import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/refund_repository.dart';
import '../../data/repositories/snapshot_repository.dart';

/// 支出净额 = 原支出 − 该笔支出的退款合计。
///
/// 退款**不算收入**：列表按净额展示（原本 100 元支出、退款 20 元 → 显示
/// 80 元），月/年支出统计也按净额计。只有支出账单参与扣减——收入/转账
/// 账单即使有历史退款记录也不受影响。
int netAmountOf(Bill bill, Map<String, int> refundTotals) {
  if (bill.type != BillType.expense.name) return bill.amount;
  final refund = refundTotals[bill.id] ?? 0;
  return refund == 0 ? bill.amount : bill.amount - refund;
}

/// 退款业务（算法一的扩展）：登记退款 + 账户余额回补 + 关联快照，单事务。
///
/// 两条红线：
/// 1. **绝不改写原账单的 amount**——退款是 refunds 表里的独立记录，数据库
///    永远同时留着「原支出」与「退款」两笔账，净额只在读取/统计时算出来；
/// 2. 退款**不计入收入**——只冲减原支出的统计口径，并把这笔钱退回原账户
///    （钱确实回来了，账户余额与资产曲线必须跟着动）。
class RefundService {
  RefundService(this._db)
    : _accounts = AccountRepository(_db),
      _bills = BillRepository(_db),
      _refunds = RefundRepository(_db),
      _snapshots = SnapshotRepository(_db);

  final AppDatabase _db;
  final AccountRepository _accounts;
  final BillRepository _bills;
  final RefundRepository _refunds;
  final SnapshotRepository _snapshots;

  /// 单笔账单的退款合计（万分之元；无退款为 0）。
  Future<int> totalOf(String billId) => _refunds.totalOf(billId);

  /// 全部账单退款合计（账单 id → 金额）。
  Future<Map<String, int>> totals() => _refunds.totals();

  /// 全部账单退款合计流（列表/统计净额换算）。
  Stream<Map<String, int>> watchTotals() => _refunds.watchTotals();

  /// 登记 / 修改 / 清除某笔支出的退款。
  ///
  /// [amount] 为账户币种的万分之元；0（或负数）表示清除退款。
  /// 余额按**差额**回补：退款合计从 a 改成 b，账户余额 +（b − a），
  /// 因此重复保存同一数值不会重复加钱。
  Future<void> setRefund({required String billId, required int amount}) async {
    final bill = await _bills.getById(billId);
    if (bill == null) throw NotFoundException('账单不存在: $billId');
    if (bill.type != BillType.expense.name) {
      throw const ValidationException('只有支出账单可以登记退款');
    }
    final newAmount = amount < 0 ? 0 : amount;
    if (newAmount > bill.amount) {
      throw const ValidationException('退款金额不能超过支出金额');
    }
    final oldAmount = await _refunds.totalOf(billId);
    final delta = newAmount - oldAmount;

    await _db.transaction(() async {
      // 退款按原账单的时间归集：统计上冲减的还是这笔支出所在的那个月
      await _refunds.deleteByBill(billId);
      if (newAmount > 0) {
        final now = nowMs();
        await _refunds.insert(
          RefundsCompanion.insert(
            id: genId(),
            billId: billId,
            amount: newAmount,
            time: bill.time,
            comment: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      // 钱退回原账户（余额 + 差额），并写关联快照（type=7 退款）
      // 支出账单必有账户（_validate 已保证），此处安全非空解包。
      if (delta != 0) {
        await _shiftBalance(bill.accountId!, delta, bill.time, billId);
      }
      // 退款改变了这笔支出的净额 → 顺带刷新账单 updatedAt，
      // 让「账单变化」驱动的流（首页列表/统计刷新/年报告指纹）同步重算。
      await _bills.update(billId, BillsCompanion(updatedAt: Value(nowMs())));
    });
  }

  /// 余额增减并按需写入关联快照（与 [BillService] 同一算法一实现）。
  Future<int> _shiftBalance(
    String accountId,
    int delta,
    int timestamp,
    String billId, {
    bool writeSnapshot = true,
  }) async {
    final account = await _accounts.getById(accountId);
    if (account == null) throw NotFoundException('账户不存在: $accountId');
    final newBalance = account.currentBalance + delta;
    await _accounts.setBalance(accountId, newBalance);
    if (writeSnapshot) {
      await _snapshots.insert(
        BalanceSnapshotsCompanion.insert(
          id: genId(),
          accountId: accountId,
          balance: newBalance,
          timestamp: timestamp,
          type: SnapshotType.refund,
          billId: Value(billId),
        ),
      );
    }
    return newBalance;
  }
}
