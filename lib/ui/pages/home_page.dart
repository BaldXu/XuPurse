import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../../state/theme_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_stagger_in.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/xp_sliding_segmented.dart';
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
  // ── 折叠状态（方案 A：重建 entries + 状态集合，展开轻量淡入）──

  /// 已折叠的月（key = '年-月'）：分组卡常驻，其下日组卡隐藏。
  final Set<String> _collapsedMonths = {};

  /// 已折叠的年：年分组卡常驻，该年所有月/日卡隐藏。
  final Set<int> _collapsedYears = {};

  /// 本次操作刚展开的月（key = '年-月'）：下一帧给其日组卡包 _FadeIn
  /// 淡入一次；post-frame 清空，滚动回收重建不会误播动画。
  final Set<String> _expandAnimate = {};

  @override
  Widget build(BuildContext context) {
    // 首次挂载（切 tab 进来）只渲染骨架：整页树（Hero 汇总 + 过滤栏 +
    // 按日卡片流）首帧全量构建会与转场/导航栏指示器动画抢帧，且卡片磨砂
    // 在未就绪图层上 readback 会闪灰黑；首帧渲染完成后自动重建真实内容
    // （xpFirstSettled 首帧门，仅首个未挂载帧生效，切回本 tab 不重播）。
    if (!xpFirstSettled) {
      return buildXpScaffold(
        appBar: AppBar(title: const Text('XuPurse')),
        body: const XpSkeletonPage(),
      );
    }
    final billsAsync = ref.watch(billsProvider);
    final summary =
        ref.watch(monthSummaryProvider).value ?? (expense: 0, income: 0);
    final now = DateTime.now();
    final appBar = AppBar(
      title: const Text('XuPurse'),
      actions: [
        IconButton(
          tooltip: '搜索',
          icon: const AppIcon(icon: Icons.search),
          onPressed: () => Navigator.of(
            context,
          ).push(XpRoute(builder: (_) => const SearchPage())),
        ),
      ],
    );
    // 磨砂穿透：滚动内容从磨砂栏后穿过，栏内模糊可见。
    final bleedTop = ref.watch(frostedGlassProvider).barsOn
        ? xpFrostedBleedTop(context, appBar)
        : 0.0;

    return buildXpScaffold(
      appBar: appBar,
      frostedBleed: true,
      // 整页骨架：仅在「无旧数据的首载」时呈现；刷新期 Riverpod 保留旧值
      // 仍 isLoading=true，不能算 loading，否则整页骨架闪一下再回来
      loading: billsAsync.isLoading && billsAsync.value == null,
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
            // 顶部穿透留白：随内容滚出，可从磨砂栏后穿过。
            SliverPadding(padding: EdgeInsets.only(top: bleedTop)),
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
              // 关键：逐月加载时 billsProvider 因 watch 重建会短暂进入
              // loading；若不跳过，列表被骨架替换导致内容塌缩，深滚位置被
              // 钳回顶部（表现为「加载后自动回滚到最上面」）。跳过重载
              // loading 后继续展示旧列表，新数据在底部追加、滚动位置不动。
              skipLoadingOnReload: true,
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: XpSkeletonList(),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: XpErrorState(
                  title: '账单加载失败',
                  message: '$e',
                  actionLabel: '重试',
                  onAction: () => ref.invalidate(billsProvider),
                ),
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
  /// 日分组之上叠加月/年分组卡（时间倒序，滚动方向新→旧）：
  /// - 每月第一组日卡前插月分组卡（含列表首组，统一显示）；
  /// - 跨年处再插主题色年分组卡（与当月月分组卡同现）；
  /// - 卡内红绿条：条总长 = 收入，红 = 支出占比，绿 = 余额占比。
  Widget _buildBillSliver(
    BuildContext context,
    WidgetRef ref,
    List<Bill> bills,
  ) {
    // 逐月收支柱（红绿条数据源；刻意不受类型筛选影响）
    final summaries = ref.watch(monthlySummariesProvider).value ?? const {};
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

    // 扁平化列表条目：跨月插月分组卡；跨年在其上再插主题色年分组卡。
    // 折叠（方案 A：重建 entries + 状态集合）：
    // - 月折叠：该月日组卡隐藏，月分组卡常驻可再展开；
    // - 年折叠：该年所有月/日卡隐藏，年分组卡常驻可再展开。
    void toggleMonth(String key) {
      setState(() {
        if (_collapsedMonths.contains(key)) {
          _collapsedMonths.remove(key);
          _expandAnimate.add(key);
        } else {
          _collapsedMonths.add(key);
          _expandAnimate.remove(key);
        }
      });
      _clearExpandAnimateAfterFrame();
    }

    void toggleYear(int year) {
      setState(() {
        if (_collapsedYears.contains(year)) {
          _collapsedYears.remove(year);
          // 展开动画覆盖该年所有月（逐月柱数据已全量在手）
          for (final k in summaries.keys) {
            if (k.startsWith('$year-')) _expandAnimate.add(k);
          }
        } else {
          _collapsedYears.add(year);
        }
      });
      _clearExpandAnimateAfterFrame();
    }

    // 稳定索引：日卡在「全量 sections」中的位置。折叠会压缩条目数，但
    // stagger 判断（<12）必须基于未折叠的稳定位置——否则折叠后深处日卡
    // 跨界进入前 12 组会被新包 XpStaggerIn，触发淡入意外重播。
    final stableIndex = <int, int>{};
    for (var i = 0; i < sections.length; i++) {
      stableIndex[sections[i].dayStart] = i;
    }

    final entries = <_BillListEntry>[];
    String? prevMonthKey;
    int? prevYear;
    for (final section in sections) {
      final y = section.day.year;
      final m = section.day.month;
      final monthKey = '$y-$m';
      final yearCollapsed = _collapsedYears.contains(y);
      final monthCollapsed = _collapsedMonths.contains(monthKey);
      if (prevYear != null && y != prevYear) {
        entries.add(
          _YearHeaderEntry(
            y,
            _yearSummary(summaries, y),
            collapsed: yearCollapsed,
          ),
        );
      }
      if (!yearCollapsed) {
        if (prevMonthKey == null || monthKey != prevMonthKey) {
          entries.add(
            _MonthHeaderEntry(
              y,
              m,
              summaries['$y-$m'],
              collapsed: monthCollapsed,
            ),
          );
        }
        if (!monthCollapsed) {
          entries.add(
            _DayEntry(
              section,
              stableIndex[section.dayStart]!,
              animateIn: _expandAnimate.contains(monthKey),
            ),
          );
        }
      }
      prevYear = y;
      prevMonthKey = monthKey;
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.xs,
        XpSpacing.l,
        96,
      ),
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final entry = entries[i];
          return switch (entry) {
            _YearHeaderEntry() => _YearGroupHeader(
              year: entry.year,
              summary: entry.summary,
              collapsed: entry.collapsed,
              onTap: () => toggleYear(entry.year),
            ),
            _MonthHeaderEntry() => _MonthGroupHeader(
              year: entry.year,
              month: entry.month,
              summary: entry.summary,
              collapsed: entry.collapsed,
              onTap: () => toggleMonth('${entry.year}-${entry.month}'),
            ),
            _DayEntry() => _buildDayCard(context, ref, entry),
          };
        },
      ),
    );
  }

  /// 日组卡：展开动画（_FadeIn）优先，其次维持 stagger 试点（仅前 12 组）。
  Widget _buildDayCard(BuildContext context, WidgetRef ref, _DayEntry entry) {
    final card = _DayGroupCard(
      section: entry.section,
      onTapBill: (bill) => BookkeepingSheet.show(context, bill: bill),
      onLongPressBill: (bill) => _confirmDelete(context, ref, bill),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: XpSpacing.m),
      child: entry.animateIn
          ? _FadeIn(child: card)
          : entry.dayIndex < 12
          ? XpStaggerIn(
              // key 稳定 stagger 的 State，避免列表 rebuild 时前 12 组动画重播
              key: ValueKey(entry.section.dayStart),
              index: entry.dayIndex,
              child: card,
            )
          : card,
    );
  }

  /// 展开动画标记只在下一帧生效：post-frame 清空，滚动回收重建时集合
  /// 已空 → 不会误播动画（_FadeIn 只在展开瞬间构建一次）。
  void _clearExpandAnimateAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _expandAnimate.clear();
    });
  }

  /// 弹出日期范围选择（下界 = 最早账单日，上界 = 今天）。
  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final minT = await ref.read(minBillTimeProvider.future);
    if (!context.mounted) return;
    final now = DateTime.now();
    final first = minT == null
        ? now.subtract(const Duration(days: 365 * 5))
        : DateTime.fromMillisecondsSinceEpoch(minT);
    final picked = await showXpDateRangePicker(
      context: context,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: now,
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

/// 汇总某年的逐月收支柱（范围为当前已加载区间，与列表展示口径一致）。
({int expense, int income})? _yearSummary(
  Map<String, ({int expense, int income})> summaries,
  int year,
) {
  var expense = 0;
  var income = 0;
  var found = false;
  for (final e in summaries.entries) {
    if (e.key.startsWith('$year-')) {
      found = true;
      expense += e.value.expense;
      income += e.value.income;
    }
  }
  return found ? (expense: expense, income: income) : null;
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
          // 类型过滤（全部 / 支出 / 收入）——滑块胶囊单选
          Expanded(
            child: XpSlidingSegmented<HomeTypeFilter>(
              items: const [
                XpSegmentedItem(value: HomeTypeFilter.all, label: '全部'),
                XpSegmentedItem(value: HomeTypeFilter.expense, label: '支出'),
                XpSegmentedItem(value: HomeTypeFilter.income, label: '收入'),
              ],
              selected: filter,
              onChanged: (value) {
                ref.read(homeTypeFilterProvider.notifier).state = value;
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

/// 明细列表条目（时间倒序）：分组头 或 日组卡。
sealed class _BillListEntry {
  const _BillListEntry();
}

/// 月分组头：跨月处（含列表首组）的卡片头——日历图标 +「x年x月」+
/// 红绿比例条，标记「从这里往下都是该月明细」。
class _MonthHeaderEntry extends _BillListEntry {
  const _MonthHeaderEntry(
    this.year,
    this.month,
    this.summary, {
    required this.collapsed,
  });

  final int year;
  final int month;

  /// 该月收支柱（红绿条数据；null = 未加载）。
  final ({int expense, int income})? summary;

  /// 该月是否已折叠（日组卡隐藏，分组卡常驻可再展开）。
  final bool collapsed;
}

/// 年分组头：跨年处的主题色大卡，比月卡更显眼。
class _YearHeaderEntry extends _BillListEntry {
  const _YearHeaderEntry(this.year, this.summary, {required this.collapsed});

  final int year;

  /// 该年收支柱（当前已加载月份的合计；null = 未加载）。
  final ({int expense, int income})? summary;

  /// 该年是否已折叠（该年所有月/日卡隐藏，分组卡常驻可再展开）。
  final bool collapsed;
}

/// 日组卡条目（dayIndex 供 stagger 差分延迟；animateIn 供展开淡入）。
class _DayEntry extends _BillListEntry {
  const _DayEntry(this.section, this.dayIndex, {required this.animateIn});

  final _DaySection section;
  final int dayIndex;

  /// 是否本次展开动画目标（包 _FadeIn 淡入一次）。
  final bool animateIn;
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

/// 月分组卡：日历图标 +「x年x月」+ 红绿比例条，卡片背景与日组卡同层。
/// 点击折叠/展开该月（折叠时箭头朝下提示展开，展开时朝上提示收起）。
class _MonthGroupHeader extends StatelessWidget {
  const _MonthGroupHeader({
    required this.year,
    required this.month,
    this.summary,
    required this.collapsed,
    required this.onTap,
  });

  final int year;
  final int month;
  final ({int expense, int income})? summary;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, XpSpacing.xs, 0, XpSpacing.m),
      child: XpCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: XpSpacing.m,
        ),
        child: Row(
          children: [
            AppIcon(
              icon: Icons.calendar_month_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: XpSpacing.s),
            Text(
              '$year年$month月',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: XpSpacing.l),
            Expanded(
              child: _RatioBar(
                expense: summary?.expense ?? 0,
                income: summary?.income ?? 0,
              ),
            ),
            const SizedBox(width: XpSpacing.s),
            AnimatedRotation(
              turns: collapsed ? 0 : 0.5,
              duration: XpMotion.component,
              curve: XpMotion.easeOut,
              child: AppIcon(
                icon: Icons.keyboard_arrow_down,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 年分组卡：主题色大卡——日历图标 +「x年」大字 + 红绿比例条，比月卡显眼。
/// 点击折叠/展开该年。
class _YearGroupHeader extends StatelessWidget {
  const _YearGroupHeader({
    required this.year,
    this.summary,
    required this.collapsed,
    required this.onTap,
  });

  final int year;
  final ({int expense, int income})? summary;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, XpSpacing.s, 0, XpSpacing.xs),
      child: XpCard(
        color: colorScheme.primary,
        onTap: onTap,
        padding: const EdgeInsets.all(XpSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon(
                  icon: Icons.calendar_month,
                  size: 22,
                  color: colorScheme.onPrimary,
                ),
                const SizedBox(width: XpSpacing.s),
                Text(
                  '$year年',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: collapsed ? 0 : 0.5,
                  duration: XpMotion.component,
                  curve: XpMotion.easeOut,
                  child: AppIcon(
                    icon: Icons.keyboard_arrow_down,
                    size: 22,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: XpSpacing.m),
            _RatioBar(
              height: 8,
              expense: summary?.expense ?? 0,
              income: summary?.income ?? 0,
            ),
          ],
        ),
      ),
    );
  }
}

/// 储蓄率条：绿底 = 该范围总收入；红条从最左按占比增长 = 支出进度，
/// 剩余绿 = 储蓄。支出超出收入（或收入为 0 但有支出）时整条变灰黑；
/// 无任何收支数据时不渲染。
class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.expense,
    required this.income,
    this.height = 6,
  });

  final int expense;
  final int income;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (expense <= 0 && income <= 0) return const SizedBox.shrink();
    // 无收入或有支出超支 → 整条灰黑（无储蓄可看）
    final over = income <= 0 || expense > income;
    final Widget fill;
    if (over) {
      fill = const ColoredBox(color: XpElevation.shadow);
    } else {
      // 绿底（总收入）铺满整条；红（支出）用 Positioned 显式定宽、恒靠左。
      // 不用 flex/StackFit：宽 = 条宽 × 占比，任何约束下都精确渲染。
      fill = LayoutBuilder(
        builder: (context, constraints) {
          final redWidth = constraints.maxWidth * (expense / income);
          return Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: XpSemanticColors.income),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: redWidth,
                child: const ColoredBox(color: XpSemanticColors.expenseStrong),
              ),
            ],
          );
        },
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(XpRadius.pill),
      child: SizedBox(height: height, child: fill),
    );
  }
}

/// 展开淡入：State 创建后淡入一次（无 index 差分，时长 XpMotion.component）。
/// 仅由「折叠展开」触发（_expandAnimate 命中时包一层），滚动回收重建
/// 不包此组件，不会误播动画；reduce-motion 时直接返回 child。
class _FadeIn extends StatefulWidget {
  const _FadeIn({required this.child});

  final Widget child;

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: XpMotion.component,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: XpMotion.easeOut),
      child: widget.child,
    );
  }
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
