import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../layout/breakpoints.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_sheet.dart';
import 'statistics/stats_budget_section.dart';
import 'statistics/stats_category_section.dart';
import 'statistics/stats_overview_section.dart';
import 'statistics/stats_shared.dart';
import 'statistics/stats_tag_section.dart';
import 'statistics/stats_trend_section.dart';

export 'statistics/stats_shared.dart' show statsDataVersionProvider;

/// 统计页：侧边栏分区（宽屏 NavigationRail / 窄屏横向 Tab）+ 日期范围下拉。
///
/// 分区：
/// - 总览：收支汇总 KPI + 环比 + 日均
/// - 分类：支出 / 收入分类占比
/// - 趋势：支出趋势（粒度随范围自适应：日 → 周 → 月）
/// - 预算：预算执行进度
/// - 标签：标签支出 Top
///
/// 分区实现与共享基建在 `statistics/` 子目录（stats_shared + 5 个分区文件）。
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

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with XpPageScaffold {
  _Section _section = _Section.overview;
  StatsRangePreset _preset = StatsRangePreset.thisMonth;
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
      case StatsRangePreset.thisMonth:
        return (
          start: DateTime(now.year, now.month).millisecondsSinceEpoch,
          end: DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
        );
      case StatsRangePreset.lastMonth:
        return (
          start: DateTime(now.year, now.month - 1).millisecondsSinceEpoch,
          end: DateTime(now.year, now.month).millisecondsSinceEpoch,
        );
      case StatsRangePreset.thisYear:
        return (
          start: DateTime(now.year).millisecondsSinceEpoch,
          end: DateTime(now.year + 1).millisecondsSinceEpoch,
        );
      case StatsRangePreset.lastYear:
        return (
          start: DateTime(now.year - 1).millisecondsSinceEpoch,
          end: DateTime(now.year).millisecondsSinceEpoch,
        );
      case StatsRangePreset.lastWeek:
        final today = DateTime(now.year, now.month, now.day);
        return (
          start: today.subtract(const Duration(days: 6)).millisecondsSinceEpoch,
          end: today.add(const Duration(days: 1)).millisecondsSinceEpoch,
        );
      case StatsRangePreset.custom:
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
    if (_preset != StatsRangePreset.custom) return _preset.label;
    final r = _customRange;
    if (r == null) return StatsRangePreset.custom.label;
    return '${fmtDate(r.start)} ~ ${fmtDate(r.end)}';
  }

  /// 实际起止日期（用于范围说明小字）。
  String get _rangeDetail {
    final r = _range;
    final s = DateTime.fromMillisecondsSinceEpoch(r.start);
    final e = DateTime.fromMillisecondsSinceEpoch(
      r.end,
    ).subtract(const Duration(milliseconds: 1));
    return '${fmtDate(s)} ~ ${fmtDate(e)}';
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final first = _earliest ?? now.subtract(const Duration(days: 365 * 5));
    final picked = await showXpDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDateRangeStart: _customRange?.start,
      initialDateRangeEnd: _customRange?.end,
      helpText: '选择统计范围',
      saveText: '确定',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _preset = StatsRangePreset.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final range = _range;
    return buildXpScaffold(
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
                  if (p == StatsRangePreset.custom) {
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
                icon: AppIcon(icon: s.icon),
                selectedIcon: AppIcon(icon: s.selectedIcon),
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
      _Section.overview => StatsOverviewSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.category => StatsCategorySection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.trend => StatsTrendSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.budget => StatsBudgetSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
      _Section.tag => StatsTagSection(
        key: key,
        start: range.start,
        end: range.end,
      ),
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
  final StatsRangePreset preset;
  final ValueChanged<StatsRangePreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<StatsRangePreset>(
      onSelected: onPresetSelected,
      tooltip: '选择时间范围',
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final p in StatsRangePreset.values)
          if (p == StatsRangePreset.custom)
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
          value: StatsRangePreset.custom,
          child: Row(
            children: [
              AppIcon(
                icon: Icons.date_range_outlined,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(StatsRangePreset.custom.label),
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
            AppIcon(
              icon: Icons.calendar_month_outlined,
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
