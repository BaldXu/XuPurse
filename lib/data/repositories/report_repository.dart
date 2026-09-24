import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../domain/services/currency_service.dart' show convertAmount;
import '../database/app_database.dart';

/// 「报告汇总」入口门槛判定结果。
class ReportGate {
  const ReportGate({
    required this.count,
    required this.minTime,
    required this.maxTime,
  });

  /// 常规记账条数（非调账、非「不计入收支」的收支账单）
  final int count;

  /// 首条 / 末条记账时间（毫秒）
  final int? minTime;
  final int? maxTime;

  /// 解锁入口的最低条数
  static const int minBillCount = 10;

  /// 解锁入口的最短时间跨度（大于一周）
  static const int minSpanMs = 7 * Duration.millisecondsPerDay;

  /// 是否达到展示门槛：≥10 条记账记录 且 时间跨度 > 7 天。
  bool get unlocked =>
      count >= minBillCount &&
      minTime != null &&
      maxTime != null &&
      maxTime! - minTime! > minSpanMs;

  /// 未达门槛 / 无数据时的空结果。
  static const ReportGate empty = ReportGate(
    count: 0,
    minTime: null,
    maxTime: null,
  );
}

/// 年度报告汇总读写。
///
/// 策略：**不做增量维护**。全部字段都是纯派生数据（bills + balance_snapshots
/// 可完全重算），读路径先用数据指纹判断陈旧，陈旧则**整年覆盖重算**（幂等
/// upsert）。这样避开跨年迁移、账单删除、调账、导入回填等增量边界错误。
///
/// 口径要点（与统计页的差异是有意为之，年报告额外单列调账）：
/// - 记录收入 / 记录支出：非调账 且 非「不计入收支」，与统计页同口径；
/// - 调账净额：调账账单单独成桶（统计页会把调账混进收支，年报告不能，
///   否则「资产变动差额」永远算不出来）；
/// - 转账不计入（不改变净资产）。
class ReportRepository {
  ReportRepository(this._db);

  final AppDatabase _db;

  /// 「常规账单」判定：非调账 且 非「不计入收支」（口径同统计页）。
  static const String _isRegular =
      "(extra IS NULL OR (extra NOT LIKE '%\"isAdjustment\":true%'"
      " AND extra NOT LIKE '%\"excludeFromStats\":true%'"
      " AND extra NOT LIKE '%\"notInTotal\":true%'))";

  /// 「调账账单」判定（[AccountService.setBalance] 写入的 extra 标记）。
  static const String _isAdjust = "extra LIKE '%\"isAdjustment\":true%'";

  // ---------- 门槛 ----------

  /// 门槛判定：常规记账条数 + 首末时间（一条 SQL）。
  Future<ReportGate> gateStats() async {
    final row = await _db
        .customSelect(
          "SELECT COUNT(*) AS c, MIN(time) AS mn, MAX(time) AS mx "
          "FROM bills WHERE type IN ('expense', 'income') AND $_isRegular",
        )
        .getSingle();
    return ReportGate(
      count: row.data['c'] as int? ?? 0,
      minTime: row.data['mn'] as int?,
      maxTime: row.data['mx'] as int?,
    );
  }

  // ---------- 读 ----------

  /// 有收支记录的年份（本地时区，倒序）。
  Future<List<int>> yearsWithBills() async {
    final rows = await _db
        .customSelect(
          "SELECT DISTINCT "
          "CAST(strftime('%Y', time / 1000, 'unixepoch', 'localtime') AS INTEGER) AS y "
          "FROM bills WHERE type IN ('expense', 'income') ORDER BY y DESC",
        )
        .get();
    return [for (final r in rows) r.data['y'] as int];
  }

  /// 全部年度报告（年份倒序）。
  Future<List<YearReport>> listAll() => (_db.select(
    _db.yearReports,
  )..orderBy([(t) => OrderingTerm.desc(t.year)])).get();

