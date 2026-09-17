import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';

/// 趋势页：总资产曲线（快照聚合，算法五）+ 期间统计。
class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

enum _Range { all, d30, d90 }

extension _RangeLabel on _Range {
  String get label => switch (this) {
    _Range.all => '全部',
    _Range.d30 => '近30天',
    _Range.d90 => '近90天',
  };

  int? get days => switch (this) {
    _Range.all => null,
    _Range.d30 => 30,
    _Range.d90 => 90,
  };
}

class _TrendPageState extends ConsumerState<TrendPage> {
  _Range _range = _Range.all;

  @override
  Widget build(BuildContext context) {
    final snapsAsync = ref.watch(snapshotsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final total = ref.watch(totalAssetsProvider).value ?? 0;

    // 资产账户口径与 watchTotalAssets / totalAssetsProvider 一致
    // （fund 恒计入；debt/record 仅 includeInAssets；初版暂不折算外币）
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('趋势'),
        actions: [
          SegmentedButton<_Range>(
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
            segments: _Range.values
                .map((r) => ButtonSegment(value: r, label: Text(r.label)))
                .toList(),
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: snapsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (snaps) {
          final cutoff = _range.days == null
              ? null
              : DateTime.now()
                      .subtract(Duration(days: _range.days!))
                      .millisecondsSinceEpoch;
          final relevant = snaps
              .where((s) => assetIds.contains(s.accountId))
              .where((s) => cutoff == null || s.timestamp >= cutoff)
              .toList();

          if (relevant.isEmpty) {
            return const _EmptyHint();
          }
          final points = _buildTrend(relevant);
          final first = points.first.value;
          final last = points.last.value;
          final change = last - first;
          var maxV = first;
          var minV = first;
          for (final p in points) {
            if (p.value > maxV) maxV = p.value;
            if (p.value < minV) minV = p.value;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // 当前总资产 + 期间变化
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '¥ ${formatYuan(total)}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${change >= 0 ? '+' : '-'}${formatYuan(change.abs())}'
                      '（${_range.label}）',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: change >= 0
                            ? const Color(0xFF30A46C)
                            : const Color(0xFFE5484D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: _TrendChart(points: points),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCell(label: '最高', value: formatYuan(maxV)),
                  ),
                  Expanded(
                    child: _StatCell(label: '最低', value: formatYuan(minV)),
                  ),
                  Expanded(
                    child: _StatCell(
                      label: '期间变化',
                      value:
                          '${change >= 0 ? '+' : '-'}${formatYuan(change.abs())}',
                      color: change >= 0
                          ? const Color(0xFF30A46C)
                          : const Color(0xFFE5484D),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// 算法五（初版简化）：按天聚合每账户「当天最后一条快照」余额求和。
  List<_TrendPoint> _buildTrend(List<BalanceSnapshot> snaps) {
    final byAccount = <String, List<BalanceSnapshot>>{};
    for (final s in snaps) {
      byAccount.putIfAbsent(s.accountId, () => []).add(s);
    }
    // 已按时间升序；收集全部天 key
    final dayKeys = <int>{
      for (final s in snaps)
        _dayStart(s.timestamp),
    }.toList()
      ..sort();

    final cursors = {for (final id in byAccount.keys) id: 0};
    final points = <_TrendPoint>[];
    for (final day in dayKeys) {
      final dayEnd = day + 86400000;
      var sum = 0;
      for (final entry in byAccount.entries) {
        final list = entry.value;
        var i = cursors[entry.key]!;
        while (i < list.length && list[i].timestamp < dayEnd) {
          i++;
        }
        // list[i-1] 是 <= dayEnd 前的最后一条（i 是 first beyond）
        cursors[entry.key] = i;
        if (i > 0) sum += list[i - 1].balance;
      }
      points.add(_TrendPoint(day, sum));
    }
    return points;
  }

  static int _dayStart(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
  }
}

class _TrendPoint {
  const _TrendPoint(this.day, this.value);
  final int day;
  final int value;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.points});

  final List<_TrendPoint> points;

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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.show_chart,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text('暂无资产数据'),
          const SizedBox(height: 4),
          Text(
            '记账或调账后这里会生成资产趋势',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
