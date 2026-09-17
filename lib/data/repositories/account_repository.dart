import 'package:drift/drift.dart';

import '../../core/utils/ids.dart';
import '../database/app_database.dart';

/// 账户数据访问（纯查询封装，业务约束校验在 Service 层）。
class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  /// 监听全部账户（按创建时间排序）
  Stream<List<Account>> watchAll({bool enabledOnly = true}) {
    final query = _db.select(_db.accounts);
    if (enabledOnly) query.where((t) => t.enabled.equals(true));
    query.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch();
  }

  /// 全部账户列表
  Future<List<Account>> getAll({bool enabledOnly = false}) async {
    final query = _db.select(_db.accounts);
    if (enabledOnly) query.where((t) => t.enabled.equals(true));
    query.orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.get();
  }

  /// 参与总资产统计的账户（fund 且 includeInAssets）
  Future<List<Account>> getAssetAccounts() =>
      (_db.select(_db.accounts)..where(
            (t) =>
                t.category.equals('fund') &
                t.includeInAssets.equals(true) &
                t.enabled.equals(true),
          ))
          .get();

  Future<Account?> getById(String id) => (_db.select(
    _db.accounts,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Account>> getByIds(List<String> ids) =>
      (_db.select(_db.accounts)..where((t) => t.id.isIn(ids))).get();

  /// 按名称查找（导入时同名账户合并）
  Future<Account?> findByName(String name) => (_db.select(
    _db.accounts,
  )..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<void> insert(AccountsCompanion entry) =>
      _db.into(_db.accounts).insert(entry);

  Future<void> update(String id, AccountsCompanion entry) =>
      (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(entry);

  /// 物理删除（是否允许删除由 Service 层校验）
  Future<void> delete(String id) =>
      (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();

  /// 余额增量调整：balance = balance + delta（可为负）
  Future<void> addBalance(String id, int delta) => _db.customUpdate(
    'UPDATE accounts SET current_balance = current_balance + ?, '
    'updated_at = ? WHERE id = ?',
    variables: [Variable(delta), Variable(nowMs()), Variable(id)],
    updates: {_db.accounts},
    updateKind: UpdateKind.update,
  );

  /// 余额直接设值（调账场景）
  Future<void> setBalance(String id, int balance) =>
      (_db.update(_db.accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(
          currentBalance: Value(balance),
          updatedAt: Value(nowMs()),
        ),
      );

  /// 总资产 = 全部 fund 账户余额之和（万分之元）
  Future<int> totalAssets() async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(current_balance), 0) AS s FROM accounts '
          "WHERE category = 'fund' AND include_in_assets = 1 AND enabled = 1",
        )
        .getSingle();
    return row.data['s'] as int;
  }
}
