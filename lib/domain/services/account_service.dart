import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/snapshot_repository.dart';
import '../../data/seed/default_categories.dart';

/// 账户业务：CRUD + 手动调账（docs/algorithms.md 算法二）。
///
/// 红线：余额变更只能经由本 Service（调账账单）或 BillService（账单联动）。
class AccountService {
  AccountService(this._db)
    : _accounts = AccountRepository(_db),
      _bills = BillRepository(_db),
      _categories = CategoryRepository(_db),
      _snapshots = SnapshotRepository(_db);

  final AppDatabase _db;
  final AccountRepository _accounts;
  final BillRepository _bills;
  final CategoryRepository _categories;
  final SnapshotRepository _snapshots;

  Stream<List<Account>> watchAll() => _accounts.watchAll();

  Stream<List<Account>> watchAllIncludingDisabled() =>
      _accounts.watchAll(enabledOnly: false);

  Future<Account?> getById(String id) => _accounts.getById(id);

  /// 总资产流（fund + includeInAssets + enabled；Phase 2 接入汇率折算）
  Stream<int> watchTotalAssets() => _db
      .customSelect(
        'SELECT COALESCE(SUM(current_balance), 0) AS s FROM accounts '
        "WHERE category = 'fund' AND include_in_assets = 1 AND enabled = 1",
        readsFrom: {_db.accounts},
      )
      .watchSingle()
      .map((row) => row.data['s'] as int);

