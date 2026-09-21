import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_stagger_in.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import 'bookkeeping_sheet.dart';
import 'search_page.dart';

/// 首页：Hero 月汇总卡 + 过滤栏（类型/日期范围）+ 按日分组的账单卡流。
///
/// 默认展示本月；上拉到底逐月加载更早数据（每次一个月）。
/// 选择自定义日期范围后一次性展示该范围（不再逐月加载）。
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with XpPageScaffold<HomePage> {
  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsProvider);
    final summary =
        ref.watch(monthSummaryProvider).value ?? (expense: 0, income: 0);
    final now = DateTime.now();

    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('XuPurse'),
        actions: [
          IconButton(
            tooltip: '搜索',
            icon: const AppIcon(icon: Icons.search),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SearchPage())),
          ),
        ],
      ),
      // 整页骨架:账单流未就绪时 Hero/过滤栏/列表整体以骨架呈现,就绪后淡入
      loading: billsAsync.isLoading,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // 自定义范围下整段已加载，无需分页
          if (ref.read(homeCustomRangeProvider) != null) {
            return false;
          }
          // 接近底部时多加载一个月
          if (n is ScrollEndNotification && n.metrics.extentAfter < 200) {
            ref.read(homeMonthsProvider.notifier).state += 1;
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            // ── Hero：本月汇总（Display 32 大金额，强调靠字重） ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  XpSpacing.l,
                  XpSpacing.xs,
                  XpSpacing.l,
                  XpSpacing.s,
                ),
                child: _SummaryHero(
                  monthLabel: '${now.month}月 · 本月支出',
                  expense: summary.expense,
                  income: summary.income,
                ),
              ),
            ),
            // ── 过滤栏：类型 + 日期范围 ──
            SliverToBoxAdapter(
              child: _FilterBar(
                onPickRange: () => _pickCustomRange(context, ref),
                onResetRange: () {
                  ref.read(homeCustomRangeProvider.notifier).state = null;
                  ref.read(homeMonthsProvider.notifier).state = 1;
                },
              ),
            ),
            // ── 账单流 ──
            billsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: XpSkeletonList(),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('加载失败：$e')),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: XpEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: '该范围内还没有账单',
                        message: '点击右下角 + 记一笔，或调整上方的筛选条件',
                      ),
                    ),
                  );
                }
                return _buildBillSliver(context, ref, bills);
              },
            ),
            // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
            SliverPadding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 按日分组，每组一张卡片（组头含当日小计，分组时顺带累计）。
  Widget _buildBillSliver(
    BuildContext context,
    WidgetRef ref,
    List<Bill> bills,
  ) {
    final sections = <_DaySection>[];
    for (final bill in bills) {
      final dt = DateTime.fromMillisecondsSinceEpoch(bill.time);
      final dayStart = DateTime(
        dt.year,
        dt.month,
        dt.day,
      ).millisecondsSinceEpoch;
      if (sections.isEmpty || sections.last.dayStart != dayStart) {
        sections.add(
          _DaySection(
            dayStart: dayStart,
            day: DateTime(dt.year, dt.month, dt.day),
            bills: [bill],
          ),
        );
      } else {
        sections.last.bills.add(bill);
      }
      final s = sections.last;
      if (bill.type == 'expense') s.expense += bill.amount;
      if (bill.type == 'income') s.income += bill.amount;
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.xs,
        XpSpacing.l,
        96,
      ),
      sliver: SliverList.builder(
        itemCount: sections.length,
        itemBuilder: (context, i) {
          final section = sections[i];
          // stagger 淡入试点:仅前 12 组做动画,更深处直接渲染(性能守则)
          final item = _DayGroupCard(
            section: section,
            onTapBill: (bill) => BookkeepingSheet.show(context, bill: bill),
            onLongPressBill: (bill) => _confirmDelete(context, ref, bill),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: XpSpacing.m),
            child: i < 12 ? XpStaggerIn(index: i, child: item) : item,
          );
        },
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
    final ok = await confirmXpDialog(
      context,
      title: '删除账单',
      content: '删除后余额与快照将同步回滚，确定删除？',
      confirmLabel: '删除',
      danger: true,
    );
    if (ok && context.mounted) {
      await ref.read(billServiceProvider).deleteBill(bill.id);
    }
  }
}

/// "12345.60" → "12,345.60"（整数部分千分位，仅展示用）。
String _grouped(String raw) {
  final parts = raw.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buf.write(digits[i]);
    final remain = digits.length - 1 - i;
    if (remain > 0 && remain % 3 == 0) buf.write(',');
  }
  return parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
}

