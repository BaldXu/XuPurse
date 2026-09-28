import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'xp_button.dart';
import 'xp_sliding_segmented.dart';

/// 日期范围选择模式。
enum _XpRangeMode {
  /// 按月选范围（某月 → 某月），粒度到月。
  month,

  /// 按日选范围（某天 → 某天），粒度到日。
  day,
}

/// 自研日期范围选择弹窗内容（居中弹窗形态，中文界面）。
///
/// 双模式，共用同一份选择状态：
/// - **按日**：完整月历，满足「某一天到某一天」的精度需求；默认模式。
/// - **按月**：年份导航 + 12 月网格，快速选「去年 5 月 → 今年 5 月」这类范围。
///
/// 按月只落一个「当月 1 日 → 当月末日」的范围，切到按日即可继续微调，
/// 反之亦然（两种粒度之间无缝切换）。
///
/// 返回值语义与 Flutter 自带 `DateRangePickerDialog` 一致：
/// [DateTimeRange.start] 为起始日 00:00，[DateTimeRange.end] 为结束日 00:00
/// （是否 +1 天由调用方自行决定）。
class XpDateRangePicker extends StatefulWidget {
  const XpDateRangePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialDateRange,
    this.helpText,
    this.saveText,
  });

  /// 可选范围下界（含）。
  final DateTime firstDate;

  /// 可选范围上界（含）。
  final DateTime lastDate;

  /// 初始已选范围（同名参数语义同自带选择器）。
  final DateTimeRange? initialDateRange;

  /// 标题文案。
  final String? helpText;

  /// 确认按钮文案（默认「确定」）。
  final String? saveText;

  @override
  State<XpDateRangePicker> createState() => _XpDateRangePickerState();
}

