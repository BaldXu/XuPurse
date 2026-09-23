import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// 滑块式单选栏（Sliding Segmented Control / Pill Selector）。
///
/// 选中项是一块在轨道上平滑滑动的胶囊高亮（AnimatedAlign 驱动），
/// 点击选项或横向拖动滑块均可切换，松手后吸附到最近的选项。
/// 轨道 surfaceContainerHighest、滑块 surface+轻投影，全部走主题与设计 token。
class XpSlidingSegmented<T> extends StatefulWidget {
  const XpSlidingSegmented({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.height = 36,
  });

  /// 选项列表（泛型值 + 展示标签），顺序即排列顺序。
  final List<XpSegmentedItem<T>> items;

  /// 当前选中值。
  final T selected;

  /// 切换回调（仅值变化时触发）。
  final ValueChanged<T> onChanged;

  /// 控件总高度（含内边距），默认 36。
  final double height;

  @override
  State<XpSlidingSegmented<T>> createState() => _XpSlidingSegmentedState<T>();
}

/// 单个选项：泛型值 + 展示标签（可选前置图标）。
class XpSegmentedItem<T> {
  const XpSegmentedItem({required this.value, required this.label, this.icon});

  final T value;
  final String label;

  /// 可选前置图标（如记账弹窗的类型 tab），选中态跟随文字着色。
  final IconData? icon;
}

class _XpSlidingSegmentedState<T> extends State<XpSlidingSegmented<T>> {
  static const double _inset = 4;

  /// 内容区宽度（LayoutBuilder 提供，拖拽换算用）。
  double? _contentWidth;

  /// 是否正在横向拖拽。
  bool _dragging = false;

  /// 本次拖拽是否真正移动过（区分「点击」与「滑动」）。
  bool _dragged = false;

  /// 拖拽中拇指中心在内容区宽度上的 0~1 位置。
  double? _dragCenter;

  int get _selectedIndex =>
      widget.items.indexWhere((item) => item.value == widget.selected);

  /// 非拖拽时的目标中心（选中项中心，0~1）。
  double get _targetCenter => (_selectedIndex + 0.5) / widget.items.length;

  /// 中心位置(0~1) → Alignment.x。
  /// 拇指宽 = 内容宽/n，n 个等宽分段时精确对齐公式：x = n(2c-1)/(n-1)。
  Alignment _alignmentFor(double center) {
    final n = widget.items.length;
    if (n <= 1) return Alignment.center;
    final x = n * (2 * center - 1) / (n - 1);
    return Alignment(x.clamp(-1.0, 1.0), 0);
  }

  @override
  void didUpdateWidget(XpSlidingSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部（如重置筛选）改了选中值时，取消未完成的拖拽态
    if (widget.selected != oldWidget.selected) {
      _dragging = false;
      _dragged = false;
      _dragCenter = null;
    }
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _dragging = true;
      _dragged = false;
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final w = _contentWidth;
    if (w == null || w <= 0) return;
    setState(() {
      _dragged = true;
      _dragCenter = (details.localPosition.dx / w).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final n = widget.items.length;
    final w = _contentWidth;
    int? target;
    if (_dragged && w != null) {
      target = ((_dragCenter ?? _targetCenter) * n).floor().clamp(0, n - 1);
    }
    setState(() {
      _dragging = false;
      _dragged = false;
      _dragCenter = null;
    });
    if (target != null && target != _selectedIndex) {
      widget.onChanged(widget.items[target].value);
    }
  }

  void _onDragCancel() {
    setState(() {
      _dragging = false;
      _dragged = false;
      _dragCenter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final n = widget.items.length;
    final selectedIndex = _selectedIndex;
    final center = _dragCenter ?? _targetCenter;

    return MouseRegion(
      // web/桌面端：悬停显示手型光标，提示可点击/可拖动
      cursor: SystemMouseCursors.click,
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.all(_inset),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(XpRadius.pill),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            _contentWidth = constraints.maxWidth;
            final segWidth = constraints.maxWidth / n;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onHorizontalDragCancel: _onDragCancel,
              child: Stack(
                children: [
                  // 滑动胶囊：拖拽中 0 时长跟随手指，松手后 XpMotion.component 吸附
                  AnimatedAlign(
                    alignment: _alignmentFor(center),
                    duration: _dragging ? Duration.zero : XpMotion.component,
                    curve: _dragging ? Curves.linear : XpMotion.easeOut,
                    child: Container(
                      width: segWidth,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(XpRadius.pill),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 选项层（文字在胶囊之上，点击/拖拽命中）
                  Row(
                    children: [
                      for (var i = 0; i < n; i++)
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (i != selectedIndex) {
                                widget.onChanged(widget.items[i].value);
                              }
                            },
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: XpMotion.micro,
                                curve: XpMotion.easeOut,
                                style:
                                    (textTheme.labelMedium ??
                                            const TextStyle(fontSize: 12))
                                        .copyWith(
                                          color: i == selectedIndex
                                              ? scheme.onSurface
                                              : scheme.onSurfaceVariant,
                                          fontWeight: i == selectedIndex
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                child: _ItemContent(item: widget.items[i]),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 选项内容：可选前置图标 + 标签；图标颜色跟随 [AnimatedDefaultTextStyle]。
class _ItemContent<T> extends StatelessWidget {
  const _ItemContent({required this.item});

  final XpSegmentedItem<T> item;

  @override
  Widget build(BuildContext context) {
    final icon = item.icon;
    final label = Text(item.label);
    if (icon == null) return label;
    // 取 AnimatedDefaultTextStyle 当前插值色，让图标与文字同步渐变
    final color = DefaultTextStyle.of(context).style.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: XpSpacing.xs),
        label,
      ],
    );
  }
}
