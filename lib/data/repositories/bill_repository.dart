import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../database/app_database.dart';

/// 账单数据访问（核心表；含标签关联）。
class BillRepository {
  BillRepository(this._db);

  final AppDatabase _db;

  /// 「不计入收支」账单的 SQL 过滤条件（无表别名版）。
  /// `excludeFromStats` 为新字段；`notInTotal` 兼容旧一木导入数据。
  static const _excludedSql =
      " AND (extra IS NULL OR (extra NOT LIKE '%\"excludeFromStats\":true%' AND extra NOT LIKE '%\"notInTotal\":true%'))";

  /// 同上，`b` 表别名版（多表 JOIN 查询用）。
  static const _excludedSqlAliasB =
      " AND (b.extra IS NULL OR (b.extra NOT LIKE '%\"excludeFromStats\":true%' AND b.extra NOT LIKE '%\"notInTotal\":true%'))";

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

  /// 时间段账单列表（时间倒序；不含「不计入收支」账单，供统计趋势用）
  Future<List<Bill>> listByRange(int start, int end, {BillType? type}) async {
    final query = _db.select(_db.bills);
    _applyFilter(query, type: type, start: start, end: end);
    // 排除「不计入收支」账单（统计口径；列表仍会展示全部账单）
    query.where(
      (_) => const CustomExpression<bool>(
        "(extra IS NULL OR (extra NOT LIKE '%\"excludeFromStats\":true%' AND extra NOT LIKE '%\"notInTotal\":true%'))",
      ),
    );
    query.orderBy([(t) => OrderingTerm.desc(t.time)]);
    return query.get();
  }

