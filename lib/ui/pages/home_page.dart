import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/breakpoints.dart';
import '../widgets/bill_tile.dart';
import 'bookkeeping_sheet.dart';
import 'search_page.dart';

/// 首页：月汇总卡 + 过滤栏（类型/日期范围）+ 账单流。
///
/// 默认展示本月；上拉到底逐月加载更早数据（每次一个月）。
/// 选择自定义日期范围后一次性展示该范围（不再逐月加载）。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final summary =
        ref.watch(monthSummaryProvider).value ?? (expense: 0, income: 0);

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
      // 宽屏限宽居中，窄屏铺满（手机版式不变）
      body: ContentWidthBox(
        child: Column(
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
          // 第二行：类型过滤 + 日期范围选择
          _FilterBar(
            onPickRange: () => _pickCustomRange(context, ref),
            onResetRange: () {
              ref.read(homeCustomRangeProvider.notifier).state = null;
              ref.read(homeMonthsProvider.notifier).state = 1;
            },
          ),
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
                    // 自定义范围下整段已加载，无需分页
                    if (ref.read(homeCustomRangeProvider) != null) {
                      return false;
                    }
                    // 接近底部时多加载一个月
                    if (n is ScrollEndNotification &&
                        n.metrics.extentAfter < 200) {
                      ref.read(homeMonthsProvider.notifier).state += 1;
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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '记一笔',
        onPressed: () => BookkeepingSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 弹出日期范围选择（下界 = 最早账单日，上界 = 今天）。
  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final minT = await ref.read(minBillTimeProvider.future);
    if (!context.mounted) return;
    final now = DateTime.now();
    final first = minT == null
        ? now.subtract(const Duration(days: 365 * 5))
        : DateTime.fromMillisecondsSinceEpoch(minT);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: now,
      initialDateRange: null,
      helpText: '选择明细日期范围',
      saveText: '确定',
    );
    if (picked == null) return;
    if (!context.mounted) return;
    ref.read(homeCustomRangeProvider.notifier).state = (
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

/// 第二行过滤栏：类型选择（全部/支出/收入）+ 日期范围按钮。
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.onPickRange, required this.onResetRange});

  final VoidCallback onPickRange;
  final VoidCallback onResetRange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeTypeFilterProvider);
    final custom = ref.watch(homeCustomRangeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String rangeLabel;
    if (custom == null) {
      final months = ref.watch(homeMonthsProvider);
      final now = DateTime.now();
      if (months <= 1) {
        rangeLabel = '本月';
      } else {
        final start = DateTime(now.year, now.month - (months - 1));
        rangeLabel = '${start.year}/${start.month} ~ 今';
      }
    } else {
      final s = DateTime.fromMillisecondsSinceEpoch(custom.start);
      final e = DateTime.fromMillisecondsSinceEpoch(custom.end)
          .subtract(const Duration(days: 1));
      String f(DateTime d) =>
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      rangeLabel = '${f(s)} ~ ${f(e)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          // 类型过滤（全部 / 支出 / 收入）
          Expanded(
            child: SegmentedButton<HomeTypeFilter>(
              segments: const [
                ButtonSegment(
                  value: HomeTypeFilter.all,
                  label: Text('全部'),
                  icon: Icon(Icons.receipt_long_outlined),
                ),
                ButtonSegment(
                  value: HomeTypeFilter.expense,
                  label: Text('支出'),
                  icon: Icon(Icons.south_west),
                ),
                ButtonSegment(
                  value: HomeTypeFilter.income,
                  label: Text('收入'),
                  icon: Icon(Icons.north_east),
                ),
              ],
              selected: {filter},
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onSelectionChanged: (selection) {
                ref.read(homeTypeFilterProvider.notifier).state =
                    selection.first;
              },
            ),
          ),
          const SizedBox(width: 8),
          // 日期范围按钮
          ActionChip(
            avatar: Icon(
              Icons.date_range_outlined,
              size: 18,
              color: custom != null ? colorScheme.onPrimary : null,
            ),
            label: Text(rangeLabel),
            backgroundColor:
                custom != null ? colorScheme.primary : null,
            labelStyle: TextStyle(
              color: custom != null ? colorScheme.onPrimary : null,
              fontSize: 12,
            ),
            visualDensity: VisualDensity.compact,
            onPressed: custom != null
                ? () => showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('日期范围'),
                      content: Text('当前：$rangeLabel'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onResetRange();
                          },
                          child: const Text('恢复默认（本月）'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onPickRange();
                          },
                          child: const Text('重新选择'),
                        ),
                      ],
                    ),
                  )
                : onPickRange,
          ),
        ],
      ),
    );
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
          Text('该范围内还没有账单', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '点击右下角 + 记一笔，或调整上方的筛选条件',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