  /// 某年按月收支（固定 12 条，无记录的月份补 0）。
  ///
  /// 口径与年度报告一致（排除调账与「不计入收支」），因此 12 个月合计等于
  /// 该年报告的记录收入 / 记录支出，不会出现图表与头部数字对不上的情况。
  Future<List<({int month, int income, int expense})>> monthlyOfYear(
    int year,
  ) async {
    final start = DateTime(year).millisecondsSinceEpoch;
    final end = DateTime(year + 1).millisecondsSinceEpoch;
    final rows = await _db
        .customSelect(
          "SELECT CAST(strftime('%m', time / 1000, 'unixepoch', 'localtime') "
          "AS INTEGER) AS m, "
          "SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) AS income, "
          "SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) AS expense "
          "FROM bills WHERE type IN ('expense', 'income') AND $_isRegular "
          'AND time >= ? AND time < ? GROUP BY m',
          variables: [Variable(start), Variable(end)],
        )
        .get();
    final byMonth = {
      for (final r in rows)
        r.data['m'] as int: (
          income: r.data['income'] as int? ?? 0,
          expense: r.data['expense'] as int? ?? 0,
        ),
    };
    return [
      for (var m = 1; m <= 12; m++)
        (
          month: m,
          income: byMonth[m]?.income ?? 0,
          expense: byMonth[m]?.expense ?? 0,
        ),
    ];
  }

