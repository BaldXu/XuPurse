import 'package:drift/drift.dart' show Variable;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/breakpoints.dart';
import '../tokens/design_tokens.dart';
import '../widgets/ai_chat_sheet.dart';

/// 统计页：侧边栏分区（宽屏 NavigationRail / 窄屏横向 Tab）+ 日期范围下拉。
///
/// 分区：
/// - 总览：收支汇总 KPI + 环比 + 日均
/// - 分类：支出 / 收入分类占比
/// - 趋势：支出趋势（粒度随范围自适应：日 → 周 → 月）
/// - 预算：预算执行进度
/// - 标签：标签支出 Top
///
/// 日期范围：本月 / 上月 / 本年 / 去年 / 最近一周 / 自定义（日历，
/// 可选下界为最早账单时间，上界为今天），全部分区共用同一范围。
class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

/// 侧边栏分区。
enum _Section {
  overview('总览', Icons.grid_view_outlined, Icons.grid_view_rounded),
  category('分类', Icons.pie_chart_outline, Icons.pie_chart),
  trend('趋势', Icons.bar_chart_outlined, Icons.bar_chart),
  budget('预算', Icons.savings_outlined, Icons.savings),
  tag('标签', Icons.label_outline, Icons.label_rounded);

  const _Section(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// 预设时间范围。
enum _RangePreset {
  thisMonth('本月'),
  lastMonth('上月'),
  thisYear('本年'),
  lastYear('去年'),
  lastWeek('最近一周'),
  custom('自定义范围');

  const _RangePreset(this.label);

  final String label;
}

/// 趋势聚合粒度。
enum _Granularity { day, week, month }

String _fmtDate(DateTime d) =>
    '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  _Section _section = _Section.overview;
  _RangePreset _preset = _RangePreset.thisMonth;
  DateTimeRange? _customRange;

  /// 最早账单时间（日历自定义范围的下界）；无账单时为 null。
  DateTime? _earliest;

  @override
  void initState() {
    super.initState();
    _loadEarliest();
  }

  Future<void> _loadEarliest() async {
    final t = await ref.read(billRepoProvider).minBillTime();
    if (!mounted) return;
    setState(() {
      _earliest = t == null ? null : DateTime.fromMillisecondsSinceEpoch(t);
    });
  }

  /// 当前生效范围 [start, end)（毫秒）。
  ({int start, int end}) get _range {
    final now = DateTime.now();
    switch (_preset) {
      case _RangePreset.thisMonth:
        return (
          start: DateTime(now.year, now.month).millisecondsSinceEpoch,
          end: DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
        );
      case _RangePreset.lastMonth:
        return (
          start: DateTime(now.year, now.month - 1).millisecondsSinceEpoch,
          end: DateTime(now.year, now.month).millisecondsSinceEpoch,
        );
      case _RangePreset.thisYear:
        return (
          start: DateTime(now.year).millisecondsSinceEpoch,
          end: DateTime(now.year + 1).millisecondsSinceEpoch,
        );
      case _RangePreset.lastYear:
        return (
          start: DateTime(now.year - 1).millisecondsSinceEpoch,
          end: DateTime(now.year).millisecondsSinceEpoch,
        );
      case _RangePreset.lastWeek:
        final today = DateTime(now.year, now.month, now.day);
        return (
          start: today.subtract(const Duration(days: 6)).millisecondsSinceEpoch,
          end: today.add(const Duration(days: 1)).millisecondsSinceEpoch,
        );
      case _RangePreset.custom:
        final r = _customRange;
        if (r == null) {
          // 理论不可达：custom 仅在日历选择后才会被设置。
          return (
            start: DateTime(now.year, now.month).millisecondsSinceEpoch,
            end: DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
          );
        }
        return (
          start: r.start.millisecondsSinceEpoch,
          end: r.end.add(const Duration(days: 1)).millisecondsSinceEpoch,
        );
    }
  }

  /// 下拉按钮上显示的范围名。
  String get _rangeLabel {
    if (_preset != _RangePreset.custom) return _preset.label;
    final r = _customRange;
    if (r == null) return _RangePreset.custom.label;
    return '${_fmtDate(r.start)} ~ ${_fmtDate(r.end)}';
  }

  /// 实际起止日期（用于范围说明小字）。
  String get _rangeDetail {
    final r = _range;
    final s = DateTime.fromMillisecondsSinceEpoch(r.start);
    final e = DateTime.fromMillisecondsSinceEpoch(
      r.end,
    ).subtract(const Duration(milliseconds: 1));
    return '${_fmtDate(s)} ~ ${_fmtDate(e)}';
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final first = _earliest ?? now.subtract(const Duration(days: 365 * 5));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDateRange: _customRange,
      helpText: '选择统计范围',
      saveText: '确定',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _preset = _RangePreset.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Column(
            children: [
              _RangeDropdown(
                label: _rangeLabel,
                preset: _preset,
                onPresetSelected: (p) {
                  if (p == _RangePreset.custom) {
                    _pickCustomRange();
                  } else {
                    setState(() => _preset = p);
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _rangeDetail,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= kSectionBreakpoint;
          return wide ? _buildWide(range) : _buildNarrow(range);
        },
      ),
      floatingActionButton: const AiFab(),
    );
  }

  /// 宽屏：左侧 NavigationRail 常驻。
  Widget _buildWide(({int start, int end}) range) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _section.index,
          labelType: NavigationRailLabelType.all,
          onDestinationSelected: (i) =>
              setState(() => _section = _Section.values[i]),
          destinations: [
            for (final s in _Section.values)
              NavigationRailDestination(
                icon: Icon(s.icon),
                selectedIcon: Icon(s.selectedIcon),
                label: Text(s.label),
              ),
          ],
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildSection(range)),
      ],
    );
  }

  /// 窄屏：顶部横向滑动 Tab。
  Widget _buildNarrow(({int start, int end}) range) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _Section.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = _Section.values[i];
              final selected = i == _section.index;
              return ChoiceChip(
                label: Text(s.label),
                selected: selected,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() => _section = s),
              );
            },
          ),
        ),
        Expanded(child: _buildSection(range)),
      ],
    );
  }

  /// 当前分区内容；用 ValueKey 保证切换范围后重新加载。
  Widget _buildSection(({int start, int end}) range) {
    final key = ValueKey('${_section.name}-${range.start}-${range.end}');
    Widget section = switch (_section) {
      _Section.overview => _OverviewSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.category => _CategorySection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.trend => _TrendSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.budget => _BudgetSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.tag => _TagSection(key: key, start: range.start, end: range.end),
    };
    // 宽屏限宽居中，避免卡片/图表在桌面大屏上无限拉伸。
    section = ContentWidthBox(maxWidth: 960, child: section);
    return section;
  }
}

