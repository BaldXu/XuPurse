import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../layout/breakpoints.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import 'statistics/stats_budget_section.dart';
import 'statistics/stats_category_section.dart';
import 'statistics/stats_overview_section.dart';
import 'statistics/stats_shared.dart';
import 'statistics/stats_tag_section.dart';
import 'statistics/stats_trend_section.dart';

export 'statistics/stats_shared.dart' show statsDataVersionProvider;

/// 统计页：顶部 TabBar 分区（点击 Tab 或左右滑动切换）+ 日期范围下拉。
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

/// 分区（顺序即 TabBar 顺序）。
enum _Section {
  overview('总览'),
  category('分类'),
  trend('趋势'),
  budget('预算'),
  tag('标签');

  const _Section(this.label);

  final String label;
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with XpPageScaffold, SingleTickerProviderStateMixin {
  // 分区内容自身已有 ContentWidthBox(960) 兜底居中；壳层不再限宽，
  // 避免顶部 TabBar 被 720 限宽推到屏幕中间。
  @override
  double get xpMaxWidth => double.infinity;

  /// 分区 Tab 控制器（点击 Tab 与左右滑动切换共用同一实例）。
  late final TabController _tabController;

  StatsRangePreset _preset = StatsRangePreset.thisMonth;
  DateTimeRange? _customRange;

  /// 最早账单时间（日历自定义范围的下界）；无账单时为 null。
  DateTime? _earliest;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _Section.values.length, vsync: this);
    _loadEarliest();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  // 数据已就绪的分区集合（key 同分区 ValueKey 规则）。
  // 未就绪的分区以不可见(Offstage)方式挂载并触发数据查询，数据加载完成
  // （onReady 回调）后才翻转为可见，避免切换瞬间把分区首帧构建/数据加载
  // 暴露在可见帧上导致闪屏；初始分区也走同一机制。
  final Set<String> _readySections = {};

  String _sectionKey(_Section s, ({int start, int end}) range) =>
      '${s.name}-${range.start}-${range.end}';

  void _markSectionReady(_Section s, ({int start, int end}) range) {
    if (!mounted) return;
    final k = _sectionKey(s, range);
    if (_readySections.contains(k)) return;
    setState(() => _readySections.add(k));
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
    // 首次挂载（切 tab 进来）只渲染骨架：整页树（AppBar 下拉 + 分区）
    // 首帧全量构建会与导航栏指示器动画抢帧；首帧渲染完成后自动重建
    // 真实内容（xpFirstSettled 首帧门，仅首个未挂载帧生效）。
    if (!xpFirstSettled) {
      return buildXpScaffold(
        appBar: AppBar(title: const Text('统计')),
        body: const XpSkeletonPage(),
      );
    }
    final range = _range;
    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('统计'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
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
                padding: const EdgeInsets.only(top: XpSpacing.xs),
                child: Text(
                  _rangeDetail,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: XpSpacing.s),
              // 分区 TabBar：点击切页；与下方 TabBarView 共用 controller，
              // 左右滑动 TabBarView 时指示器也会同步。
              TabBar(
                controller: _tabController,
                tabs: [for (final s in _Section.values) Tab(text: s.label)],
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 顶部 10dp 空白：内容整体下移，与 AppBar 拉开一点距离。
          Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final s in _Section.values) _buildPage(s, range),
                  ],
                ),
              ),
            ],
          ),
          // AI 悬浮按钮：默认右侧 30% 高度、可上下拖动，
          // 每次进入统计页重置位置（见 MainShell 切 tab 处理）。
          const AiDraggableFab(),
        ],
      ),
    );
  }

  /// 单个分区页；用 ValueKey 保证切换范围后重新加载。
  /// 未就绪的分区：可见层只显示骨架，分区以不可见(Offstage)方式挂载并触发
  /// 数据查询，onReady 数据就绪后翻转 offstage 让分区可见（同 key 保活，
  /// 直接渲染完整内容，避免首帧构建/数据加载暴露在可见帧上的闪屏）。
  Widget _buildPage(_Section s, ({int start, int end}) range) {
    final key = ValueKey('${s.name}-${range.start}-${range.end}');
    final ready = _readySections.contains(_sectionKey(s, range));
    final section = _sectionWidget(
      s,
      range,
      key: key,
      onReady: () => _markSectionReady(s, range),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!ready) const XpSkeletonList(key: ValueKey('stats-tab-pending')),
        Offstage(offstage: !ready, child: section),
      ],
    );
  }

  /// 按当前分区构造内容组件（宽屏限宽居中）。
  Widget _sectionWidget(
    _Section s,
    ({int start, int end}) range, {
    required Key key,
    VoidCallback? onReady,
  }) {
    Widget section = switch (s) {
      _Section.overview => StatsOverviewSection(
        key: key,
        start: range.start,
        end: range.end,
        onReady: onReady,
      ),
      _Section.category => StatsCategorySection(
        key: key,
        start: range.start,
        end: range.end,
        onReady: onReady,
      ),
      _Section.trend => StatsTrendSection(
        key: key,
        start: range.start,
        end: range.end,
        onReady: onReady,
      ),
      _Section.budget => StatsBudgetSection(
        key: key,
        start: range.start,
        end: range.end,
        onReady: onReady,
      ),
      _Section.tag => StatsTagSection(
        key: key,
        start: range.start,
        end: range.end,
        onReady: onReady,
      ),
    };
    // 宽屏限宽居中，避免卡片/图表在桌面大屏上无限拉伸。
    return ContentWidthBox(maxWidth: 960, child: section);
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
                  const SizedBox(width: XpSpacing.s),
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
              const SizedBox(width: XpSpacing.s),
              Text(StatsRangePreset.custom.label),
            ],
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
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
            const SizedBox(width: XpSpacing.xs),
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
