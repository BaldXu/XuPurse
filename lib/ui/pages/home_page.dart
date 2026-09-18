import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../widgets/bill_tile.dart';
import 'bookkeeping_sheet.dart';
import 'search_page.dart';

/// 首页：月汇总卡 + 账单流（按天分组、滚动懒加载、点按编辑、长按删除）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final summary =
        ref.watch(monthSummaryProvider).value ?? (expense: 0, income: 0);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('XuPurse'),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          // 月汇总卡
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCell(
                        label: '本月支出',
                        value: formatYuan(summary.expense),
                        color: kExpenseColor,
                      ),
                    ),
                    Expanded(
                      child: _SummaryCell(
                        label: '本月收入',
                        value: formatYuan(summary.income),
                        color: kIncomeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text('账单明细', style: textTheme.titleSmall),
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (bills) {
                if (bills.isEmpty) {
                  return const _EmptyHint();
                }
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    // 接近底部时追加加载条数（懒加载）
                    if (n is ScrollEndNotification &&
                        n.metrics.extentAfter < 200) {
                      ref.read(billsLimitProvider.notifier).state += 50;
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: bills.length,
                    itemBuilder: (context, i) {
                      final bill = bills[i];
                      int dayOf(Bill b) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(b.time);
                        return DateTime(
                          dt.year,
                          dt.month,
                          dt.day,
                        ).millisecondsSinceEpoch;
                      }

                      final showHeader =
                          i == 0 || dayOf(bill) != dayOf(bills[i - 1]);
                      return Column(
                        key: ValueKey(bill.id),
                        children: [
                          // 组与组之间的分隔线（组头自带日期）
                          if (showHeader && i > 0)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          if (showHeader)
                            _DayHeaderFor(bills: bills, index: i)
                          else
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          BillTile(
                            bill: bill,
                            onTap: () =>
                                BookkeepingSheet.show(context, bill: bill),
                            onLongPress: () =>
                                _confirmDelete(context, ref, bill),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '记一笔',
        onPressed: () => BookkeepingSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Bill bill,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账单'),
        content: const Text('删除后余额与快照将同步回滚，确定删除？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(billServiceProvider).deleteBill(bill.id);
    }
  }
}

/// 月汇总单元格。
class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 组头（当日小计）。为复用 BillDayGroups 的统计口径，这里内联轻量实现。
class _DayHeaderFor extends ConsumerWidget {
  const _DayHeaderFor({required this.bills, required this.index});

  final List<Bill> bills;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dt = DateTime.fromMillisecondsSinceEpoch(bills[index].time);
    final dayStart = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(
      dt.year,
      dt.month,
      dt.day + 1,
    ).millisecondsSinceEpoch;
    var expense = 0;
    var income = 0;
    for (final b in bills) {
      if (b.time < dayStart || b.time >= dayEnd) continue;
      if (b.type == 'expense') expense += b.amount;
      if (b.type == 'income') income += b.amount;
    }

    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;
    final label =
        '${dt.month}月${dt.day}日 ${weekdays[dt.weekday - 1]}${isToday ? ' · 今天' : ''}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Text(
            '支 ${formatYuan(expense)}  收 ${formatYuan(income)}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 空账单引导。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 56,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text('还没有账单', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '点击右下角 + 记下第一笔吧',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