class _XpDateRangePickerState extends State<XpDateRangePicker> {
  /// 月份标签（1 月 ~ 12 月）。
  static const List<String> _monthLabels = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月',
  ];

  /// 星期表头（周日起）。
  static const List<String> _weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];

  /// 按日格子高度。
  static const double _cellHeight = 40;

  _XpRangeMode _mode = _XpRangeMode.day;

  /// 按日模式下「快速跳月」面板是否展开（点标题切换）。
  bool _jumpPanel = false;

  /// 当前显示月份（当月 1 号）。按月模式取年份，按日模式渲染该月月历。
  late DateTime _cursor;

  /// 已选范围（均为当日 00:00）。[_end] 为空 = 只定了起点、等待终点。
  DateTime? _start;
  DateTime? _end;

  late final DateTime _min = _dateOnly(widget.firstDate);
  late final DateTime _max = _dateOnly(widget.lastDate);

  @override
  void initState() {
    super.initState();
    final anchor = widget.initialDateRange?.start ?? widget.lastDate;
    _cursor = DateTime(anchor.year, anchor.month, 1);
    final r = widget.initialDateRange;
    if (r != null) {
      _start = _dateOnly(r.start);
      _end = _dateOnly(r.end);
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  bool get _hasFullRange => _start != null && _end != null;

  /// 选中范围的生效终点（未定终点时视作与起点同格，便于高亮单格）。
  DateTime? get _effEnd => _end ?? _start;

  /// 日期是否落在 [firstDate, lastDate] 内。
  bool _dayEnabled(DateTime d) => !d.isBefore(_min) && !d.isAfter(_max);

  /// 月份是否与 [firstDate, lastDate] 有交集。
  bool _monthEnabled(DateTime firstDay, DateTime lastDay) =>
      !lastDay.isBefore(_min) && !firstDay.isAfter(_max);

  /// 日期是否落在当前已选范围内。
  bool _inRange(DateTime day) {
    final s = _start;
    if (s == null) return false;
    final e = _effEnd!;
    return !day.isBefore(s) && !day.isAfter(e);
  }

  /// 月份是否与当前已选范围有交集。
  bool _monthInRange(DateTime firstDay, DateTime lastDay) {
    final s = _start;
    if (s == null) return false;
    final e = _effEnd!;
    return !lastDay.isBefore(s) && !firstDay.isAfter(e);
  }

  /// 处理一次范围格的点选（cellStart / cellEnd 均为当日 00:00）。
  ///
  /// 交互：无选择 → 定起点；已定起点 → 补终点（早于起点则交换）；
  /// 已有完整范围 → 从新起点重新开始选。
  void _onCellTap(DateTime cellStart, DateTime cellEnd) {
    setState(() {
      final s = _start;
      if (_hasFullRange || s == null) {
        _start = cellStart;
        _end = null;
      } else if (cellEnd.isBefore(s)) {
        _end = s;
        _start = cellStart;
      } else {
        _end = cellEnd;
      }
    });
  }

  bool get _canPrevYear => _cursor.year > widget.firstDate.year;

  bool get _canNextYear => _cursor.year < widget.lastDate.year;

  bool get _canPrevMonth => DateTime(
    _cursor.year,
    _cursor.month,
    1,
  ).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month, 1));

  bool get _canNextMonth => DateTime(
    _cursor.year,
    _cursor.month,
    1,
  ).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month, 1));

  void _shiftYear(int delta) {
    final y = _cursor.year + delta;
    if (y < widget.firstDate.year || y > widget.lastDate.year) return;
    setState(() => _cursor = DateTime(y, _cursor.month, 1));
  }

  void _shiftMonth(int delta) {
    if (delta > 0 && !_canNextMonth) return;
    if (delta < 0 && !_canPrevMonth) return;
    setState(() => _cursor = DateTime(_cursor.year, _cursor.month + delta, 1));
  }

  void _confirm() {
    if (!_hasFullRange) return;
    Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end!));
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(XpSpacing.xl),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(
                XpSpacing.l,
                XpSpacing.l,
                XpSpacing.l,
                XpSpacing.m,
              ),
              child: Text(
                widget.helpText ?? '选择日期范围',
                style: textTheme.titleMedium,
              ),
            ),
            // 粒度切换：按月 / 按日
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
              child: XpSlidingSegmented<_XpRangeMode>(
                items: const [
                  XpSegmentedItem(value: _XpRangeMode.month, label: '按月'),
                  XpSegmentedItem(value: _XpRangeMode.day, label: '按日'),
                ],
                selected: _mode,
                onChanged: (v) => setState(() {
                  _mode = v;
                  _jumpPanel = false;
                }),
                height: 34,
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            // 导航条 + 选择区（AnimatedSize 让两种粒度的高度切换平滑）
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNav(textTheme),
                  const SizedBox(height: XpSpacing.xs),
                  AnimatedSize(
                    duration: XpMotion.component,
                    curve: XpMotion.easeOut,
                    alignment: Alignment.topCenter,
                    child: _buildBody(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            _buildSummary(textTheme),
            const SizedBox(height: XpSpacing.m),
            _buildActions(),
            const SizedBox(height: XpSpacing.l),
          ],
        ),
      ),
    );
  }

  /// 顶部导航条：左右箭头 + 中间标题（按日标题可点开快速跳月面板）。
  Widget _buildNav(TextTheme textTheme) {
    final bool yearNav = _mode == _XpRangeMode.month || _jumpPanel;
    final String label = yearNav
        ? '${_cursor.year}年'
        : '${_cursor.year}年${_cursor.month}月';
    final VoidCallback? prev = yearNav
        ? (_canPrevYear ? () => _shiftYear(-1) : null)
        : (_canPrevMonth ? () => _shiftMonth(-1) : null);
    final VoidCallback? next = yearNav
        ? (_canNextYear ? () => _shiftYear(1) : null)
        : (_canNextMonth ? () => _shiftMonth(1) : null);

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          _navButton(Icons.chevron_left, prev),
          Expanded(
            child: InkWell(
              onTap: _mode == _XpRangeMode.month
                  ? null
                  : () => setState(() => _jumpPanel = !_jumpPanel),
              borderRadius: BorderRadius.circular(XpRadius.c),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: textTheme.titleSmall),
                    if (_mode == _XpRangeMode.day)
                      Icon(
                        _jumpPanel ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      ),
                  ],
                ),
              ),
            ),
          ),
          _navButton(Icons.chevron_right, next),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback? onTap) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      color: onTap == null ? scheme.onSurfaceVariant.withValues(alpha: 0.3) : null,
    );
  }

  Widget _buildBody() {
    if (_mode == _XpRangeMode.month) return _buildMonthGrid(rangeMode: true);
    return _jumpPanel ? _buildMonthGrid(rangeMode: false) : _buildDayGrid();
  }

  /// 12 月网格。
  ///
  /// [rangeMode] = true 时为「按月选范围」（选中态跟随已选范围）；
  /// false 时为「按日模式的快速跳月」（点选某月即定位过去，不改选范围）。
  Widget _buildMonthGrid({required bool rangeMode}) {
    final year = _cursor.year;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: XpSpacing.s),
          Row(
            children: [
              for (var col = 0; col < 4; col++) ...[
                if (col > 0) const SizedBox(width: XpSpacing.s),
                Expanded(
                  child: _buildMonthCell(
                    year: year,
                    month: row * 4 + col + 1,
                    rangeMode: rangeMode,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMonthCell({
    required int year,
    required int month,
    required bool rangeMode,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final enabled = _monthEnabled(firstDay, lastDay);

    final bool selected;
    final bool edge;
    if (rangeMode) {
      selected = _monthInRange(firstDay, lastDay);
      edge =
          selected &&
          ((_start != null && _sameMonth(firstDay, _start!)) ||
              (_end != null && _sameMonth(firstDay, _end!)));
    } else {
      selected = _sameMonth(firstDay, _cursor);
      edge = selected;
    }

    final Color? bg = selected
        ? (edge ? scheme.primary : XpBrandColors.primarySoft)
        : null;
    final Color fg = selected
        ? (edge ? scheme.onPrimary : scheme.primary)
        : (enabled ? scheme.onSurface : scheme.onSurfaceVariant.withValues(alpha: 0.35));

    return SizedBox(
      height: 44,
      child: Material(
        color: bg ?? Colors.transparent,
        borderRadius: BorderRadius.circular(XpRadius.c),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  if (rangeMode) {
                    _onCellTap(firstDay, lastDay);
                  } else {
                    setState(() {
                      _cursor = firstDay;
                      _jumpPanel = false;
                    });
                  }
                }
              : null,
          child: Center(
            child: Text(
              _monthLabels[month - 1],
              style: TextStyle(
                fontSize: 14,
                fontWeight: edge ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 月历（6 行 × 7 列，固定高度避免切月时抖动）。
  Widget _buildDayGrid() {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final firstOfMonth = DateTime(_cursor.year, _cursor.month, 1);
    final lead = firstOfMonth.weekday % 7; // 周日 = 0

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final w in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: XpSpacing.xs),
        for (var row = 0; row < 6; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildDayCell(
                    DateTime(
                      firstOfMonth.year,
                      firstOfMonth.month,
                      firstOfMonth.day - lead + row * 7 + col,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day) {
    final scheme = Theme.of(context).colorScheme;
    final inMonth = day.month == _cursor.month;
    final enabled = _dayEnabled(day);

    final s = _start;
    final e = _effEnd;
    final isStart = s != null && day == s;
    final isEnd = e != null && day == e;
    final filled = isStart || isEnd;
    // 单日选择（起点即终点）只画圆点；跨多日时才铺出连续底带。
    final banded = _inRange(day) && !(isStart && isEnd);

    final Color fg;
    if (filled) {
      fg = scheme.onPrimary;
    } else if (!enabled) {
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.3);
    } else if (!inMonth) {
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.5);
    } else {
      fg = scheme.onSurface;
    }

    return SizedBox(
      height: _cellHeight,
      child: ColoredBox(
        color: banded ? XpBrandColors.primarySoft : Colors.transparent,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _onCellTap(day, day) : null,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: filled
                  ? BoxDecoration(color: scheme.primary, shape: BoxShape.circle)
                  : null,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 实时摘要（未选满两点时提示下一步）。
  Widget _buildSummary(TextTheme textTheme) {
    final scheme = Theme.of(context).colorScheme;
    final s = _start;
    final e = _end;
    final String label;
    if (s == null) {
      label = _mode == _XpRangeMode.month ? '请选择开始月份' : '请选择开始日期';
    } else if (e == null) {
      label = '${_fmt(s)}  →  …';
    } else {
      label = '${_fmt(s)}  →  ${_fmt(e)}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.m,
          vertical: XpSpacing.s,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(XpRadius.s),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: XpSpacing.s),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: e == null ? scheme.onSurfaceVariant : scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
      child: Row(
        children: [
          Expanded(
            child: XpButton(
              onPressed: () => Navigator.of(context).pop(),
              height: 44,
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: XpSpacing.m),
          Expanded(
            child: SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _hasFullRange ? _confirm : null,
                style: FilledButton.styleFrom(
                  shape: XpShape.smooth(
                    borderRadius: BorderRadius.circular(XpRadius.c),
                  ),
                ),
                child: Text(widget.saveText ?? '确定'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
