import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../state/providers.dart';
import '../../tokens/design_tokens.dart';

/// 账单数据版本号:任何账单变化(记账、导入、调账、删除、清空、切换账本)
/// 都会 bump,统计页各分区 watch 它以及时重跑查询,不再依赖 IndexedStack
/// 重建或手动切换日期范围。
final statsDataVersionProvider = StreamProvider<int>((ref) {
  var version = 0;
  return ref.watch(billRepoProvider).watchAll().map((_) => ++version);
});

/// 统计分区刷新 mixin:watch [statsDataVersionProvider],数据变化时回调
/// [onDataVersionChanged],分区重跑自己的查询。与 didUpdateWidget(日期范围)
/// 正交,两者都触发重载。
@optionalTypeArgs
mixin StatsSectionRefresh<W extends ConsumerStatefulWidget>
    on ConsumerState<W> {
  int? _lastVersion;

  void onDataVersionChanged();

  @override
  void initState() {
    super.initState();
    // initState 里不能 ref.listen,改用首帧后订阅
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lastVersion = ref.read(statsDataVersionProvider).value;
      ref.listenManual(statsDataVersionProvider, (prev, next) {
        final v = next.value;
        if (v != null && _lastVersion != null && v != _lastVersion) {
          _lastVersion = v;
          onDataVersionChanged();
        } else if (v != null) {
          _lastVersion = v;
        }
      });
    });
  }
}

/// FutureBuilder 统一淡入门:loading 骨架 ↔ 完成内容 交叉淡变
/// (XpMotion.component)。key 随 connectionState 变化,AnimatedSwitcher
/// 只在 loading → data/error 时动画。
Widget xpFadeGate<T>(AsyncSnapshot<T> snap, Widget Function() build) {
  return AnimatedSwitcher(
    duration: XpMotion.component,
    switchInCurve: XpMotion.easeOut,
    switchOutCurve: XpMotion.easeIn,
    child: KeyedSubtree(
      key: ValueKey<bool>(snap.connectionState == ConnectionState.done),
      child: build(),
    ),
  );
}

/// 预设时间范围（统计页日期范围下拉共用）。
enum StatsRangePreset {
  thisMonth('本月'),
  lastMonth('上月'),
  thisYear('本年'),
  lastYear('去年'),
  lastWeek('最近一周'),
  custom('自定义范围');

  const StatsRangePreset(this.label);

  final String label;
}

/// 趋势聚合粒度。
enum StatsGranularity { day, week, month }

/// 日期格式化（统计页范围说明共用）。
String fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// 趋势粒度：随范围天数自适应（≤14 天按日、≤62 天按周、其余按月）。
StatsGranularity granularityFor(int start, int end) {
  final days = (end - start) / 86400000;
  if (days <= 14) return StatsGranularity.day;
  if (days <= 62) return StatsGranularity.week;
  return StatsGranularity.month;
}

String granularityLabel(StatsGranularity g) => switch (g) {
  StatsGranularity.day => '每日支出趋势',
  StatsGranularity.week => '每周支出趋势',
  StatsGranularity.month => '每月支出趋势',
};

/// 把区间内支出账单按日/周/月聚合为趋势序列。
List<({String label, int amount})> aggregateTrend(
  List<Bill> bills, {
  required StatsGranularity granularity,
}) {
  final map = <int, int>{};
  final labels = <int, String>{};
  for (final b in bills) {
    final dt = DateTime.fromMillisecondsSinceEpoch(b.time);
    final int key;
    final String label;
    switch (granularity) {
      case StatsGranularity.day:
        key = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
        label = '${dt.month}/${dt.day}';
      case StatsGranularity.week:
        final ws = dt.subtract(Duration(days: dt.weekday - 1));
        final wk = DateTime(ws.year, ws.month, ws.day);
        key = wk.millisecondsSinceEpoch;
        label = '${wk.month}/${wk.day}';
      case StatsGranularity.month:
        key = DateTime(dt.year, dt.month).millisecondsSinceEpoch;
        label = '${dt.month}月';
    }
    map[key] = (map[key] ?? 0) + b.amount;
    labels[key] = label;
  }
  final keys = map.keys.toList()..sort();
  return [for (final k in keys) (label: labels[k]!, amount: map[k]!)];
}

String spanLabel(int spanMs) {
  final days = spanMs / 86400000;
  if (days >= 360) return '${(days / 365).round()}年';
  if (days >= 30) return '${(days / 30).round()}个月';
  return '${days.round()}天';
}

/// 分类饼图/排行与标签条形共用的图表调色板。
const piePalette = [
  Color(0xFF5470C6),
  Color(0xFF91CC75),
  Color(0xFFFAC858),
  Color(0xFFEE6666),
  Color(0xFF73C0DE),
  Color(0xFF3BA272),
  Color(0xFFEA7CCC),
  Color(0xFF9A60B4),
  Color(0xFFFC8452),
  Color(0xFFF472B6),
];
