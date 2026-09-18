import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors.dart';
import '../../core/utils/bill_extra.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/snapshot_repository.dart';

/// 账单业务：新增/修改/删除的余额联动与快照（docs/algorithms.md 算法一），
/// 以及全量余额重算（算法三）。
///
/// 所有写操作在单事务内完成：账单 + 余额 + 快照同生共死（单一数据源红线）。
class BillService {
  BillService(this._db)
    : _accounts = AccountRepository(_db),
      _bills = BillRepository(_db),
      _snapshots = SnapshotRepository(_db);

  final AppDatabase _db;
  final AccountRepository _accounts;
  final BillRepository _bills;
  final SnapshotRepository _snapshots;

  Stream<List<Bill>> watchPage({
    int limit = 50,
    int offset = 0,
    BillType? type,
    String? accountId,
    String? categoryId,
    int? start,
    int? end,
  }) => _bills.watchPage(
    limit: limit,
    offset: offset,
    type: type,
    accountId: accountId,
    categoryId: categoryId,
    start: start,
    end: end,
  );

  Future<Bill?> getById(String id) => _bills.getById(id);

  /// 新增账单（算法一）：账单落库 + 余额联动 + 关联快照 + 标签，单事务。
  ///
  /// - expense：主账户 `-amount`，快照 type=1
  /// - income：主账户 `+amount`，快照 type=2
  /// - transfer：转出账户 `-amount`（快照 type=3）+ 转入账户 `+toAmount`
  ///   （快照 type=4，toAmount 缺省为 amount），并写 Transfers 扩展表
  ///   （手续费 fee = amount - toAmount）。
  Future<String> addBill({
    required BillType type,
    required String categoryId,
    required int amount,
    String? accountId,
    String? incomeAccountId,
    required int time,
    String? comment,
    List<String> tagIds = const [],
    BillExtra extra = const BillExtra(),
    String? currencyCode,
    int? currencyAmount,
    String? baseCurrency,
    int? transferToAmount,
  }) async {
    _validate(
      type: type,
      amount: amount,
      accountId: accountId,
      incomeAccountId: incomeAccountId,
    );
    final billId = genId();
    final now = nowMs();
    final toAmount = type == BillType.transfer
        ? (transferToAmount ?? amount)
        : amount;

    await _db.transaction(() async {
      await _bills.insert(
        BillsCompanion.insert(
          id: billId,
          type: type.name,
          categoryId: categoryId,
          amount: amount,
          accountId: Value(accountId),
          incomeAccountId: Value(incomeAccountId),
          time: time,
          comment: Value(comment),
          currencyCode: Value(currencyCode),
          currencyAmount: Value(currencyAmount),
          baseCurrency: Value(baseCurrency),
          extra: Value(extra.encode()),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _applyEffect(
        type: type,
        amount: amount,
        toAmount: toAmount,
        accountId: accountId,
        incomeAccountId: incomeAccountId,
        time: time,
        billId: billId,
        sign: 1,
      );
      if (type == BillType.transfer) {
        await _writeTransfer(
          billId: billId,
          fromAccountId: accountId!,
          toAccountId: incomeAccountId!,
          amount: amount,
          toAmount: toAmount,
          fee: amount - toAmount,
          time: time,
          comment: comment,
        );
      }
      if (tagIds.isNotEmpty) await _bills.setBillTags(billId, tagIds);
    });
    return billId;
  }

  /// 修改账单：旧账单影响反向应用 → 更新 → 新账单影响正向应用（算法一）。
  Future<void> updateBill(
    String id, {
    BillType? type,
    String? categoryId,
    int? amount,
    String? accountId,
    String? incomeAccountId,
    int? time,
    String? comment,
    List<String>? tagIds,
    BillExtra? extra,
    int? transferToAmount,
    String? currencyCode,
    int? currencyAmount,
    String? baseCurrency,
  }) async {
    final old = await _bills.getById(id);
    if (old == null) throw NotFoundException('账单不存在: $id');

    final newType = type ?? BillType.values.byName(old.type);
    final newAmount = amount ?? old.amount;
    final newAccountId = accountId ?? old.accountId;
    final newIncomeAccountId = incomeAccountId ?? old.incomeAccountId;
    _validate(
      type: newType,
      amount: newAmount,
      accountId: newAccountId,
      incomeAccountId: newIncomeAccountId,
    );
    final newTime = time ?? old.time;
    final newToAmount = newType == BillType.transfer
        ? (transferToAmount ?? newAmount)
        : newAmount;
    // 旧转账到账金额（撤销时回滚转入端余额用）
    final oldToAmount = old.type == BillType.transfer.name
        ? await _transferToAmountOf(id)
        : null;

    await _db.transaction(() async {
      // 旧账单反向 + 旧快照失效
      await _applyEffect(
        type: BillType.values.byName(old.type),
        amount: old.amount,
        toAmount: oldToAmount ?? old.amount,
        accountId: old.accountId,
        incomeAccountId: old.incomeAccountId,
        time: old.time,
        billId: id,
        sign: -1,
      );
      await _snapshots.invalidateByBill(id);

      await _bills.update(
        id,
        BillsCompanion(
          type: Value(newType.name),
          categoryId: Value(categoryId ?? old.categoryId),
          amount: Value(newAmount),
          accountId: Value(newAccountId),
          incomeAccountId: Value(newIncomeAccountId),
          time: Value(newTime),
          comment: Value(comment ?? old.comment),
          currencyCode: Value(currencyCode ?? old.currencyCode),
          currencyAmount: Value(currencyAmount ?? old.currencyAmount),
          baseCurrency: Value(baseCurrency ?? old.baseCurrency),
          extra: Value(extra?.encode() ?? old.extra),
          updatedAt: Value(nowMs()),
        ),
      );
      await _applyEffect(
        type: newType,
        amount: newAmount,
        toAmount: newToAmount,
        accountId: newAccountId,
        incomeAccountId: newIncomeAccountId,
        time: newTime,
        billId: id,
        sign: 1,
      );
      if (newType == BillType.transfer) {
        await _writeTransfer(
          billId: id,
          fromAccountId: newAccountId!,
          toAccountId: newIncomeAccountId!,
          amount: newAmount,
          toAmount: newToAmount,
          fee: newAmount - newToAmount,
          time: newTime,
          comment: comment ?? old.comment,
        );
      } else {
        await (_db.delete(
          _db.transfers,
        )..where((t) => t.billId.equals(id))).go();
      }
      if (tagIds != null) await _bills.setBillTags(id, tagIds);
    });
  }

  /// 删除账单：反向恢复余额 + 快照失效 + 删除账单/转账扩展/标签关联，单事务。
  Future<void> deleteBill(String id) async {
    final old = await _bills.getById(id);
    if (old == null) return; // 幂等删除
    final oldToAmount = old.type == BillType.transfer.name
        ? await _transferToAmountOf(id)
        : null;

    await _db.transaction(() async {
      await _applyEffect(
        type: BillType.values.byName(old.type),
        amount: old.amount,
        toAmount: oldToAmount ?? old.amount,
        accountId: old.accountId,
        incomeAccountId: old.incomeAccountId,
        time: old.time,
        billId: id,
        sign: -1,
      );
      await _snapshots.invalidateByBill(id);
      await (_db.delete(_db.billTags)..where((t) => t.billId.equals(id))).go();
      await (_db.delete(_db.transfers)..where((t) => t.billId.equals(id))).go();
      await _bills.delete(id);
    });
  }

  /// 全量余额重算（算法三，危险操作）。
  ///
  /// 所有账户重置为 initialBalance 后按账单累加；调账账单与第三方导入账单
  /// （extra.skipInRecalculate）跳过。用于刚导入大量历史数据或数据异常修复。
  Future<void> recalculateAllBalances() async {
    await _db.transaction(() async {
      final accounts = await _accounts.getAll();
      final allBills = await _bills.getAll();
      final balance = {for (final a in accounts) a.id: a.initialBalance};

      for (final bill in allBills) {
        final extra = BillExtra.fromJson(bill.extra);
        if (extra.skipInRecalculate) continue;
        final type = BillType.values.byName(bill.type);
        final amount = bill.amount;
        if (type == BillType.expense) {
          _addTo(balance, bill.accountId, -amount);
        } else if (type == BillType.income) {
          _addTo(balance, bill.accountId, amount);
        } else if (type == BillType.transfer) {
          _addTo(balance, bill.accountId, -amount);
          _addTo(balance, bill.incomeAccountId, amount);
        }
      }

      for (final entry in balance.entries) {
        await _accounts.setBalance(entry.key, entry.value);
      }
    });
  }

  // ---------- 私有 ----------

  void _validate({
    required BillType type,
    required int amount,
    String? accountId,
    String? incomeAccountId,
  }) {
    if (amount <= 0) throw const ValidationException('金额必须大于 0');
    if (type == BillType.transfer) {
      if (accountId == null || incomeAccountId == null) {
        throw const ValidationException('转账必须指定转出与转入账户');
      }
      if (accountId == incomeAccountId) {
        throw const ValidationException('转出与转入账户不能相同');
      }
    } else if (accountId == null) {
      throw const ValidationException('必须指定账户');
    }
  }

  /// 按算法一应用账单对余额的影响并写快照。[sign] 为 +1 正向 / -1 反向。
  ///
  /// 反向应用（撤销）只回滚余额，不写快照——中间态快照无追溯价值，
  /// 随后的 invalidateByBill 只应失效账单原本的正向快照。
  Future<void> _applyEffect({
    required BillType type,
    required int amount,
    int? toAmount,
    required String? accountId,
    required String? incomeAccountId,
    required int time,
    required String billId,
    required int sign,
  }) async {
    final writeSnapshot = sign > 0;
    switch (type) {
      case BillType.expense:
        await _shiftBalance(
          accountId!,
          -sign * amount,
          time,
          SnapshotType.expense,
          billId,
          writeSnapshot: writeSnapshot,
        );
      case BillType.income:
        await _shiftBalance(
          accountId!,
          sign * amount,
          time,
          SnapshotType.income,
          billId,
          writeSnapshot: writeSnapshot,
        );
      case BillType.transfer:
        await _shiftBalance(
          accountId!,
          -sign * amount,
          time,
          SnapshotType.transferOut,
          billId,
          writeSnapshot: writeSnapshot,
        );
        await _shiftBalance(
          incomeAccountId!,
          sign * (toAmount ?? amount),
          time,
          SnapshotType.transferIn,
          billId,
          writeSnapshot: writeSnapshot,
        );
    }
  }

  /// 转账扩展落库（Transfers 表；幂等：同一 billId 先删后插）。
  Future<void> _writeTransfer({
    required String billId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    required int toAmount,
    required int fee,
    required int time,
    String? comment,
  }) async {
    await (_db.delete(
      _db.transfers,
    )..where((t) => t.billId.equals(billId))).go();
    await _db
        .into(_db.transfers)
        .insert(
          TransfersCompanion.insert(
            id: genId(),
            billId: billId,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amount: amount,
            toAmount: Value(toAmount),
            fee: Value(fee),
            time: time,
            comment: Value(comment),
            createdAt: nowMs(),
            updatedAt: nowMs(),
          ),
        );
  }

  /// 查询转账扩展的到账金额（不存在返回 null）。
  Future<int?> _transferToAmountOf(String billId) async {
    final row =
        await (_db.select(_db.transfers)
              ..where((t) => t.billId.equals(billId))
              ..limit(1))
            .getSingleOrNull();
    return row?.toAmount;
  }

  /// 余额增减并按需写入关联快照；返回新余额。
  Future<int> _shiftBalance(
    String accountId,
    int delta,
    int timestamp,
    int snapshotType,
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
          type: snapshotType,
          billId: Value(billId),
        ),
      );
    }
    return newBalance;
  }

  static void _addTo(Map<String, int> map, String? id, int delta) {
    if (id == null) return;
    map[id] = (map[id] ?? 0) + delta;
  }
}
