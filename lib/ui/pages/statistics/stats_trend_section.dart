import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/amount.dart';
import '../../../state/providers.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_skeleton.dart';
import 'stats_shared.dart';

/// 趋势分区：支出柱状趋势（粒度自适应/手动切换）+ 一级分类环比。
class StatsTrendSection extends ConsumerStatefulWidget {
  const StatsTrendSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<StatsTrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends ConsumerState<StatsTrendSection>
    with StatsSectionRefresh {
  late Future<_TrendData> _future;
  StatsGranularity _granularity = StatsGranularity.week;

  @override
  void initState() {
    super.initState();
    _granularity = granularityFor(widget.start, widget.end);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant StatsTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      // 范围变化：重置为自适应默认粒度，并重新加载
      _granularity = granularityFor(widget.start, widget.end);
      _future = _load();
    }
  }

  @override
  void onDataVersionChanged() {
    _future = _load();
  }

  Future<_TrendData> _load() async {
    final bills = await ref
        .read(billRepoProvider)
        .listByRange(widget.start, widget.end, type: BillType.expense);
    return _TrendData(
      granularity: _granularity,
      points: aggregateTrend(bills, granularity: _granularity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TrendData>(
      future: _future,
      builder: (context, snap) => xpFadeGate(snap, () {
        if (snap.connectionState != ConnectionState.done) {
          return const XpSkeletonList();
        }
        if (snap.hasError) {
          return XpErrorState(
            message: '${snap.error}',
            actionLabel: '重试',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final d = snap.data!;
        return ListView(
          // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
          padding: EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.l,
            XpSpacing.l,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _TrendCard(
              title: granularityLabel(d.granularity),
              points: d.points,
              granularity: _granularity,
              onGranularityChanged: (g) {
                setState(() {
                  _granularity = g;
                  _future = _load();
                });
              },
            ),
            const SizedBox(height: XpSpacing.l),
            _TrendCompareCard(start: widget.start, end: widget.end),
          ],
        );
      }),
    );
  }
}

class _TrendData {
  const _TrendData({required this.granularity, required this.points});

  final StatsGranularity granularity;
  final List<({String label, int amount})> points;
}

/// 支出趋势卡片（柱状图，按日/周/月粒度聚合；支持手动切换粒度）。
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.points,
    required this.granularity,
    required this.onGranularityChanged,
  });