/// 日期范围下拉。
class _RangeDropdown extends StatelessWidget {
  const _RangeDropdown({
    required this.label,
    required this.preset,
    required this.onPresetSelected,
  });

  final String label;
  final _RangePreset preset;
  final ValueChanged<_RangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_RangePreset>(
      onSelected: onPresetSelected,
      tooltip: '选择时间范围',
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final p in _RangePreset.values)
          if (p == _RangePreset.custom)
            const PopupMenuDivider()
          else
            PopupMenuItem(
              value: p,
              child: Row(
                children: [
                  if (preset == p)
                    Icon(Icons.check, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(p.label),
                ],
              ),
            ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _RangePreset.custom,
          child: Row(
            children: [
              Icon(Icons.date_range_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(_RangePreset.custom.label),
            ],
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// 趋势粒度：随范围天数自适应（≤14 天按日、≤62 天按周、其余按月）。
_Granularity _granularityFor(int start, int end) {
  final days = (end - start) / 86400000;
  if (days <= 14) return _Granularity.day;
  if (days <= 62) return _Granularity.week;
  return _Granularity.month;
}

String _granularityLabel(_Granularity g) => switch (g) {
  _Granularity.day => '每日支出趋势',
  _Granularity.week => '每周支出趋势',
  _Granularity.month => '每月支出趋势',
};

/// 把区间内支出账单按日/周/月聚合为趋势序列。
List<({String label, int amount})> _aggregateTrend(
  List<Bill> bills, {
  required _Granularity granularity,
}) {
  final map = <int, int>{};
  final labels = <int, String>{};
  for (final b in bills) {
    final dt = DateTime.fromMillisecondsSinceEpoch(b.time);
    final int key;
    final String label;
    switch (granularity) {
      case _Granularity.day:
        key = DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
        label = '${dt.month}/${dt.day}';
      case _Granularity.week:
        final ws = dt.subtract(Duration(days: dt.weekday - 1));
        final wk = DateTime(ws.year, ws.month, ws.day);
        key = wk.millisecondsSinceEpoch;
        label = '${wk.month}/${wk.day}';
      case _Granularity.month:
        key = DateTime(dt.year, dt.month).millisecondsSinceEpoch;
        label = '${dt.month}月';
    }
    map[key] = (map[key] ?? 0) + b.amount;
    labels[key] = label;
  }
  final keys = map.keys.toList()..sort();
  return [for (final k in keys) (label: labels[k]!, amount: map[k]!)];
}

// ---------------------------------------------------------------------------
// 总览分区
// ---------------------------------------------------------------------------

class _OverviewSection extends ConsumerStatefulWidget {
  const _OverviewSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_OverviewSection> createState() => _OverviewSectionState();
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

class _OverviewSectionState extends ConsumerState<_OverviewSection> {
  late Future<_OverviewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _OverviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
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
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final d = snap.data!;
        final balance = d.income - d.expense;
        return ListView(
          padding: const EdgeInsets.all(16),
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
      },
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

// ---------------------------------------------------------------------------
// 分类分区
// ---------------------------------------------------------------------------

class _CategorySection extends ConsumerStatefulWidget {
  const _CategorySection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<_CategorySection> {
  late Future<_CategoryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _CategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  Future<_CategoryData> _load() async {
    final repo = ref.read(billRepoProvider);
    final expenseSum = await repo.sumByCategoryInRange(
      widget.start,
      widget.end,
      BillType.expense,
    );
    final incomeSum = await repo.sumByCategoryInRange(
      widget.start,
      widget.end,
      BillType.income,
    );
    final categories = await ref.read(categoryRepoProvider).getAll();
    return _CategoryData(
      expenseSum: expenseSum,
      incomeSum: incomeSum,
      categories: categories,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CategoryData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final d = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CategoryPieCard(
              title: '支出分类占比',
              emptyHint: '本时段暂无支出',
              categorySum: d.expenseSum,
              categories: d.categories,
            ),
            const SizedBox(height: 16),
            _CategoryPieCard(
              title: '收入分类占比',
              emptyHint: '本时段暂无收入',
              categorySum: d.incomeSum,
              categories: d.categories,
            ),
            const SizedBox(height: 16),
            _CategoryRankCard(
              start: widget.start,
              end: widget.end,
              data: d,
            ),
          ],
        );
      },
    );
  }
}

/// 分类金额排行卡：支出/收入切换 + 按一级分类聚合排序 + 点击看明细。
class _CategoryRankCard extends ConsumerStatefulWidget {
  const _CategoryRankCard({
    required this.start,
    required this.end,
    required this.data,
  });

  final int start;
  final int end;
  final _CategoryData data;

  @override
  ConsumerState<_CategoryRankCard> createState() => _CategoryRankCardState();
}

class _CategoryRankCardState extends ConsumerState<_CategoryRankCard> {
  BillType _type = BillType.expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leafSum = _type == BillType.expense
        ? widget.data.expenseSum
        : widget.data.incomeSum;
    final ranked = widget.data.topLevelSum(leafSum);
    final total = ranked.fold<int>(0, (s, e) => s + e.amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '分类金额排行',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SegmentedButton<BillType>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: BillType.expense, label: Text('支出')),
                    ButtonSegment(value: BillType.income, label: Text('收入')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '按一级分类合计金额排序，点击查看明细',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (ranked.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    _type == BillType.expense ? '本时段暂无支出' : '本时段暂无收入',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              )
            else
              for (var i = 0; i < ranked.length; i++)
                _RankTile(
                  rank: i + 1,
                  name: _catName(widget.data.categories, ranked[i].categoryId),
                  amount: ranked[i].amount,
                  percent: total <= 0 ? 0 : ranked[i].amount / total,
                  color: _piePalette[i % _piePalette.length],
                  onTap: () => _showDetail(ranked[i].categoryId),
                ),
          ],
        ),
      ),
    );
  }

  /// 明细弹窗：该一级分类（含其子分类）在时间范围内的账单列表。
  void _showDetail(String topCategoryId) {
    final name = _catName(widget.data.categories, topCategoryId);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) =>
          _CategoryDetailSheet(
            start: widget.start,
            end: widget.end,
            type: _type,
            topCategoryId: topCategoryId,
            title: name,
            data: widget.data,
          ),
    );
  }
}

