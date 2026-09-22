import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/amount.dart';
import '../../../data/database/app_database.dart';
import '../../../state/providers.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_skeleton.dart';
import 'stats_shared.dart';

/// 预算分区：预算执行进度。
class StatsBudgetSection extends ConsumerStatefulWidget {
  const StatsBudgetSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<StatsBudgetSection> createState() => _BudgetSectionState();
}

/// 预算执行单项（预算 + 当前区间内实际支出）。
class _BudgetExec {
  const _BudgetExec({required this.budget, required this.spent});

  final Budget budget;
  final int spent;
}

class _BudgetSectionState extends ConsumerState<StatsBudgetSection>
    with StatsSectionRefresh {
  late Future<List<_BudgetExec>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant StatsBudgetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  @override
  void onDataVersionChanged() {
    _future = _load();
  }

  Future<List<_BudgetExec>> _load() async {
    final db = ref.read(dbProvider);
    final repo = ref.read(budgetRepoProvider);
    final budgets = await repo.getAll();
    final result = <_BudgetExec>[];
    for (final b in budgets) {
      if (b.type != BillType.expense.name) continue;
      final bStart = b.startTime;
      if (bStart == null) continue;
      final bEnd = b.endTime ?? bStart + 32 * 24 * 3600 * 1000;
      if (!(bStart < widget.end && bEnd > widget.start)) continue; // 与当前区间重叠
      final winStart = bStart > widget.start ? bStart : widget.start;
      final winEnd = bEnd < widget.end ? bEnd : widget.end;
      final rows = await db
          .customSelect(
            'SELECT COALESCE(SUM(amount), 0) AS s FROM bills '
            'WHERE type = ? AND time >= ? AND time < ?'
            " AND (extra IS NULL OR (extra NOT LIKE '%\"excludeFromStats\":true%' AND extra NOT LIKE '%\"notInTotal\":true%'))"
            '${b.categoryId != null ? ' AND category_id = ?' : ''}',
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
  Widget build(BuildContext context) {
    return FutureBuilder<List<_BudgetExec>>(
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
        final items = snap.data ?? const <_BudgetExec>[];
        if (items.isEmpty) {
          return const XpCard(
            padding: EdgeInsets.zero,
            child: XpEmptyState(icon: Icons.savings_outlined, title: '本时段暂无预算'),
          );
        }
        return ListView(
          // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
          padding: EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.l,
            XpSpacing.l,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            XpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('预算执行', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: XpSpacing.m),
                  for (final item in items) _BudgetExecRow(item: item),
                ],
              ),
            ),
          ],
        );
      }),
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
      padding: const EdgeInsets.symmetric(vertical: XpSpacing.s),
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
                style: textTheme.bodySmall
                    ?.copyWith(
                      color: over
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                    .tabular,
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