  final String title;
  final List<({String label, int amount})> points;
  final StatsGranularity granularity;
  final ValueChanged<StatsGranularity> onGranularityChanged;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const XpCard(
        padding: EdgeInsets.zero,
        child: XpEmptyState(icon: Icons.bar_chart, title: '本时段暂无支出'),
      );
    }
    final n = points.length;
    final maxAmount = points.fold<int>(
      0,
      (m, p) => p.amount > m ? p.amount : m,
    );
    final theme = Theme.of(context);
    final groups = <BarChartGroupData>[
      for (var i = 0; i < n; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              // 直接用真实金额（万分之元），悬浮框/坐标才是真实数值
              toY: points[i].amount.toDouble(),
              color: theme.colorScheme.primary,
              width: 6,
            ),
          ],
        ),
    ];
    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SegmentedButton<StatsGranularity>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: StatsGranularity.day, label: Text('日')),
                  ButtonSegment(value: StatsGranularity.week, label: Text('周')),
                  ButtonSegment(
                    value: StatsGranularity.month,
                    label: Text('月'),
                  ),
                ],
                selected: {granularity},
                onSelectionChanged: (s) => onGranularityChanged(s.first),
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: groups,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: n > 8 ? (n / 6).ceilToDouble() : 1,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= n) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[i].label,
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                // 悬浮提示：白底 + 灰边 + 真实金额
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipBorder: BorderSide(color: theme.colorScheme.outline),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final i = group.x.toInt();
                      if (i < 0 || i >= points.length) return null;
                      final p = points[i];
                      return BarTooltipItem(
                        '${p.label}\n¥ ${formatYuan(p.amount)}',
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: XpSpacing.xs),
          Text(
            '峰值 ${formatYuan(maxAmount)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 一级分类环比卡：当前区间 vs 上一区间，各一级分类支出金额浮动。
class _TrendCompareCard extends ConsumerStatefulWidget {
  const _TrendCompareCard({required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_TrendCompareCard> createState() => _TrendCompareCardState();
}

class _TrendCompareCardState extends ConsumerState<_TrendCompareCard> {
  late Future<_TrendCompareData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _TrendCompareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  Future<_TrendCompareData> _load() async {
    final repo = ref.read(billRepoProvider);
    final span = widget.end - widget.start;
    final prevStart = widget.start - span;
    final prevEnd = widget.start;

    final curBills = await repo.listByRange(
      widget.start,
      widget.end,
      type: BillType.expense,
    );
    final prevBills = await repo.listByRange(
      prevStart,
      prevEnd,
      type: BillType.expense,
    );
    final categories = await ref.read(categoryRepoProvider).getAll();
    final byId = {for (final c in categories) c.id: c};

    // 上溯到一级分类
    String topId(String id) {
      var cur = id;
      final seen = <String>{};
      while (true) {
        final c = byId[cur];
        if (c == null || c.parentId == null || !seen.add(cur)) return cur;
        cur = c.parentId!;
      }
    }

    final curAgg = <String, int>{};
    for (final b in curBills) {
      final t = topId(b.categoryId);
      curAgg[t] = (curAgg[t] ?? 0) + b.amount;
    }
    final prevAgg = <String, int>{};
    for (final b in prevBills) {
      final t = topId(b.categoryId);
      prevAgg[t] = (prevAgg[t] ?? 0) + b.amount;
    }

    // 合并所有出现过的顶级分类（当前或上个区间）
    final allKeys = <String>{...curAgg.keys, ...prevAgg.keys};
    final rows =
        <_CompareRow>[
          for (final k in allKeys)
            _CompareRow(
              categoryId: k,
              name: byId[k]?.name ?? '未知分类',
              current: curAgg[k] ?? 0,
              previous: prevAgg[k] ?? 0,
            ),
        ]..sort(
          (a, b) => (b.current - b.previous).abs().compareTo(
            (a.current - a.previous).abs(),
          ),
        );
    return _TrendCompareData(rows: rows, spanMs: span);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_TrendCompareData>(
      future: _future,
      builder: (context, snap) => xpFadeGate(snap, () {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: XpSkeletonList(
              itemCount: 2,
              padding: EdgeInsets.symmetric(vertical: XpSpacing.s),
            ),
          );
        }
        if (snap.hasError) {
          return XpErrorState(
            message: '${snap.error}',
            actionLabel: '重试',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final d = snap.data!;
        if (d.rows.isEmpty) {
          return const XpCard(
            padding: EdgeInsets.zero,
            child: XpEmptyState(icon: Icons.compare_arrows, title: '本时段暂无支出'),
          );
        }
        final totalChange = d.rows.fold<int>(
          0,
          (s, r) => s + (r.current - r.previous),
        );
        return XpCard(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.m,
            XpSpacing.l,
            XpSpacing.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '分类环比',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: XpSpacing.xs),
              Text(
                '与上一周期（${spanLabel(d.spanMs)}）对比，各一级分类支出浮动',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: XpSpacing.s),
              for (final row in d.rows) _CompareRowTile(row: row),
              const SizedBox(height: XpSpacing.s),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: XpSpacing.s),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '合计变动',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      totalChange >= 0
                          ? '+${formatYuan(totalChange)}'
                          : '-${formatYuan(totalChange.abs())}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: totalChange >= 0
                            ? XpSemanticColors.expense
                            : XpSemanticColors.income,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TrendCompareData {
  const _TrendCompareData({required this.rows, required this.spanMs});

  final List<_CompareRow> rows;
  final int spanMs;
}

class _CompareRow {
  const _CompareRow({
    required this.categoryId,
    required this.name,
    required this.current,
    required this.previous,
  });

  final String categoryId;
  final String name;
  final int current;
  final int previous;

  int get diff => current - previous;
}

class _CompareRowTile extends StatelessWidget {
  const _CompareRowTile({required this.row});

  final _CompareRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = row.diff;
    final up = diff >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(row.name, style: theme.textTheme.bodyMedium)),
          Flexible(
            child: Text(
              '${formatYuan(row.previous)} → ${formatYuan(row.current)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                  .tabular,
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          SizedBox(
            width: 74,
            child: Text(
              diff == 0 ? '持平' : '${up ? '+' : '-'}${formatYuan(diff.abs())}',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: diff == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : up
                        ? XpSemanticColors.expense
                        : XpSemanticColors.income,
                  )
                  .tabular,
            ),
          ),
        ],
      ),
    );
  }
}
