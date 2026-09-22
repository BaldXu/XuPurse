import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/trend_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart' show kExpenseColor, kIncomeColor;
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import 'statistics/stats_shared.dart' show statsDataVersionProvider;

/// 趋势页：资产趋势（快照聚合，算法五）+ 单账户余额趋势 + 累计收支净额。
///
/// 范围：本年 / 去年 / 全部 / 自定义（下界=最早有数据之日，上界=今天）；
/// 粒度：日 / 周 / 月，默认周（周/月桶取期末值）。
class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

enum _Range { thisYear, lastYear, all, custom }

extension _RangeLabel on _Range {
  String get label => switch (this) {
    _Range.thisYear => '本年',
    _Range.lastYear => '去年',
    _Range.all => '全部',
    _Range.custom => '自定义',
  };
}

class _TrendPageState extends ConsumerState<TrendPage>
    with XpPageScaffold<TrendPage> {
  _Range _range = _Range.all;
  TrendGranularity _granularity = TrendGranularity.week;
  ({int start, int end})? _custom;
  String? _accountId; // 单账户趋势选择；null = 全部账户

  @override
  double get xpMaxWidth => 960;

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('趋势'));
    // 转场期间只渲染骨架：快照数据常在 300ms 转场内返回，此刻构建
    // fl_chart 图表会撞上转场动画后半段抢 raster；completed 后数据
    // 若已到则直接构建，未到继续由下方 loading 分支兜骨架。
    if (!xpPushSettled) {
      return buildXpScaffold(appBar: appBar, loading: true);
    }
    final snapsAsync = ref.watch(snapshotsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final total = ref.watch(totalAssetsProvider).value ?? 0;
    final minDataTime = ref.watch(minDataTimeProvider).value;

    // 资产账户口径与 totalAssetsProvider 一致（fund 恒计入；
    // debt/record 仅 includeInAssets；初版暂不折算外币）
    final assetIds = accounts
        .where(
          (a) =>
              a.enabled &&
              (a.category == 'fund' ||
                  ((a.category == 'debt' || a.category == 'record') &&
                      a.includeInAssets)),
        )
        .map((a) => a.id)
        .toSet();

    final range = _resolveRange(minDataTime);
    final selectedAccount = accounts.where((a) => a.id == _accountId).toList();

    return buildXpScaffold(
      appBar: appBar,
      body: snapsAsync.when(
        loading: () => const XpSkeletonPage(),
        error: (e, _) => XpErrorState(
          message: '$e',
          actionLabel: '重试',
          onAction: () => ref.invalidate(snapshotsProvider),
        ),
        data: (snaps) {
          final points = aggregateTrendPoints(
            buildTrendPoints(
              snaps: snaps,
              assetIds: assetIds,
              accounts: accounts,
              start: range.start,
              end: range.end,
            ),
            _granularity,
          );

          return _TrendPageScope(
            granularity: _granularity,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                XpSpacing.l,
                XpSpacing.s,
                XpSpacing.l,
                32,
              ),
              children: [
                // 筛选栏：范围 + 粒度（包卡，避免直接落在页背景上低对比）
                XpCard(
                  padding: const EdgeInsets.all(XpSpacing.m),
                  child: _FilterBar(
                    range: _range,
                    granularity: _granularity,
                    custom: _custom,
                    onRangeChanged: (r) {
                      setState(() {
                        _range = r;
                        if (r == _Range.custom && _custom == null) {
                          _pickCustomRange(minDataTime);
                        }
                      });
                    },
                    onGranularityChanged: (g) =>
                        setState(() => _granularity = g),
                    onPickCustom: () => _pickCustomRange(minDataTime),
                  ),
                ),
                const SizedBox(height: XpSpacing.l),
                // 总资产趋势（总资产 + 期间变化 + 主图表，包卡与下方卡片一致）
                XpCard(
                  padding: const EdgeInsets.fromLTRB(
                    XpSpacing.l,
                    XpSpacing.m,
                    XpSpacing.l,
                    XpSpacing.l,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '总资产趋势',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: XpSpacing.xs),
                      Text(
                        '¥ ${formatYuan(total)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)
                            .tabular,
                      ),
                      if (points.length >= 2)
                        Padding(
                          padding: const EdgeInsets.only(top: XpSpacing.xs),
                          child: _ChangeText(
                            change: points.last.value - points.first.value,
                            suffix: '（期间）',
                          ),
                        ),
                      const SizedBox(height: XpSpacing.m),
                      if (points.isEmpty)
                        const XpEmptyState(
                          icon: Icons.show_chart,
                          title: '暂无资产数据',
                          message: '记账或调账后这里会生成资产趋势',
                        )
                      else
                        SizedBox(
                          height: 220,
                          child: _TrendChart(points: points),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: XpSpacing.xl),
                // 单账户余额趋势
                _AccountTrendCard(
                  accounts: accounts
                      .where((a) => a.enabled && assetIds.contains(a.id))
                      .toList(),
                  selectedId: _accountId,
                  onSelected: (id) => setState(() => _accountId = id),
                  range: range,
                  granularity: _granularity,
                  accountName: selectedAccount.isEmpty
                      ? null
                      : selectedAccount.first.name,
                ),
                const SizedBox(height: XpSpacing.xl),
                // 累计收支净额
                _CumulativeNetCard(range: range),
              ],
            ),
          );
        },
      ),
    );
  }

  ({int start, int? end}) _resolveRange(int? minDataTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_range) {
      _Range.thisYear => (
        start: DateTime(now.year).millisecondsSinceEpoch,
        end: today.millisecondsSinceEpoch + 86400000,
      ),
      _Range.lastYear => (
        start: DateTime(now.year - 1).millisecondsSinceEpoch,
        end: DateTime(now.year).millisecondsSinceEpoch,
      ),
      _Range.all => (
        start: minDataTime ?? 0,
        end: today.millisecondsSinceEpoch + 86400000,
      ),
      _Range.custom =>
        _custom != null
            ? (start: _custom!.start, end: _custom!.end)
            : (
                start: minDataTime ?? 0,
                end: today.millisecondsSinceEpoch + 86400000,
              ),
    };
  }

  /// 自定义范围下界 = 最早有数据之日（账单/快照取更早者），上界 = 今天。
  Future<void> _pickCustomRange(int? minDataTime) async {
    final now = DateTime.now();
    final DateTime first;
    if (minDataTime == null) {
      first = now.subtract(const Duration(days: 365));
    } else {
      final dt = DateTime.fromMillisecondsSinceEpoch(minDataTime);
      first = DateTime(dt.year, dt.month, dt.day);
    }
    final picked = await showXpDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDateRangeStart: _custom == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_custom!.start),
      initialDateRangeEnd: _custom == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_custom!.end - 86400000),
      helpText: '选择趋势日期范围',
      saveText: '确定',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _custom = (
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ).millisecondsSinceEpoch,
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day + 1,
        ).millisecondsSinceEpoch,
      );
      _range = _Range.custom;
    });
  }
}