  Future<Bill?> getById(String id) =>
      (_db.select(_db.bills)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Bill>> getAll() =>
      (_db.select(_db.bills)..orderBy([(t) => OrderingTerm.asc(t.time)])).get();

  /// 全部账单流(时间升序;搜索页等需要全量数据响应式刷新的场景)。
  Stream<List<Bill>> watchAll() => (_db.select(
    _db.bills,
  )..orderBy([(t) => OrderingTerm.asc(t.time)])).watch();

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
          'WHERE type = ? AND time >= ? AND time < ?'
          '$_excludedSql',
          variables: [Variable(type.name), Variable(start), Variable(end)],
        )
        .getSingle();
    return row.data['s'] as int;
  }

  /// 时间段收支柱出（一次性查询，AI 摘要用；口径同 watchSummaryInRange）。
  Future<({int expense, int income})> summaryInRangeOnce(
    int start,
    int end,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT type, SUM(amount) AS s FROM bills '
          'WHERE time >= ? AND time < ? AND type IN (?, ?)'
          '$_excludedSql GROUP BY type',
          variables: [
            Variable(start),
            Variable(end),
            Variable(BillType.expense.name),
            Variable(BillType.income.name),
          ],
          readsFrom: {_db.bills},
        )
        .get();
    var expense = 0;
    var income = 0;
    for (final row in rows) {
      final s = row.data['s'] as int? ?? 0;
      if (row.data['type'] == BillType.expense.name) expense = s;
      if (row.data['type'] == BillType.income.name) income = s;
    }
    return (expense: expense, income: income);
  }

  /// 时间段收支柱出流（首页月汇总；不含转账；不含「不计入收支」）
  Stream<({int expense, int income})> watchSummaryInRange(int start, int end) {
    return _db
        .customSelect(
          'SELECT type, SUM(amount) AS s FROM bills '
          'WHERE time >= ? AND time < ? AND type IN (?, ?)'
          '$_excludedSql GROUP BY type',
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

  /// 时间段内按「年-月」分组收支柱流（首页分组卡储蓄率条；不含转账）。
  /// 刻意不排除「不计入收支」账单：与明细列表/日卡口径一致——条反映
  /// 用户在该月实际看到的所有收支。时间倒序（新年份在前）。
  /// 年/月分桶在 Dart 侧完成（DateTime 本地时区）：SQLite 的 strftime
  /// 'localtime' 修饰符在部分原生 SQLite 构建（Windows 桌面/测试 VM）会
  /// 返回 NULL，直接在 SQL 里 CAST 成 INT 会崩，故时区换算不放 SQL。
  Stream<List<({int year, int month, int expense, int income})>>
  watchMonthlySummaryInRange(int start, int end) {
    return _db
        .customSelect(
          "SELECT time, "
          "CASE WHEN type = 'expense' THEN amount ELSE 0 END AS expense, "
          "CASE WHEN type = 'income' THEN amount ELSE 0 END AS income "
          "FROM bills WHERE time >= ? AND time < ? "
          "AND type IN ('expense', 'income')",
          variables: [Variable(start), Variable(end)],
          readsFrom: {_db.bills},
        )
        .watch()
        .map((rows) {
          final buckets = <(int, int), ({int expense, int income})>{};
          for (final r in rows) {
            final dt = DateTime.fromMillisecondsSinceEpoch(
              r.data['time'] as int,
            );
            final key = (dt.year, dt.month);
            final rec = buckets.putIfAbsent(key, () => (expense: 0, income: 0));
            buckets[key] = (
              expense: rec.expense + (r.data['expense'] as int),
              income: rec.income + (r.data['income'] as int),
            );
          }
          final list =
              [
                for (final e in buckets.entries)
                  (
                    year: e.key.$1,
                    month: e.key.$2,
                    expense: e.value.expense,
                    income: e.value.income,
                  ),
              ]..sort((a, b) {
                final byYear = b.year.compareTo(a.year);
                return byYear != 0 ? byYear : b.month.compareTo(a.month);
              });
          return list;
        });
  }

  /// 时间段内按分类汇总金额（统计页分类占比；不含转账；不含「不计入收支」）。
  Future<List<({String categoryId, int amount})>> sumByCategoryInRange(
    int start,
    int end,
    BillType type,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT category_id AS cid, SUM(amount) AS s FROM bills '
          'WHERE type = ? AND time >= ? AND time < ?'
          '$_excludedSql GROUP BY category_id',
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

  /// 最早账单时间（毫秒）；无账单返回 null（统计页自定义范围的日历下界）。
  Future<int?> minBillTime() async {
    final row = await _db
        .customSelect('SELECT MIN(time) AS t FROM bills')
        .getSingle();
    return row.data['t'] as int?;
  }

  /// 时间段内按标签汇总金额（统计页标签分区；不含转账；不含「不计入收支」）。
  Future<List<({String tagId, int amount})>> sumByTagInRange(
    int start,
    int end,
    BillType type,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT bt.tag_id AS tid, SUM(b.amount) AS s FROM bills b '
          'JOIN bill_tags bt ON bt.bill_id = b.id '
          'WHERE b.type = ? AND b.time >= ? AND b.time < ?'
          '$_excludedSqlAliasB GROUP BY bt.tag_id',
          variables: [Variable(type.name), Variable(start), Variable(end)],
        )
        .get();
    return [
      for (final r in rows)
        (
          tagId: r.data['tid'] as String? ?? '',
          amount: r.data['s'] as int? ?? 0,
        ),
    ];
  }

  // ---------- 标签关联 ----------

  /// 时间段内按备注文本汇总金额（AI 统计摘要用；收支类型，不含转账；
  /// 不含「不计入收支」）。[limit] 只取金额最高的前 N 条备注。
  Future<List<({String comment, int amount})>> sumByCommentInRange(
    int start,
    int end, {
    int limit = 10,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT comment AS c, SUM(amount) AS s FROM bills '
          'WHERE type IN (?, ?) AND time >= ? AND time < ?'
          " AND comment IS NOT NULL AND comment != ''"
          '$_excludedSql GROUP BY comment ORDER BY s DESC LIMIT ?',
          variables: [
            Variable(BillType.expense.name),
            Variable(BillType.income.name),
            Variable(start),
            Variable(end),
            Variable(limit),
          ],
        )
        .get();
    return [
      for (final r in rows)
        (
          comment: r.data['c'] as String? ?? '',
          amount: r.data['s'] as int? ?? 0,
        ),
    ];
  }

  /// 账单的全部标签 ID
  Future<List<String>> tagIdsOf(String billId) async {
    final rows = await (_db.select(
      _db.billTags,
    )..where((t) => t.billId.equals(billId))).get();
    return rows.map((r) => r.tagId).toList();
  }

  /// 全部账单-标签关联（分析页词云一次性取数，避免 N+1 查询）。
  Future<List<({String billId, String tagId})>> allBillTags() async {
    final rows = await (_db.select(_db.billTags)).get();
    return [for (final r in rows) (billId: r.billId, tagId: r.tagId)];
  }

  /// 转账记录的手续费（无转账记录或 fee=0 返回 null；编辑转账时回显用）。
  Future<int?> transferFeeOf(String billId) async {
    final row =
        await (_db.select(_db.transfers)
              ..where((t) => t.billId.equals(billId))
              ..limit(1))
            .getSingleOrNull();
    if (row == null || row.fee <= 0) return null;
    return row.fee;
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
