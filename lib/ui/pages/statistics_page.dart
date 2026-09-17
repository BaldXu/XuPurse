import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';

/// 统计页：收支对比 + 分类占比 + 每日支出趋势。
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  int _period = 0; // 0 本月 / 1 上月 / 2 本年

  ({int start, int end}) get _range {
    final now = DateTime.now();
    return switch (_period) {
      0 => (
        start: DateTime(now.year, now.month).millisecondsSinceEpoch,
        end: DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
      ),
      1 => (
        start: DateTime(now.year, now.month - 1).millisecondsSinceEpoch,
        end: DateTime(now.year, now.month).millisecondsSinceEpoch,
      ),
      _ => (
        start: DateTime(now.year).millisecondsSinceEpoch,
        end: DateTime(now.year + 1).millisecondsSinceEpoch,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('本月')),
                ButtonSegment(value: 1, label: Text('上月')),
                ButtonSegment(value: 2, label: Text('本年')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
          ),
        ),
      ),
      body: FutureBuilder<_StatsData>(
        future: _load(range.start, range.end),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('加载失败：${snap.error}'));
          }
          final data = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(expense: data.expense, income: data.income),
              const SizedBox(height: 16),
              _CategoryPieCard(
                categorySum: data.categorySum,
                categories: data.categories,
              ),
              const SizedBox(height: 16),
              _DailyTrendCard(daily: data.daily, start: range.start),
            ],
          );
        },
      ),
    );
  }

  Future<_StatsData> _load(int start, int end) async {
    final repo = ref.read(billRepoProvider);
    final summary = await repo.sumByType(start, end, BillType.expense);
    final income = await repo.sumByType(start, end, BillType.income);
    final categorySum = await repo.sumByCategoryInRange(
      start,
      end,
      BillType.expense,
    );
    final daily = await repo.dailyExpenseInRange(start, end);
    final categories = await ref.read(categoryRepoProvider).getAll();
    return _StatsData(
      expense: summary,
      income: income,
      categorySum: categorySum,
      daily: daily,
      categories: categories,
    );
  }
}

class _StatsData {
  const _StatsData({
    required this.expense,
    required this.income,
    required this.categorySum,
    required this.daily,
    required this.categories,
  });

  final int expense;
  final int income;
  final List<({String categoryId, int amount})> categorySum;
  final List<({int day, int amount})> daily;
  final List<Category> categories;
}

const _piePalette = [
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

String _catName(_StatsData data, String id) {
  for (final c in data.categories) {
    if (c.id == id) return c.name;
  }
  return '未知分类';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.expense, required this.income});

  final int expense;
  final int income;

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _cell(context, '支出', formatYuan(expense), Colors.red.shade400),
            _cell(context, '收入', formatYuan(income), Colors.green.shade600),
            _cell(
              context,
              '结余',
              formatYuan(balance),
              balance >= 0 ? Colors.green.shade600 : Colors.red.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({required this.categorySum, required this.categories});

  final List<({String categoryId, int amount})> categorySum;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final data = _StatsData(
      expense: 0,
      income: 0,
      categorySum: categorySum,
      daily: const [],
      categories: categories,
    );
    if (categorySum.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('本时段暂无支出')),
        ),
      );
    }
    final sorted = [...categorySum]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = sorted.fold<int>(0, (s, e) => s + e.amount);
    final top5 = sorted.take(5).toList();
    final otherAmount = total - top5.fold<int>(0, (s, e) => s + e.amount);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < top5.length; i++)
        PieChartSectionData(
          value: top5[i].amount.toDouble(),
          title: '${(top5[i].amount / total * 100).toStringAsFixed(0)}%',
          color: _piePalette[i % _piePalette.length],
          radius: 52,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      if (otherAmount > 0)
        PieChartSectionData(
          value: otherAmount.toDouble(),
          title: '${(otherAmount / total * 100).toStringAsFixed(0)}%',
          color: _piePalette[5],
          radius: 52,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('支出分类占比', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < top5.length; i++)
                        _legend(
                          _piePalette[i % _piePalette.length],
                          _catName(data, top5[i].categoryId),
                          '${formatYuan(top5[i].amount)}'
                          '（${(top5[i].amount / total * 100).toStringAsFixed(0)}%）',
                        ),
                      if (otherAmount > 0)
                        _legend(
                          _piePalette[5],
                          '其他',
                          '${formatYuan(otherAmount)}'
                              '（${(otherAmount / total * 100).toStringAsFixed(0)}%）',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _DailyTrendCard extends StatelessWidget {
  const _DailyTrendCard({required this.daily, required this.start});

  final List<({int day, int amount})> daily;
  final int start;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('本时段暂无支出')),
        ),
      );
    }
    final byDay = {for (final d in daily) d.day: d.amount};
    final days = (daily.last.day - daily.first.day + 1).clamp(1, 92);
    final firstDay = daily.first.day;
    final maxAmount = daily.fold<int>(0, (m, d) => d.amount > m ? d.amount : m);
    final groups = <BarChartGroupData>[
      for (var i = 0; i < days; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (byDay[firstDay + i] ?? 0) / (maxAmount > 0 ? maxAmount : 1),
              color: Theme.of(context).colorScheme.primary,
              width: 6,
            ),
          ],
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('每日支出趋势', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  barGroups: groups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 7,
                      ),
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '峰值 ${formatYuan(maxAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
