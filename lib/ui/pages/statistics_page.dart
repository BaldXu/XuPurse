import 'package:drift/drift.dart' show Variable;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/budget_repository.dart';
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
              _TrendCard(
                title: _period == 2 ? '每月支出趋势' : '每周支出趋势',
                points: data.trend,
              ),
              const SizedBox(height: 16),
              _BudgetExecCard(start: range.start, end: range.end),
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
    final categories = await ref.read(categoryRepoProvider).getAll();
    // 趋势按粒度聚合（本地时区）：月份视图按周、年度视图按月
    final bills = await repo.listByRange(start, end, type: BillType.expense);
    final trend = _aggregateTrend(bills, byMonth: _period == 2);
    return _StatsData(
      expense: summary,
      income: income,
      categorySum: categorySum,
      trend: trend,
      categories: categories,
    );
  }

  /// 把区间内支出账单按周（周一起）或月聚合为趋势序列。
  List<({String label, int amount})> _aggregateTrend(
    List<Bill> bills, {
    required bool byMonth,
  }) {
    final map = <int, int>{};
    final labels = <int, String>{};
    for (final b in bills) {
      final dt = DateTime.fromMillisecondsSinceEpoch(b.time);
      final int key;
      final String label;
      if (byMonth) {
        key = DateTime(dt.year, dt.month).millisecondsSinceEpoch;
        label = '${dt.month}月';
      } else {
        final weekStart = dt.subtract(Duration(days: dt.weekday - 1));
        final ws = DateTime(weekStart.year, weekStart.month, weekStart.day);
        key = ws.millisecondsSinceEpoch;
        label = '${ws.month}/${ws.day}';
      }
      map[key] = (map[key] ?? 0) + b.amount;
      labels[key] = label;
    }
    final keys = map.keys.toList()..sort();
    return [for (final k in keys) (label: labels[k]!, amount: map[k]!)];
  }
}

class _StatsData {
  const _StatsData({
    required this.expense,
    required this.income,
    required this.categorySum,
    required this.trend,
    required this.categories,
  });

  final int expense;
  final int income;
  final List<({String categoryId, int amount})> categorySum;

  /// 按粒度（周/月）聚合的支出趋势。
  final List<({String label, int amount})> trend;
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
      trend: const [],
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

/// 预算执行单项（预算 + 当前区间内实际支出）。
class _BudgetExec {
  const _BudgetExec({required this.budget, required this.spent});

  final Budget budget;
  final int spent;
}

/// 预算执行模块：统计「与当前时间范围重叠」的预算及其支出进度。
class _BudgetExecCard extends ConsumerWidget {
  const _BudgetExecCard({required this.start, required this.end});

  final int start;
  final int end;

  Future<List<_BudgetExec>> _load(AppDatabase db, BudgetRepository repo) async {
    final budgets = await repo.getAll();
    final result = <_BudgetExec>[];
    for (final b in budgets) {
      if (b.type != BillType.expense.name) continue;
      final bStart = b.startTime;
      if (bStart == null) continue;
      final bEnd = b.endTime ?? bStart + 32 * 24 * 3600 * 1000;
      if (!(bStart < end && bEnd > start)) continue; // 与当前区间重叠
      final winStart = bStart > start ? bStart : start;
      final winEnd = bEnd < end ? bEnd : end;
      final rows = await db
          .customSelect(
            'SELECT COALESCE(SUM(amount), 0) AS s FROM bills '
            'WHERE type = ? AND time >= ? AND time < ? '
            '${b.categoryId != null ? 'AND category_id = ?' : ''}',
            variables: [
              Variable(BillType.expense.name),
              Variable(winStart),
              Variable(winEnd),
              if (b.categoryId != null) Variable(b.categoryId),
            ],
          )
          .get();
      final spent = rows.first.data['s'] as int? ?? 0;
      result.add(_BudgetExec(budget: b, spent: spent));
    }
    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(dbProvider);
    final repo = ref.watch(budgetRepoProvider);
    return FutureBuilder<List<_BudgetExec>>(
      future: _load(db, repo),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('预算执行计算中…')),
            ),
          );
        }
        final items = snap.data ?? const <_BudgetExec>[];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('预算执行', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                for (final item in items) _BudgetExecRow(item: item),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BudgetExecRow extends StatelessWidget {
  const _BudgetExecRow({required this.item});

  final _BudgetExec item;

  @override
  Widget build(BuildContext context) {
    final b = item.budget;
    final textTheme = Theme.of(context).textTheme;
    final progress = b.amount <= 0
        ? 0.0
        : (item.spent / b.amount).clamp(0.0, 1.0);
    final over = item.spent > b.amount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  b.name.isEmpty ? '未命名预算' : b.name,
                  style: textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${formatYuan(item.spent)} / ${formatYuan(b.amount)}'
                '${b.amount > 0 ? '（${(progress * 100).toStringAsFixed(0)}%）' : ''}',
                style: textTheme.bodySmall?.copyWith(
                  color: over
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: over
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// 支出趋势卡片（柱状图，按周/月粒度聚合）。
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.title, required this.points});

  final String title;
  final List<({String label, int amount})> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('本时段暂无支出')),
        ),
      );
    }
    final n = points.length;
    final maxAmount = points.fold<int>(
      0,
      (m, p) => p.amount > m ? p.amount : m,
    );
    final groups = <BarChartGroupData>[
      for (var i = 0; i < n; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: points[i].amount / (maxAmount > 0 ? maxAmount : 1),
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
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
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
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
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
