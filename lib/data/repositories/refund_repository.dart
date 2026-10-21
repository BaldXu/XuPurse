import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 退款数据访问（Bills 的子记录：一笔支出一条退款，金额为万分之元）。
///
/// 设计红线：**退款是独立记录，绝不改写原账单的 amount**——数据库里始终
/// 保留「原本 100 元支出」与「20 元退款」两条记录，展示与统计在读取时
/// 按净额（100 − 20 = 80）计算。
class RefundRepository {
  RefundRepository(this._db);

  final AppDatabase _db;

  /// 全部退款合计流（账单 id → 退款合计），列表/统计净额换算数据源。
  /// 退款表任一变化都会推送。
  Stream<Map<String, int>> watchTotals() =>
      _totalsQuery().watch().map(_toMap);

  /// 全部退款合计（一次性读取）。
  Future<Map<String, int>> totals() async => _toMap(await _totalsQuery().get());

  /// 单笔账单的退款合计（无退款为 0）。
  Future<int> totalOf(String billId) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS s FROM refunds WHERE bill_id = ?',
          variables: [Variable(billId)],
          readsFrom: {_db.refunds},
        )
        .getSingle();
    return row.data['s'] as int? ?? 0;
  }

  /// 单笔账单的退款记录（正常至多一条；导入的历史数据可能多条）。
  Future<List<Refund>> listOf(String billId) =>
      (_db.select(_db.refunds)..where((t) => t.billId.equals(billId))).get();

  Future<void> insert(RefundsCompanion entry) =>
      _db.into(_db.refunds).insert(entry);

  /// 删除某账单的全部退款记录。
  Future<void> deleteByBill(String billId) =>
      (_db.delete(_db.refunds)..where((t) => t.billId.equals(billId))).go();

  Selectable<QueryRow> _totalsQuery() => _db.customSelect(
    'SELECT bill_id AS bid, SUM(amount) AS s FROM refunds GROUP BY bill_id',
    readsFrom: {_db.refunds},
  );

  static Map<String, int> _toMap(List<QueryRow> rows) => {
    for (final r in rows) (r.data['bid'] as String): r.data['s'] as int? ?? 0,
  };
}
