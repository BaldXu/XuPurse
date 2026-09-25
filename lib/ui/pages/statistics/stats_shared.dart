import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
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
        if (v == null) return;
        if (_lastVersion != null && v != _lastVersion) {
          _lastVersion = v;
          // ref.listenManual 只做副作用监听,不会触发重建;必须 setState,
          // 否则 _future 换新对象 FutureBuilder 也不会重建,数据永远陈旧。
          if (mounted) setState(onDataVersionChanged);
        } else {
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

String granularityLabel(StatsGranularity g, BillType type) {
  final dir = type == BillType.expense ? '支出' : '收入';
  return switch (g) {
    StatsGranularity.day => '每日$dir趋势',
    StatsGranularity.week => '每周$dir趋势',
    StatsGranularity.month => '每月$dir趋势',
  };
}

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

/// 环比「上一周期」区间的日历对齐计算。
///
/// 不能用 `start - (end - start)` 滚动窗口：日历月天数不一（30/31/28），
/// 本月 9/1~10/1 的 span=30 天，滚回去是 8/2~9/1，把上月 8/1 的账单
/// 切掉（环比少算一整天的钱）。正确做法是按日历单位整体平移——
/// 上月就是上月、去年就是去年、上周就是上周。
({int start, int end}) prevCalendarRange(int start, int end) {
  final s = DateTime.fromMillisecondsSinceEpoch(start);
  final e = DateTime.fromMillisecondsSinceEpoch(end);
  // 端点都是当日 00:00 且 end 恰为 start 的「下个整月/整年」→ 日历月/年。
  final bool startIsMidnight = s.hour == 0 && s.minute == 0 && s.second == 0;
  // 月份分支必须同时校验「两端都是 1 号」：仅年/月相同会让任意跨整月边界
  // 的区间（如自定义 6/15~7/15、8/31~9/30）被误判为整月，错误对齐到月初。
  if (startIsMidnight &&
      s.day == 1 &&
      e.day == 1 &&
      e.year == (s.month == 12 ? s.year + 1 : s.year) &&
      e.month == (s.month == 12 ? 1 : s.month + 1)) {
    // 本月 → 上月（含 12 月跨年；DateTime(month:0) 自动落到上一年 12 月）。
    return (
      start: DateTime(s.year, s.month - 1).millisecondsSinceEpoch,
      end: DateTime(s.year, s.month).millisecondsSinceEpoch,
    );
  }
  if (startIsMidnight &&
      e.year == s.year + 1 &&
      e.month == s.month &&
      e.day == s.day) {
    // 本年 → 去年（平移一年）。
    return (
      start: DateTime(s.year - 1, s.month, s.day).millisecondsSinceEpoch,
      end: DateTime(e.year - 1, e.month, e.day).millisecondsSinceEpoch,
    );
  }
  if (startIsMidnight &&
      !e.isAfter(s.add(const Duration(days: 7))) &&
      e.weekday == DateTime.monday &&
      s.weekday == DateTime.monday) {
    // 整周（周一起）→ 上一周。
    return (
      start: s.add(const Duration(days: -7)).millisecondsSinceEpoch,
      end: e.add(const Duration(days: -7)).millisecondsSinceEpoch,
    );
  }
  // 其余（自定义范围/非对齐区间）：按天数平移，但用「当日同时刻」平移
  // 保证边界落在同一时刻（而非毫秒差），避免 DST/月末截断类错位。
  final shiftDays = e.difference(s).inDays;
  return (
    start: s.subtract(Duration(days: shiftDays)).millisecondsSinceEpoch,
    end: e.subtract(Duration(days: shiftDays)).millisecondsSinceEpoch,
  );
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