class _CategoryDetailSheet extends ConsumerStatefulWidget {
  const _CategoryDetailSheet({
    required this.start,
    required this.end,
    required this.type,
    required this.topCategoryId,
    required this.title,
    required this.data,
  });

  final int start;
  final int end;
  final BillType type;
  final String topCategoryId;
  final String title;
  final _CategoryData data;

  @override
  ConsumerState<_CategoryDetailSheet> createState() =>
      _CategoryDetailSheetState();
}

class _CategoryDetailSheetState extends ConsumerState<_CategoryDetailSheet> {
  Future<List<Bill>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Bill>> _load() async {
    final repo = ref.read(billRepoProvider);
    final bills = await repo.listByRange(widget.start, widget.end);
    // 该一级分类（含其所有子分类）的账单
    final wanted = <String>{widget.topCategoryId};
    // 收集所有子分类 id（多级）
    var changed = true;
    while (changed) {
      changed = false;
      for (final c in widget.data.categories) {
        if (c.parentId != null && wanted.contains(c.parentId)) {
          if (wanted.add(c.id)) changed = true;
        }
      }
    }
    return [
      for (final b in bills)
        if (b.type == widget.type.name && wanted.contains(b.categoryId)) b,
    ]..sort((a, b) => b.time.compareTo(a.time));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Bill>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('加载失败：${snap.error}'));
                  }
                  final bills = snap.data!;
                  if (bills.isEmpty) {
                    return const Center(child: Text('该时间范围内暂无明细'));
                  }
                  var total = 0;
                  for (final b in bills) {
                    total += b.amount;
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: bills.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '共 ${bills.length} 笔，合计 ${formatYuan(total)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final b = bills[i - 1];
                      return _DetailRow(bill: b, categories: widget.data.categories);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.bill, required this.categories});

  final Bill bill;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateTime.fromMillisecondsSinceEpoch(bill.time);
    final childName = _catName(categories, bill.categoryId);
    final isExpense = bill.type == BillType.expense.name;
    final comment = (bill.comment ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (comment.isNotEmpty)
                  Text(
                    comment,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${formatYuan(bill.amount)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isExpense
                  ? theme.colorScheme.onSurface
                  : XpSemanticColors.income,
            ),
          ),
        ],
      ),
    );
  }
}