  /// 创建账户；currentBalance 初始化为 initialBalance。
  Future<String> createAccount({
    required String name,
    required AccountCategory category,
    required AccountType type,
    String? icon,
    String? color,
    int initialBalance = 0,
    String currency = 'CNY',
    bool includeInAssets = true,
    int? creditLimit,
    String? cardCode,
    int? statementDate,
    int? repaymentDate,
    String? remark,
  }) async {
    if (name.trim().isEmpty) {
      throw const ValidationException('账户名称不能为空');
    }
    if (await _accounts.findByName(name.trim()) != null) {
      throw const ValidationException('已存在同名账户');
    }
    final id = genId();
    final now = nowMs();
    await _accounts.insert(
      AccountsCompanion.insert(
        id: id,
        name: name.trim(),
        category: category.name,
        type: type.name,
        icon: Value(icon),
        color: Value(color),
        initialBalance: Value(initialBalance),
        currentBalance: Value(initialBalance),
        currency: Value(currency),
        includeInAssets: Value(includeInAssets),
        creditLimit: Value(creditLimit),
        cardCode: Value(cardCode),
        statementDate: Value(statementDate),
        repaymentDate: Value(repaymentDate),
        remark: Value(remark),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// 更新账户信息（不含余额字段；余额变更走 [setBalance]）。
  Future<void> updateAccount(String id, AccountsCompanion entry) async {
    assert(
      !entry.currentBalance.present && !entry.initialBalance.present,
      '余额变更必须走 setBalance / BillService',
    );
    await _accounts.update(id, entry.copyWith(updatedAt: Value(nowMs())));
  }

  /// 删除账户（有关联账单则拒绝；关联快照一并清理）。
  Future<void> deleteAccount(String id) async {
    final billCount = await _bills.countByAccountId(id);
    if (billCount > 0) {
      throw ValidationException('该账户还有 $billCount 笔关联账单，无法删除');
    }
    await _db.transaction(() async {
      await _accounts.delete(id);
      // 手动快照等残留清理（无账单关联的快照）
      await _db.customStatement(
        'DELETE FROM balance_snapshots WHERE account_id = ?',
        [id],
      );
    });
  }

  /// 合并账户：把 [sourceIds] 全部并入 [targetId]（docs/algorithms.md 算法八）。
  ///
  /// - 所有账单 / 快照 / 转账 / 借贷 / 报销 / 分期中的账户引用替换为 target。
  /// - 导入映射表（import_mappings）中指向被合并账户的记录重定向到 target，
  ///   保证再次导入同一第三方文件不产生重复账户（幂等）。
  /// - 可选 [newName]：合并后重命名 target。
  /// - 单事务；被合并账户物理删除。
  Future<void> mergeAccounts({
    required String targetId,
    required List<String> sourceIds,
    String? newName,
  }) async {
    final ids = sourceIds.where((id) => id != targetId).toSet();
    if (ids.isEmpty) return;

    await _db.transaction(() async {
      for (final sourceId in ids) {
        await _redirectReferences(sourceId, targetId);
      }
      if (newName != null && newName.trim().isNotEmpty) {
        await _accounts.update(
          targetId,
          AccountsCompanion(
            name: Value(newName.trim()),
            updatedAt: Value(nowMs()),
          ),
        );
      }
      for (final sourceId in ids) {
        await _accounts.delete(sourceId);
      }
    });
  }

  /// 批量设置账户币种。
  Future<void> setCurrencies(List<String> ids, String currencyCode) async {
    if (ids.isEmpty) return;
    await _db.transaction(() async {
      await (_db.update(_db.accounts)
            ..where((t) => t.id.isIn(ids)))
          .write(
            AccountsCompanion(
              currency: Value(currencyCode),
              updatedAt: Value(nowMs()),
            ),
          );
    });
  }

  /// 把某账户的全部引用重定向到另一账户（合并内部步骤）。
  Future<void> _redirectReferences(String fromId, String toId) async {
    // 账单主账户 / 转入账户
    await _db.customUpdate(
      'UPDATE bills SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.bills},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE bills SET income_account_id = ? WHERE income_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.bills},
      updateKind: UpdateKind.update,
    );
    // 快照
    await _db.customUpdate(
      'UPDATE balance_snapshots SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.balanceSnapshots},
      updateKind: UpdateKind.update,
    );
    // 转账扩展
    await _db.customUpdate(
      'UPDATE transfers SET from_account_id = ? WHERE from_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.transfers},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE transfers SET to_account_id = ? WHERE to_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.transfers},
      updateKind: UpdateKind.update,
    );
    // 借贷
    await _db.customUpdate(
      'UPDATE lends SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.lends},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE lends SET repayment_account_id = ? WHERE repayment_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.lends},
      updateKind: UpdateKind.update,
    );
    // 报销
    await _db.customUpdate(
      'UPDATE reimbursements SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.reimbursements},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE reimbursements SET reimbursement_account_id = ? '
      'WHERE reimbursement_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.reimbursements},
      updateKind: UpdateKind.update,
    );
    // 分期
    await _db.customUpdate(
      'UPDATE instalments SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.instalments},
      updateKind: UpdateKind.update,
    );
    // 导入映射重定向（保证再次导入不产生重复账户）
    await _db.customUpdate(
      'UPDATE import_mappings SET target_id = ? WHERE target_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.importMappings},
      updateKind: UpdateKind.update,
    );
  }

  /// 手动调账：把账户余额直接设为 [newBalance]（算法二）。
  ///
  /// 产生一笔调账账单（extra.isAdjustment=true）+ MANUAL 快照，流水完整可追溯。
  /// diff == 0 时不产生任何记录。
  Future<void> setBalance(
    String accountId,
    int newBalance, {
    String? note,
    int? time,
  }) async {
    final account = await _accounts.getById(accountId);
    if (account == null) {
      throw NotFoundException('账户不存在: $accountId');
    }
    final diff = newBalance - account.currentBalance;
    if (diff == 0) return;

    final isIncome = diff > 0;
    final category = await _categories.findBySeedKey(
      isIncome ? AdjustmentCategoryKeys.income : AdjustmentCategoryKeys.expense,
    );
    if (category == null) {
      throw const NotFoundException('缺少调账分类种子（balance_adjustment_*）');
    }

    final billId = genId();
    final ts = time ?? nowMs();

    await _db.transaction(() async {
      await _bills.insert(
        BillsCompanion.insert(
          id: billId,
          type: isIncome ? BillType.income.name : BillType.expense.name,
          categoryId: category.id,
          amount: diff.abs(),
          accountId: Value(accountId),
          time: ts,
          comment: Value(note ?? '余额调整'),
          extra: const Value('{"isAdjustment":true}'),
          createdAt: nowMs(),
          updatedAt: nowMs(),
        ),
      );
      await _accounts.setBalance(accountId, newBalance);
      await _snapshots.insert(
        BalanceSnapshotsCompanion.insert(
          id: genId(),
          accountId: accountId,
          balance: newBalance,
          timestamp: ts,
          type: SnapshotType.manual,
          billId: Value(billId),
          note: Value(note),
        ),
      );
    });
  }
}