/// 期间变化文本（带涨跌色）。
class _ChangeText extends StatelessWidget {
  const _ChangeText({required this.change, this.suffix = ''});

  final int change;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final color = change >= 0 ? kIncomeColor : kExpenseColor;
    return Text(
      '${change >= 0 ? '+' : '-'}${formatYuan(change.abs())}$suffix',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: color).tabular,
    );
  }
}

// ---------------------------------------------------------------------------
// 筛选栏：范围 + 粒度
// ---------------------------------------------------------------------------

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.range,
    required this.granularity,
    required this.custom,
    required this.onRangeChanged,
    required this.onGranularityChanged,
    required this.onPickCustom,
  });

  final _Range range;
  final TrendGranularity granularity;
  final ({int start, int end})? custom;
  final ValueChanged<_Range> onRangeChanged;
  final ValueChanged<TrendGranularity> onGranularityChanged;
  final VoidCallback onPickCustom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_Range>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: _Range.values
                  .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                  .toList(),
              selected: {range},
              onSelectionChanged: (s) => onRangeChanged(s.first),
            ),
            // 自定义已选时展示当前范围摘要
            if (range == _Range.custom && custom != null)
              ActionChip(
                avatar: const AppIcon(icon: Icons.date_range, size: 16),
                label: Text(
                  '${_fmtDay(custom!.start)} ~ ${_fmtDay(custom!.end - 86400000)}',
                  style: theme.textTheme.labelSmall,
                ),
                onPressed: onPickCustom,
              ),
          ],
        ),
        const SizedBox(height: XpSpacing.s),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('粒度', style: theme.textTheme.labelMedium),
            SegmentedButton<TrendGranularity>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: TrendGranularity.values
                  .map((g) => ButtonSegment(value: g, label: Text(g.label)))
                  .toList(),
              selected: {granularity},
              onSelectionChanged: (s) => onGranularityChanged(s.first),
            ),
          ],
        ),
      ],
    );
  }

  static String _fmtDay(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}/${d.month}/${d.day}';
  }
}

