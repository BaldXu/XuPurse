import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/amount.dart';
import '../../../state/providers.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_skeleton.dart';
import 'stats_shared.dart';

/// 总览分区：收支汇总 KPI + 环比 + 日均。
class StatsOverviewSection extends ConsumerStatefulWidget {
  const StatsOverviewSection({
    super.key,
    required this.start,
    required this.end,
  });

  final int start;
  final int end;

  @override
  ConsumerState<StatsOverviewSection> createState() => _OverviewSectionState();
}

class _OverviewData {
  const _OverviewData({
    required this.expense,
    required this.income,
    required this.prevExpense,
    required this.prevIncome,
    required this.days,
  });

  final int expense;
  final int income;
  final int prevExpense;
  final int prevIncome;
  final double days;
}

class _OverviewSectionState extends ConsumerState<StatsOverviewSection>
    with StatsSectionRefresh {
  late Future<_OverviewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant StatsOverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  @override
  void onDataVersionChanged() {
    _future = _load();
  }

  Future<_OverviewData> _load() async {
    final repo = ref.read(billRepoProvider);
    final expense = await repo.sumByType(
      widget.start,
      widget.end,
      BillType.expense,
    );
    final income = await repo.sumByType(
      widget.start,
      widget.end,
      BillType.income,
    );
    // 环比：与上一段等长区间对比
    final span = widget.end - widget.start;
    final prevExpense = await repo.sumByType(
      widget.start - span,
      widget.start,
      BillType.expense,
    );
    final prevIncome = await repo.sumByType(
      widget.start - span,
      widget.start,
      BillType.income,
    );
    return _OverviewData(
      expense: expense,
      income: income,
      prevExpense: prevExpense,
      prevIncome: prevIncome,
      days: span / 86400000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewData>(
      future: _future,
      builder: (context, snap) => xpFadeGate(snap, () {
        if (snap.connectionState != ConnectionState.done) {
          return const XpSkeletonList();
        }
        if (snap.hasError) {
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final d = snap.data!;
        final balance = d.income - d.expense;
        return ListView(
          // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _SummaryCard(
              expense: d.expense,
              income: d.income,
              balance: balance,
            ),
            const SizedBox(height: 16),
            _CompareCard(
              expense: d.expense,
              income: d.income,
              prevExpense: d.prevExpense,
              prevIncome: d.prevIncome,
            ),
            const SizedBox(height: 16),
            _DailyCard(expense: d.expense, income: d.income, days: d.days),
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.expense,
    required this.income,
    required this.balance,
  });

  final int expense;
  final int income;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _cell(context, '支出', formatYuan(expense), XpSemanticColors.expense),
            _cell(context, '收入', formatYuan(income), XpSemanticColors.income),
            _cell(
              context,
              '结余',
              formatYuan(balance),
              balance >= 0 ? XpSemanticColors.income : XpSemanticColors.expense,
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

/// 环比卡：本期 vs 上一段等长区间，展示涨跌幅。
class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.expense,
    required this.income,
    required this.prevExpense,
    required this.prevIncome,
  });

  final int expense;
  final int income;
  final int prevExpense;
  final int prevIncome;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('环比对比', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _row(context, '支出', expense, prevExpense, upIsGood: false),
            const SizedBox(height: 8),
            _row(context, '收入', income, prevIncome, upIsGood: true),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    int current,
    int prev, {
    required bool upIsGood,
  }) {
    final pct = prev > 0 ? (current - prev) / prev * 100 : null;
    final (arrow, color) = pct == null
        ? ('—', Theme.of(context).colorScheme.onSurfaceVariant)
        : pct >= 0
        ? (
            upIsGood ? '↑' : '↑',
            upIsGood ? XpSemanticColors.income : XpSemanticColors.income,
          )
        : (
            upIsGood ? '↓' : '↓',
            upIsGood ? XpSemanticColors.expense : XpSemanticColors.expense,
          );
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Text(
            formatYuan(current),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          pct == null
              ? '上期 $label 无数据'
              : '$arrow ${pct.abs().toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// 日均卡。
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.expense,
    required this.income,
    required this.days,
  });

  final int expense;
  final int income;
  final double days;

  @override
  Widget build(BuildContext context) {
    final d = days > 0 ? days : 1.0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _cell(context, '日均支出', formatYuan((expense / d).round())),
            _cell(context, '日均收入', formatYuan((income / d).round())),
            _cell(context, '统计天数', days.toStringAsFixed(0)),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, String label, String value) {
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
