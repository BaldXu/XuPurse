import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../database/app_database.dart';

/// 账单数据访问（核心表；含标签关联）。
class BillRepository {
  BillRepository(this._db);

  final AppDatabase _db;

  /// 分页账单流（时间倒序；支持类型/账户/分类/时间段过滤）
  Stream<List<Bill>> watchPage({
    int limit = 50,
    int offset = 0,
    BillType? type,
    String? accountId,
    String? categoryId,
    int? start,
    int? end,
  }) {
    final query = _db.select(_db.bills);
    _applyFilter(
      query,
      type: type,
      accountId: accountId,
      categoryId: categoryId,
      start: start,
      end: end,
    );
    query
      ..orderBy([
        (t) => OrderingTerm.desc(t.time),
        (t) => OrderingTerm.desc(t.createdAt),
      ])
      ..limit(limit, offset: offset);
    return query.watch();
  }

  /// 时间段账单列表（时间倒序）
  Future<List<Bill>> listByRange(int start, int end, {BillType? type}) async {
    final query = _db.select(_db.bills);
    _applyFilter(query, type: type, start: start, end: end);
    query.orderBy([(t) => OrderingTerm.desc(t.time)]);
    return query.get();
  }

  Future<Bill?> getById(String id) =>
      (_db.select(_db.bills)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Bill>> getAll() =>
      (_db.select(_db.bills)..orderBy([(t) => OrderingTerm.asc(t.time)])).get();

  Future<List<Bill>> getByIds(List<String> ids) =>
      (_db.select(_db.bills)..where((t) => t.id.isIn(ids))).get();

  Future<void> insert(BillsCompanion entry) =>
      _db.into(_db.bills).insert(entry);

  Future<void> update(String id, BillsCompanion entry) =>
      (_db.update(_db.bills)..where((t) => t.id.equals(id))).write(entry);

  Future<void> delete(String id) =>
      (_db.delete(_db.bills)..where((t) => t.id.equals(id))).go();

  /// 账户关联账单数（删除账户前的校验）
  Future<int> countByAccountId(String accountId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM bills WHERE account_id = ? OR income_account_id = ?',
          variables: [Variable(accountId), Variable(accountId)],
        )
        .getSingle();
    return row.data['c'] as int;
  }

  /// 分类关联账单数（删除分类前的校验）
  Future<int> countByCategoryId(String categoryId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM bills WHERE category_id = ?',
          variables: [Variable(categoryId)],
        )
        .getSingle();
    return row.data['c'] as int;
  }

  /// 时间段内按类型汇总金额（万分之元；转账单条同时计入转出/转入不在此统计）
  Future<int> sumByType(int start, int end, BillType type) async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(amount), 0) AS s FROM bills '
          'WHERE type = ? AND time >= ? AND time < ?',
          variables: [Variable(type.name), Variable(start), Variable(end)],
        )
        .getSingle();
    return row.data['s'] as int;
  }

  /// 时间段收支柱出流（首页月汇总；不含转账）
  Stream<({int expense, int income})> watchSummaryInRange(int start, int end) {
    return _db
        .customSelect(
          'SELECT type, SUM(amount) AS s FROM bills '
          'WHERE time >= ? AND time < ? AND type IN (?, ?) GROUP BY type',
          variables: [
            Variable(start),
            Variable(end),
            Variable(BillType.expense.name),
            Variable(BillType.income.name),
          ],
          readsFrom: {_db.bills},
        )
        .watch()
        .map((rows) {
          var expense = 0;
          var income = 0;
          for (final row in rows) {
            final s = row.data['s'] as int? ?? 0;
            if (row.data['type'] == BillType.expense.name) expense = s;
            if (row.data['type'] == BillType.income.name) income = s;
          }
          return (expense: expense, income: income);
        });
  }

  /// 时间段内按分类汇总金额（统计页分类占比；不含转账）。
  Future<List<({String categoryId, int amount})>> sumByCategoryInRange(
    int start,
    int end,
    BillType type,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT category_id AS cid, SUM(amount) AS s FROM bills '
          'WHERE type = ? AND time >= ? AND time < ? GROUP BY category_id',
          variables: [Variable(type.name), Variable(start), Variable(end)],
        )
        .get();
    return [
      for (final r in rows)
        (
          categoryId: r.data['cid'] as String? ?? '',
          amount: r.data['s'] as int? ?? 0,
        ),
    ];
  }

  /// 时间段内按天汇总支出（统计页趋势图）。
  Future<List<({int day, int amount})>> dailyExpenseInRange(
    int start,
    int end,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT (time / 86400000) AS day, SUM(amount) AS s FROM bills '
          'WHERE type = ? AND time >= ? AND time < ? GROUP BY day ORDER BY day',
          variables: [
            Variable(BillType.expense.name),
            Variable(start),
            Variable(end),
          ],
        )
        .get();
    return [
      for (final r in rows)
        (day: r.data['day'] as int? ?? 0, amount: r.data['s'] as int? ?? 0),
    ];
  }

  // ---------- 标签关联 ----------

  /// 账单的全部标签 ID
  Future<List<String>> tagIdsOf(String billId) async {
    final rows = await (_db.select(
      _db.billTags,
    )..where((t) => t.billId.equals(billId))).get();
    return rows.map((r) => r.tagId).toList();
  }

  /// 整体替换账单的标签关联
  Future<void> setBillTags(String billId, List<String> tagIds) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.billTags,
      )..where((t) => t.billId.equals(billId))).go();
      for (final tagId in tagIds) {
        await _db
            .into(_db.billTags)
            .insert(
              BillTagsCompanion.insert(billId: billId, tagId: tagId),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }

  // ---------- 私有 ----------

  void _applyFilter(
    SimpleSelectStatement<$BillsTable, Bill> query, {
    BillType? type,
    String? accountId,
    String? categoryId,
    int? start,
    int? end,
  }) {
    if (type != null) query.where((t) => t.type.equals(type.name));
    if (accountId != null) {
      query.where(
        (t) =>
            t.accountId.equals(accountId) | t.incomeAccountId.equals(accountId),
      );
    }
    if (categoryId != null) {
      query.where((t) => t.categoryId.equals(categoryId));
    }
    if (start != null) query.where((t) => t.time.isBiggerOrEqualValue(start));
    if (end != null) query.where((t) => t.time.isSmallerThanValue(end));
  }
}