// ---------------------------------------------------------------------------
// 单账户余额趋势卡片
// ---------------------------------------------------------------------------

class _AccountTrendCard extends ConsumerWidget {
  const _AccountTrendCard({
    required this.accounts,
    required this.selectedId,
    required this.onSelected,
    required this.range,
    required this.granularity,
    required this.accountName,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final ({int start, int? end}) range;
  final TrendGranularity granularity;
  final String? accountName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapsAsync = ref.watch(snapshotsProvider);
    return XpCard(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.l,
      ),
      child: snapsAsync.maybeWhen(
        loading: () => const SizedBox(
          height: 120,
          child: XpSkeletonList(
            itemCount: 2,
            padding: EdgeInsets.symmetric(vertical: XpSpacing.s),
          ),
        ),
        orElse: () {
          final snaps = snapsAsync.value ?? const <BalanceSnapshot>[];
          if (accounts.isEmpty) {
            return const XpEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: '暂无资产账户',
            );
          }
          final selected = selectedId ?? accounts.first.id;
          final snapsOf = snaps.where((s) => s.accountId == selected).toList();
          final daily = buildTrendPoints(
            snaps: snapsOf,
            assetIds: {selected},
            accounts: accounts,
            start: range.start,
            end: range.end,
          );
          final points = aggregateTrendPoints(daily, granularity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: selected,
                      decoration: const InputDecoration(
                        labelText: '单账户余额趋势',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        for (final a in accounts)
                          DropdownMenuItem(value: a.id, child: Text(a.name)),
                      ],
                      onChanged: (v) => onSelected(v),
                    ),
                  ),
                  if (points.length >= 2) ...[
                    const SizedBox(width: XpSpacing.m),
                    _ChangeText(change: points.last.value - points.first.value),
                  ],
                ],
              ),
              const SizedBox(height: XpSpacing.m),
              if (points.isEmpty)
                XpEmptyState(
                  icon: Icons.show_chart,
                  title: accountName == null ? '选择账户查看余额趋势' : '该账户在所选范围内暂无快照',
                )
              else
                SizedBox(height: 200, child: _TrendChart(points: points)),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 累计收支净额卡片
// ---------------------------------------------------------------------------

class _CumulativeNetCard extends ConsumerStatefulWidget {
  const _CumulativeNetCard({required this.range});

  final ({int start, int? end}) range;

  @override
  ConsumerState<_CumulativeNetCard> createState() => _CumulativeNetCardState();
}

class _CumulativeNetCardState extends ConsumerState<_CumulativeNetCard> {
  Future<List<TrendPoint>>? _future;
  ({int start, int? end})? _lastRange;
  ProviderSubscription<int>? _dataSub;