  /// 某年按分类汇总（叶子分类；口径同上）。
  Future<List<({String categoryId, int amount})>> categorySumOfYear(
    int year,
    BillType type,
  ) async {
    final start = DateTime(year).millisecondsSinceEpoch;
    final end = DateTime(year + 1).millisecondsSinceEpoch;
    final rows = await _db
        .customSelect(
          'SELECT category_id AS cid, SUM(amount) AS s FROM bills '
          "WHERE type = ? AND time >= ? AND time < ? AND $_isRegular "
          'GROUP BY category_id',
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

  /// 全部年度报告流（年份倒序；重算后自动推送）。
  Stream<List<YearReport>> watchAll() => (_db.select(
    _db.yearReports,
  )..orderBy([(t) => OrderingTerm.desc(t.year)])).watch();

  // ---------- 一致性 ----------

  /// 按指纹校准缓存：陈旧年份整年覆盖重算，已无账单的年份整行删除。
  ///
  /// [baseCurrency] / [rates] 参与指纹与折算，因此切换本位币或改汇率也会触发
  /// 重算。整体在一个事务内完成，幂等；无变化时为空操作。
  Future<void> ensureUpToDate({
    required String baseCurrency,
    required Map<String, double> rates,
  }) async {
    final sig = await _fingerprint(baseCurrency, rates);
    final cached = await listAll();
    final cachedByYear = {for (final r in cached) r.year: r};
    final years = await yearsWithBills();
    final liveYears = years.toSet();

    await _db.transaction(() async {
      for (final r in cached) {
        if (!liveYears.contains(r.year)) {
          await (_db.delete(
            _db.yearReports,
          )..where((t) => t.year.equals(r.year))).go();
        }
      }
      for (final year in years) {
        if (cachedByYear[year]?.sourceSig == sig) continue;
        await _db
            .into(_db.yearReports)
            .insertOnConflictUpdate(
              await _computeYear(year, baseCurrency, rates, sig),
            );
      }
    });
  }

  /// 单年重算：三分桶聚合 + 期初/期末资产时点（3 条 SQL）。
  Future<YearReportsCompanion> _computeYear(
    int year,
    String baseCurrency,
    Map<String, double> rates,
    String sig,
  ) async {
    final start = DateTime(year).millisecondsSinceEpoch;
    final end = DateTime(year + 1).millisecondsSinceEpoch;

    final row = await _db
        .customSelect(
          '''
SELECT
  SUM(CASE WHEN $_isAdjust THEN 1 ELSE 0 END) AS adjust_count,
  SUM(CASE WHEN $_isAdjust AND type = 'income' THEN amount
           WHEN $_isAdjust AND type = 'expense' THEN -amount
           ELSE 0 END) AS adjust_net,
  SUM(CASE WHEN $_isRegular AND type = 'income' THEN amount ELSE 0 END) AS income,
  SUM(CASE WHEN $_isRegular AND type = 'expense' THEN amount ELSE 0 END) AS expense,
  SUM(CASE WHEN $_isRegular THEN 1 ELSE 0 END) AS bill_count
FROM bills
WHERE type IN ('expense', 'income') AND time >= ? AND time < ?
''',
          variables: [Variable(start), Variable(end)],
        )
        .getSingle();

    final startAssets = await _assetsAt(start, baseCurrency, rates);
    final endAssets = await _assetsAt(end, baseCurrency, rates);

    return YearReportsCompanion(
      year: Value(year),
      income: Value(row.data['income'] as int? ?? 0),
      expense: Value(row.data['expense'] as int? ?? 0),
      adjustNet: Value(row.data['adjust_net'] as int? ?? 0),
      startAssets: Value(startAssets.total),
      endAssets: Value(endAssets.total),
      billCount: Value(row.data['bill_count'] as int? ?? 0),
      adjustCount: Value(row.data['adjust_count'] as int? ?? 0),
      hasAssetBaseline: Value(startAssets.hasSnapshot && endAssets.hasSnapshot),
      sourceSig: Value(sig),
      computedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// 某时点的资产合计（本位币，万分之元）。
  ///
  /// 口径对齐 totalAssetsProvider：fund 恒计入，debt/record 仅 includeInAssets
  /// 时计入，外币按当前汇率折算。逐账户取 `timestamp < boundary` 的最后一条有效
  /// 快照；无快照时回退 currentBalance（存量账户可能全无快照合约）。
  Future<({int total, bool hasSnapshot})> _assetsAt(
    int boundary,
    String baseCurrency,
    Map<String, double> rates,
  ) async {
    final rows = await _db
        .customSelect(
          '''
SELECT a.currency AS currency,
       COALESCE((SELECT s.balance FROM balance_snapshots s
                 WHERE s.account_id = a.id AND s.is_valid = 1 AND s.timestamp < ?
                 ORDER BY s.timestamp DESC, s.rowid DESC LIMIT 1),
                a.current_balance) AS bal,
       (SELECT COUNT(*) FROM balance_snapshots s
        WHERE s.account_id = a.id AND s.is_valid = 1 AND s.timestamp < ?) AS snap_count
FROM accounts a
WHERE a.enabled = 1
  AND (a.category = 'fund'
       OR (a.category IN ('debt', 'record') AND a.include_in_assets = 1))
''',
          variables: [Variable(boundary), Variable(boundary)],
        )
        .get();

    var total = 0;
    var hasSnapshot = false;
    for (final r in rows) {
      total += convertAmount(
        r.data['bal'] as int? ?? 0,
        r.data['currency'] as String? ?? 'CNY',
        baseCurrency,
        rates,
      );
      if ((r.data['snap_count'] as int? ?? 0) > 0) hasSnapshot = true;
    }
    return (total: total, hasSnapshot: hasSnapshot);
  }

  /// 数据指纹：覆盖账单 / 账户 / 快照三类可变输入 + 本位币与汇率。
  /// 任一变化都会让全部年度缓存失效（年度间存在资产累积依赖，统一失效最稳）。
  Future<String> _fingerprint(
    String baseCurrency,
    Map<String, double> rates,
  ) async {
    final agg = await _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM bills) AS bc, '
          '(SELECT COALESCE(MAX(updated_at), 0) FROM bills) AS bu, '
          '(SELECT COUNT(*) FROM accounts) AS ac, '
          '(SELECT COALESCE(MAX(updated_at), 0) FROM accounts) AS au, '
          '(SELECT COUNT(*) FROM balance_snapshots) AS sc, '
          '(SELECT COALESCE(MAX(timestamp), 0) FROM balance_snapshots) AS su',
        )
        .getSingle();
    final codes = rates.keys.toList()..sort();
    final rateStr = [for (final c in codes) '$c=${rates[c]}'].join(',');
    return '${agg.data['bc']}:${agg.data['bu']}:'
        '${agg.data['ac']}:${agg.data['au']}:'
        '${agg.data['sc']}:${agg.data['su']}:'
        '$baseCurrency:$rateStr';
  }
}