/// 排行单行。
class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
    required this.onTap,
  });

  final int rank;
  final String name;
  final int amount;
  final double percent;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(name, style: theme.textTheme.bodyMedium),
            ),
            Text(
              formatYuan(amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 46,
              child: Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData({
    required this.expenseSum,
    required this.incomeSum,
    required this.categories,
  });

  final List<({String categoryId, int amount})> expenseSum;
  final List<({String categoryId, int amount})> incomeSum;
  final List<Category> categories;

  /// id → 分类
  Map<String, Category> get byId {
    final m = <String, Category>{};
    for (final c in categories) {
      m[c.id] = c;
    }
    return m;
  }

  /// 沿 parentId 上溯到一级分类 id（自身即一级时返回自身）。
  String topParentId(String categoryId) {
    final byIdMap = byId;
    var cur = categoryId;
    final seen = <String>{};
    while (true) {
      final c = byIdMap[cur];
      if (c == null || c.parentId == null || !seen.add(cur)) return cur;
      cur = c.parentId!;
    }
  }

  /// 把叶子级金额聚合（[sumByCategoryInRange]）归并到一级分类，返回
  /// 排序后的列表（金额降序）。结果不含未用到的分类。
  List<({String categoryId, int amount, int count})> topLevelSum(
    List<({String categoryId, int amount})> leafSum,
  ) {
    final agg = <String, int>{};
    for (final e in leafSum) {
      final top = topParentId(e.categoryId);
      agg[top] = (agg[top] ?? 0) + e.amount;
    }
    final list = <({String categoryId, int amount, int count})>[
      for (final e in agg.entries)
        (
          categoryId: e.key,
          amount: e.value,
          count: leafSum
              .where((s) => topParentId(s.categoryId) == e.key)
              .length,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
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

String _catName(List<Category> categories, String id) {
  for (final c in categories) {
    if (c.id == id) return c.name;
  }
  return '未知分类';
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({
    required this.title,
    required this.emptyHint,
    required this.categorySum,
    required this.categories,
  });

  final String title;
  final String emptyHint;
  final List<({String categoryId, int amount})> categorySum;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categorySum.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(emptyHint)),
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
            Text(title, style: Theme.of(context).textTheme.titleSmall),
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
                          _catName(categories, top5[i].categoryId),
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

// ---------------------------------------------------------------------------
// 趋势分区
// ---------------------------------------------------------------------------

class _TrendSection extends ConsumerStatefulWidget {
  const _TrendSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_TrendSection> createState() => _TrendSectionState();
}

class _TrendSectionState extends ConsumerState<_TrendSection> {
  late Future<_TrendData> _future;
  _Granularity _granularity = _Granularity.week;

  @override
  void initState() {
    super.initState();
    _granularity = _granularityFor(widget.start, widget.end);
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _TrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      // 范围变化：重置为自适应默认粒度，并重新加载
      _granularity = _granularityFor(widget.start, widget.end);
      _future = _load();
    }
  }

  Future<_TrendData> _load() async {
    final bills = await ref
        .read(billRepoProvider)
        .listByRange(widget.start, widget.end, type: BillType.expense);
    return _TrendData(
      granularity: _granularity,
      points: _aggregateTrend(bills, granularity: _granularity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TrendData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final d = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TrendCard(
              title: _granularityLabel(d.granularity),
              points: d.points,
              granularity: _granularity,
              onGranularityChanged: (g) {
                setState(() {
                  _granularity = g;
                  _future = _load();
                });
              },
            ),
            const SizedBox(height: 16),
            _TrendCompareCard(
              start: widget.start,
              end: widget.end,
            ),
          ],
        );
      },
    );
  }
}

class _TrendData {
  const _TrendData({required this.granularity, required this.points});

  final _Granularity granularity;
  final List<({String label, int amount})> points;
}

/// 支出趋势卡片（柱状图，按日/周/月粒度聚合；支持手动切换粒度）。
class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.points,
    required this.granularity,
    required this.onGranularityChanged,
  });

  final String title;
  final List<({String label, int amount})> points;
  final _Granularity granularity;
  final ValueChanged<_Granularity> onGranularityChanged;

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
    final theme = Theme.of(context);
    final groups = <BarChartGroupData>[
      for (var i = 0; i < n; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              // 直接用真实金额（万分之元），悬浮框/坐标才是真实数值
              toY: points[i].amount.toDouble(),
              color: theme.colorScheme.primary,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SegmentedButton<_Granularity>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: _Granularity.day, label: Text('日')),
                    ButtonSegment(value: _Granularity.week, label: Text('周')),
                    ButtonSegment(value: _Granularity.month, label: Text('月')),
                  ],
                  selected: {granularity},
                  onSelectionChanged: (s) => onGranularityChanged(s.first),
                ),
              ],
            ),
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
                              style: theme.textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  // 悬浮提示：白底 + 灰边 + 真实金额
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      tooltipBorder: BorderSide(
                        color: theme.colorScheme.outline,
                      ),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final i = group.x.toInt();
                        if (i < 0 || i >= points.length) return null;
                        final p = points[i];
                        return BarTooltipItem(
                          '${p.label}\n¥ ${formatYuan(p.amount)}',
                          TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '峰值 ${formatYuan(maxAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一级分类环比卡：当前区间 vs 上一区间，各一级分类支出金额浮动。
class _TrendCompareCard extends ConsumerStatefulWidget {
  const _TrendCompareCard({required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_TrendCompareCard> createState() => _TrendCompareCardState();
}

class _TrendCompareCardState extends ConsumerState<_TrendCompareCard> {
  late Future<_TrendCompareData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _TrendCompareCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  Future<_TrendCompareData> _load() async {
    final repo = ref.read(billRepoProvider);
    final span = widget.end - widget.start;
    final prevStart = widget.start - span;
    final prevEnd = widget.start;

    final curBills = await repo.listByRange(
      widget.start,
      widget.end,
      type: BillType.expense,
    );
    final prevBills = await repo.listByRange(
      prevStart,
      prevEnd,
      type: BillType.expense,
    );
    final categories = await ref.read(categoryRepoProvider).getAll();
    final byId = {for (final c in categories) c.id: c};

    // 上溯到一级分类
    String topId(String id) {
      var cur = id;
      final seen = <String>{};
      while (true) {
        final c = byId[cur];
        if (c == null || c.parentId == null || !seen.add(cur)) return cur;
        cur = c.parentId!;
      }
    }

    final curAgg = <String, int>{};
    for (final b in curBills) {
      final t = topId(b.categoryId);
      curAgg[t] = (curAgg[t] ?? 0) + b.amount;
    }
    final prevAgg = <String, int>{};
    for (final b in prevBills) {
      final t = topId(b.categoryId);
      prevAgg[t] = (prevAgg[t] ?? 0) + b.amount;
    }

    // 合并所有出现过的顶级分类（当前或上个区间）
    final allKeys = <String>{...curAgg.keys, ...prevAgg.keys};
    final rows = <_CompareRow>[
      for (final k in allKeys)
        _CompareRow(
          categoryId: k,
          name: byId[k]?.name ?? '未知分类',
          current: curAgg[k] ?? 0,
          previous: prevAgg[k] ?? 0,
        ),
    ]..sort((a, b) => (b.current - b.previous).abs().compareTo(
          (a.current - a.previous).abs(),
        ));
    return _TrendCompareData(rows: rows, spanMs: span);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<_TrendCompareData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('加载失败：${snap.error}')),
            ),
          );
        }
        final d = snap.data!;
        if (d.rows.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('本时段暂无支出')),
            ),
          );
        }
        final totalChange = d.rows.fold<int>(
          0,
          (s, r) => s + (r.current - r.previous),
        );
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '分类环比',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '与上一周期（${_spanLabel(d.spanMs)}）对比，各一级分类支出浮动',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final row in d.rows) _CompareRowTile(row: row),
                const SizedBox(height: 8),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '合计变动',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        totalChange >= 0
                            ? '+${formatYuan(totalChange)}'
                            : '-${formatYuan(totalChange.abs())}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: totalChange >= 0
                              ? XpSemanticColors.expense
                              : XpSemanticColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrendCompareData {
  const _TrendCompareData({required this.rows, required this.spanMs});

  final List<_CompareRow> rows;
  final int spanMs;
}