  @override
  void initState() {
    super.initState();
    // 订阅账单 watch 流:数据变化时重算(与范围变化正交)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var version = 0;
      _dataSub = ref.listenManual(
        statsDataVersionProvider.select((async) => async.valueOrNull ?? -1),
        (prev, next) {
          final v = next;
          if (v < 0 || v == version) return;
          version = v;
          if (!mounted) return;
          final range = widget.range;
          _lastRange = range;
          setState(() => _future = _loadFor(range));
        },
      );
    });
  }

  Future<List<TrendPoint>> _loadFor(({int start, int? end}) range) {
    final end = range.end ?? DateTime.now().millisecondsSinceEpoch;
    return ref
        .read(billRepoProvider)
        .listByRange(range.start, end)
        .then(
          (bills) =>
              buildCumulativeNetPoints(bills, start: range.start, end: end),
        );
  }

  @override
  void dispose() {
    _dataSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final range = widget.range;
    if (_lastRange != range || _future == null) {
      _lastRange = range;
      _future = _loadFor(range);
    }
    return XpCard(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '累计收支净额',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            '口径为记账流水（收入-支出累加，不含转账与「不计入收支」）；'
            '仅有余额快照而无流水的历史数据不参与计算',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          FutureBuilder<List<TrendPoint>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 200,
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
                  onAction: () =>
                      setState(() => _future = _loadFor(widget.range)),
                );
              }
              final points = aggregateTrendPoints(
                snap.data ?? const <TrendPoint>[],
                _granularityOf(context),
              );
              if (points.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: XpEmptyState(
                    icon: Icons.stacked_line_chart,
                    title: '所选范围内暂无收支流水',
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '净额 ${points.last.value >= 0 ? '+' : '-'}'
                        '${formatYuan(points.last.value.abs())}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: points.last.value >= 0
                                  ? kIncomeColor
                                  : kExpenseColor,
                              fontWeight: FontWeight.w600,
                            )
                            .tabular,
                      ),
                    ],
                  ),
                  const SizedBox(height: XpSpacing.s),
                  SizedBox(height: 200, child: _TrendChart(points: points)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  TrendGranularity _granularityOf(BuildContext context) {
    // 粒度由宿主页面决定；通过 _TrendPageScope 向下传递（见页面 build）。
    return _TrendPageScope.of(context).granularity;
  }
}

/// 向下传递当前粒度的 InheritedWidget。
class _TrendPageScope extends InheritedWidget {
  const _TrendPageScope({required this.granularity, required super.child});

  final TrendGranularity granularity;

  static _TrendPageScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TrendPageScope>()!;

  @override
  bool updateShouldNotify(_TrendPageScope oldWidget) =>
      oldWidget.granularity != granularity;
}

// ---------------------------------------------------------------------------
// 通用趋势折线图
// ---------------------------------------------------------------------------

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineColor = colorScheme.primary;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value / 10000),
    ];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble().clamp(1, double.infinity),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _yInterval(),
          getDrawingHorizontalLine: (v) => FlLine(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: _yInterval(),
              getTitlesWidget: (v, _) => Text(
                _compactYuan(v),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _xInterval(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _xLabel(points[i].day),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                colorScheme.inverseSurface.withValues(alpha: 0.9),
            getTooltipItems: (spots) => spots
                .map(
                  (s) => LineTooltipItem(
                    '${_xLabel(points[s.x.toInt()].day)}\n¥ ${formatYuan((s.y * 10000).round())}',
                    TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontSize: 11,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: lineColor,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  double _yInterval() {
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b) / 10000;
    final maxV = values.reduce((a, b) => a > b ? a : b) / 10000;
    final span = (maxV - minV).abs();
    if (span == 0) return 1;
    return (span / 4).clamp(0.5, double.infinity);
  }

  double _xInterval() {
    final n = points.length;
    if (n <= 7) return 1;
    return (n / 6).ceilToDouble();
  }

  static String _xLabel(int dayMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(dayMs);
    return '${dt.month}/${dt.day}';
  }

  static String _compactYuan(double v) {
    if (v.abs() >= 10000) {
      return '${(v / 10000).toStringAsFixed(1)}w';
    }
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }
}
