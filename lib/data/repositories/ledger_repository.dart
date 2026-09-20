import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 业务记录（借贷/报销/退款/分期）数据访问：watch 流 + 删除。
///
/// 台账页目前只读+删除；删除仅移除记录本身，不回滚关联账单/余额
/// （删除时 UI 层需向用户明确说明）。
class LedgerRepository {
  LedgerRepository(this._db);

  final AppDatabase _db;

  // ---------- watch 流（时间倒序） ----------

  Stream<List<Lend>> watchLends() => (_db.select(
    _db.lends,
  )..orderBy([(t) => OrderingTerm.desc(t.time)])).watch();

  Stream<List<Reimbursement>> watchReimbursements() => (_db.select(
    _db.reimbursements,
  )..orderBy([(t) => OrderingTerm.desc(t.time)])).watch();

  Stream<List<Refund>> watchRefunds() => (_db.select(
    _db.refunds,
  )..orderBy([(t) => OrderingTerm.desc(t.time)])).watch();

  Stream<List<Instalment>> watchInstalments() => (_db.select(
    _db.instalments,
  )..orderBy([(t) => OrderingTerm.desc(t.time)])).watch();

  // ---------- 删除 ----------

  Future<void> deleteLend(String id) =>
      (_db.delete(_db.lends)..where((t) => t.id.equals(id))).go();

  Future<void> deleteReimbursement(String id) =>
      (_db.delete(_db.reimbursements)..where((t) => t.id.equals(id))).go();

  /// 删除退款记录（含其关联账单的账单 id，供调用方决定是否联动）。
  Future<void> deleteRefund(String id) =>
      (_db.delete(_db.refunds)..where((t) => t.id.equals(id))).go();

  Future<void> deleteInstalment(String id) =>
      (_db.delete(_db.instalments)..where((t) => t.id.equals(id))).go();
}