class _CompareRow {
  const _CompareRow({
    required this.categoryId,
    required this.name,
    required this.current,
    required this.previous,
  });

  final String categoryId;
  final String name;
  final int current;
  final int previous;

  int get diff => current - previous;
}

class _CompareRowTile extends StatelessWidget {
  const _CompareRowTile({required this.row});

  final _CompareRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = row.diff;
    final up = diff >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(row.name, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '${formatYuan(row.previous)} → ${formatYuan(row.current)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: Text(
              diff == 0
                  ? '持平'
                  : '${up ? '+' : '-'}${formatYuan(diff.abs())}',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: diff == 0
                    ? theme.colorScheme.onSurfaceVariant
                    : up
                    ? XpSemanticColors.expense
                    : XpSemanticColors.income,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _spanLabel(int spanMs) {
  final days = spanMs / 86400000;
  if (days >= 360) return '${(days / 365).round()}年';
  if (days >= 30) return '${(days / 30).round()}个月';
  return '${days.round()}天';
}

// ---------------------------------------------------------------------------
// 预算分区
// ---------------------------------------------------------------------------

/// 预算执行单项（预算 + 当前区间内实际支出）。
class _BudgetExec {
  const _BudgetExec({required this.budget, required this.spent});

  final Budget budget;
  final int spent;
}

class _BudgetSection extends ConsumerStatefulWidget {
  const _BudgetSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends ConsumerState<_BudgetSection> {
  late Future<List<_BudgetExec>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _BudgetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
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
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const <_BudgetExec>[];
        if (items.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('本时段暂无预算')),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
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
            ),
          ],
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

// ---------------------------------------------------------------------------
// 标签分区
// ---------------------------------------------------------------------------

class _TagSection extends ConsumerStatefulWidget {
  const _TagSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

  @override
  ConsumerState<_TagSection> createState() => _TagSectionState();
}

class _TagData {
  const _TagData({required this.sum, required this.tags});

  final List<({String tagId, int amount})> sum;
  final List<Tag> tags;
}

class _TagSectionState extends ConsumerState<_TagSection> {
  late Future<_TagData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _TagSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  Future<_TagData> _load() async {
    final sum = await ref
        .read(billRepoProvider)
        .sumByTagInRange(widget.start, widget.end, BillType.expense);
    final tags = await ref.read(tagRepoProvider).getAll();
    return _TagData(sum: sum, tags: tags);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TagData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final d = snap.data!;
        if (d.sum.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('本时段暂无标签支出')),
            ),
          );
        }
        final total = d.sum.fold<int>(0, (s, e) => s + e.amount);
        final sorted = [...d.sum]..sort((a, b) => b.amount.compareTo(a.amount));
        final maxAmount = sorted.first.amount;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标签支出 Top',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < sorted.length; i++)
                      _TagBar(
                        color: _piePalette[i % _piePalette.length],
                        name: _tagName(d.tags, sorted[i].tagId),
                        amount: sorted[i].amount,
                        total: total,
                        ratio: maxAmount > 0 ? sorted[i].amount / maxAmount : 0,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _tagName(List<Tag> tags, String id) {
    for (final t in tags) {
      if (t.id == id) return t.name;
    }
    return '未知标签';
  }
}

/// 横向条形图行：名称 + 占比条形 + 金额。
class _TagBar extends StatelessWidget {
  const _TagBar({
    required this.color,
    required this.name,
    required this.amount,
    required this.total,
    required this.ratio,
  });

  final Color color;
  final String name;
  final int amount;
  final int total;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${formatYuan(amount)}'
            '（${total > 0 ? (amount / total * 100).toStringAsFixed(0) : 0}%）',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