/// Hero 月汇总卡：大金额（Display 32/w700 tabular）+ 支收小计行。
/// 语义色只点缀圆点与小计，主金额用主文字色——强调靠字重，不靠颜色。
class _SummaryHero extends StatelessWidget {
  const _SummaryHero({
    required this.monthLabel,
    required this.expense,
    required this.income,
  });

  final String monthLabel;
  final int expense;
  final int income;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return XpCard(
      padding: const EdgeInsets.all(XpSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: XpSpacing.xs),
              Text(
                _grouped(formatYuan(expense)),
                style: textTheme.displayLarge
                    ?.copyWith(fontWeight: FontWeight.w700)
                    .tabular,
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          Row(
            children: [
              _LegendItem(
                color: XpSemanticColors.expense,
                label: '支出',
                value: _grouped(formatYuan(expense)),
              ),
              const SizedBox(width: XpSpacing.l),
              _LegendItem(
                color: XpSemanticColors.income,
                label: '收入',
                value: _grouped(formatYuan(income)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 小计图例：语义色圆点 + 标签 + 语义色金额。
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: XpSpacing.s),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: XpSpacing.xs),
        Text(
          value,
          style: textTheme.bodyMedium
              ?.copyWith(color: color, fontWeight: FontWeight.w600)
              .tabular,
        ),
      ],
    );
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
      final e = DateTime.fromMillisecondsSinceEpoch(
        custom.end,
      ).subtract(const Duration(days: 1));
      String f(DateTime d) =>
          '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
      rangeLabel = '${f(s)} ~ ${f(e)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        0,
        XpSpacing.l,
        XpSpacing.m,
      ),
      child: Row(
        children: [
          // 类型过滤（全部 / 支出 / 收入）
          Expanded(
            child: SegmentedButton<HomeTypeFilter>(
              segments: const [
                ButtonSegment(value: HomeTypeFilter.all, label: Text('全部')),
                ButtonSegment(value: HomeTypeFilter.expense, label: Text('支出')),
                ButtonSegment(value: HomeTypeFilter.income, label: Text('收入')),
              ],
              selected: {filter},
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: WidgetStatePropertyAll(StadiumBorder()),
              ),
              onSelectionChanged: (selection) {
                ref.read(homeTypeFilterProvider.notifier).state =
                    selection.first;
              },
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          // 日期范围按钮（ Flexible 防长文案在窄屏溢出）
          Flexible(
            child: ActionChip(
              avatar: AppIcon(
                icon: Icons.date_range_outlined,
                size: 18,
                color: custom != null ? colorScheme.onPrimary : null,
              ),
              label: Text(
                rangeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              backgroundColor: custom != null ? colorScheme.primary : null,
              labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: custom != null ? colorScheme.onPrimary : null,
              ),
              visualDensity: VisualDensity.compact,
              onPressed: custom != null
                  ? () => showXpDialog<void>(
                      context: context,
                      title: '日期范围',
                      content: '当前：$rangeLabel',
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onResetRange();
                          },
                          child: const Text('恢复默认（本月）'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onPickRange();
                          },
                          child: const Text('重新选择'),
                        ),
                      ],
                    )
                  : onPickRange,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单日账单分组数据（分组遍历时顺带累计当日小计）。
class _DaySection {
  _DaySection({required this.dayStart, required this.day, required this.bills});

  final int dayStart;
  final DateTime day;
  final List<Bill> bills;
  int expense = 0;
  int income = 0;
}

/// 日组卡：组头（日期 + 当日小计）+ 当日账单行。
class _DayGroupCard extends StatelessWidget {
  const _DayGroupCard({
    required this.section,
    required this.onTapBill,
    required this.onLongPressBill,
  });

  final _DaySection section;
  final void Function(Bill bill) onTapBill;
  final void Function(Bill bill) onLongPressBill;

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final d = section.day;
    final isToday =
        now.year == d.year && now.month == d.month && now.day == d.day;
    final label =
        '${d.month}月${d.day}日 ${_weekdays[d.weekday - 1]}${isToday ? ' · 今天' : ''}';

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    // 只展示非零项，避免「收 0.00」这类占位噪音
    final parts = <String>[
      if (section.expense > 0) '支 ${_grouped(formatYuan(section.expense))}',
      if (section.income > 0) '收 ${_grouped(formatYuan(section.income))}',
    ];

    return XpCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.m,
              XpSpacing.l,
              XpSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' · '),
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)
                        .tabular,
                  ),
              ],
            ),
          ),
          for (var i = 0; i < section.bills.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: XpSpacing.l,
                endIndent: XpSpacing.l,
              ),
            BillTile(
              bill: section.bills[i],
              onTap: () => onTapBill(section.bills[i]),
              onLongPress: () => onLongPressBill(section.bills[i]),
            ),
          ],
        ],
      ),
    );
  }
}
