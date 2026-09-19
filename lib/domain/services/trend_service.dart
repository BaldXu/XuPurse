import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';

/// 资产趋势计算（docs/algorithms.md 算法五）。
///
/// 与 cent-xyx 一致的口径：
/// 1. 每个资产账户按时间升序排列其有效快照；
/// 2. 对窗口起点 `start` 之前最近一条快照作为**期初锚点**（近 30/90 天视图
///    若直接丢弃窗口外快照，期初会被严重低估/缺失）；
/// 3. 时间 key = `start` 当天 ∪ 窗口内有快照的天 ∪ `end` 当天，升序；
/// 4. 每个时间 key 取各账户「最后一条 timestamp <= key」的快照余额求和；
/// 5. **无任何快照的资产账户**（如钱迹导入无历史快照）用当前余额作全程
///    平直值，避免曲线缺失该账户。
class TrendPoint {
  const TrendPoint(this.day, this.value);

  /// 天起始毫秒（本地时区 0 点）
  final int day;

  /// 该天总资产（万分之元）
  final int value;
}

/// 计算资产趋势点序列；窗口内无数据且无兜底账户时返回空列表。
List<TrendPoint> buildTrendPoints({
  required List<BalanceSnapshot> snaps,
  required Set<String> assetIds,
  required List<Account> accounts,
  int? start,
  int? end,
}) {
  final filtered = [
    for (final s in snaps)
      if (assetIds.contains(s.accountId)) s,
  ];

  final byAccount = <String, List<BalanceSnapshot>>{};
  for (final s in filtered) {
    byAccount.putIfAbsent(s.accountId, () => []).add(s);
  }

  // 无快照的资产账户 → 用当前余额作全程平直值（钱迹导入无历史快照场景）
  final fallbackBalances = <String, int>{
    for (final a in accounts)
      if (assetIds.contains(a.id) && !byAccount.containsKey(a.id))
        a.id: a.currentBalance,
  };
  if (byAccount.isEmpty && fallbackBalances.isEmpty) return const [];

  final startDay = start == null ? null : dayStart(start);
  final endDay = end == null ? null : dayStart(end);

  // 时间 key：start 天 ∪ 窗口内有快照的天 ∪ end 天
  final dayKeys = <int>{
    if (startDay != null) startDay,
    if (endDay != null) endDay,
    for (final s in filtered)
      if ((startDay == null || s.timestamp >= startDay) &&
          (endDay == null || s.timestamp < endDay + 86400000))
        dayStart(s.timestamp),
  }.toList()..sort();
  if (dayKeys.isEmpty) return const [];

  final accountIds = {...byAccount.keys, ...fallbackBalances.keys};
  final cursors = {for (final id in accountIds) id: 0};
  final points = <TrendPoint>[];
  for (final day in dayKeys) {
    final dayEnd = day + 86400000;
    var sum = 0;
    for (final id in accountIds) {
      final list = byAccount[id];
      if (list == null) {
        sum += fallbackBalances[id] ?? 0;
        continue;
      }
      var i = cursors[id]!;
      while (i < list.length && list[i].timestamp < dayEnd) {
        i++;
      }
      cursors[id] = i;
      if (i > 0) sum += list[i - 1].balance;
      // i == 0：start 前该账户无快照，视为窗口期初不存在（贡献 0）
    }
    points.add(TrendPoint(day, sum));
  }
  return points;
}

/// 本地时区当天 0 点（毫秒）。
int dayStart(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
}

/// 趋势图粒度。
enum TrendGranularity { day, week, month }

extension TrendGranularityLabel on TrendGranularity {
  String get label => switch (this) {
    TrendGranularity.day => '日',
    TrendGranularity.week => '周',
    TrendGranularity.month => '月',
  };
}

/// 将日序列聚合为周（周一起）/月序列，每桶取**期末值**（快照是时点数、
/// 累计净额是累计值，均应取桶内最后一天）；day 粒度原样返回。
List<TrendPoint> aggregateTrendPoints(
  List<TrendPoint> daily,
  TrendGranularity g,
) {
  if (g == TrendGranularity.day || daily.isEmpty) return daily;
  int bucketKey(int dayMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(dayMs);
    return g == TrendGranularity.month
        ? DateTime(dt.year, dt.month, 1).millisecondsSinceEpoch
        : // 周桶：回退到本周周一
          DateTime(
            dt.year,
            dt.month,
            dt.day - (dt.weekday - 1),
          ).millisecondsSinceEpoch;
  }

  // daily 升序，后写覆盖即为期末值
  final buckets = <int, TrendPoint>{};
  for (final p in daily) {
    buckets[bucketKey(p.day)] = p;
  }
  final keys = buckets.keys.toList()..sort();
  return [for (final k in keys) buckets[k]!];
}

/// 期间内**逐日累计收支净额**曲线（收入-支出累加；仅 expense/income，
/// 转账与「不计入收支」由调用方的 listByRange 口径保证排除）。
///
/// 注意：导入场景可能只有余额快照而无完整流水，本曲线与资产曲线
/// 可能对不上，属预期（口径为记账流水）。
List<TrendPoint> buildCumulativeNetPoints(
  List<Bill> bills, {
  int? start,
  int? end,
}) {
  final dayNet = <int, int>{};
  for (final b in bills) {
    if (b.type == BillType.transfer.name) continue;
    if (start != null && b.time < start) continue;
    if (end != null && b.time >= end) continue;
    final d = dayStart(b.time);
    final signed = b.type == BillType.income.name ? b.amount : -b.amount;
    dayNet[d] = (dayNet[d] ?? 0) + signed;
  }
  final days = dayNet.keys.toList()..sort();
  var acc = 0;
  final points = <TrendPoint>[];
  for (final d in days) {
    acc += dayNet[d]!;
    points.add(TrendPoint(d, acc));
  }
  return points;
}
