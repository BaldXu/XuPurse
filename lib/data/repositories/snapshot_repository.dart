import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 余额快照数据访问（趋势图数据源；账单联动快照由 Service 层在同事务写入）。
class SnapshotRepository {
  SnapshotRepository(this._db);

  final AppDatabase _db;

  Future<void> insert(BalanceSnapshotsCompanion entry) =>
      _db.into(_db.balanceSnapshots).insert(entry);

  Future<void> insertAll(List<BalanceSnapshotsCompanion> entries) =>
      _db.batch((batch) {
        batch.insertAll(_db.balanceSnapshots, entries);
      });

  /// 指定账户的快照列表（时间升序）
  Future<List<BalanceSnapshot>> listByAccount(
    String accountId, {
    int? start,
    int? end,
    bool validOnly = true,
  }) {
    final query = _db.select(_db.balanceSnapshots)
      ..where((t) => t.accountId.equals(accountId));
    if (validOnly) {
      query.where((t) => t.isValid.equals(true));
    }
    if (start != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((t) => t.timestamp.isSmallerThanValue(end));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    return query.get();
  }

  /// 指定账户最新一条快照
  Future<BalanceSnapshot?> latestByAccount(String accountId) =>
      (_db.select(_db.balanceSnapshots)
            ..where((t) => t.accountId.equals(accountId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(1))
          .getSingleOrNull();

  /// 全部账户快照（总资产趋势）
  Future<List<BalanceSnapshot>> listAll({
    int? start,
    int? end,
    bool validOnly = true,
  }) {
    final query = _db.select(_db.balanceSnapshots);
    if (validOnly) {
      query.where((t) => t.isValid.equals(true));
    }
    if (start != null) {
      query.where((t) => t.timestamp.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((t) => t.timestamp.isSmallerThanValue(end));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    return query.get();
  }

  /// 全部账户快照流（总资产趋势，响应式刷新）
  Stream<List<BalanceSnapshot>> watchAll({bool validOnly = true}) {
    final query = _db.select(_db.balanceSnapshots);
    if (validOnly) {
      query.where((t) => t.isValid.equals(true));
    }
    query.orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    return query.watch();
  }

  /// 关联账单失效（账单被删除/修改时，旧快照作废而非删除，保留追溯）
  Future<void> invalidateByBill(String billId) =>
      (_db.update(_db.balanceSnapshots)..where((t) => t.billId.equals(billId)))
          .write(const BalanceSnapshotsCompanion(isValid: Value(false)));

  /// 关联账单的快照（重算时定位旧快照）
  Future<List<BalanceSnapshot>> listByBill(String billId) => (_db.select(
    _db.balanceSnapshots,
  )..where((t) => t.billId.equals(billId))).get();

  /// 指定账户指定时间之后的快照全部失效（重算场景）
  Future<void> invalidateAfter(String accountId, int timestamp) =>
      (_db.update(_db.balanceSnapshots)..where(
            (t) =>
                t.accountId.equals(accountId) &
                t.timestamp.isBiggerOrEqualValue(timestamp) &
                t.billId.isNotNull(),
          ))
          .write(const BalanceSnapshotsCompanion(isValid: Value(false)));

  Future<void> deleteById(String id) =>
      (_db.delete(_db.balanceSnapshots)..where((t) => t.id.equals(id))).go();
}
