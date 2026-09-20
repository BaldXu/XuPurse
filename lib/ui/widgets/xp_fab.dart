import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// 统一 FAB:按下微缩放(micro 170ms),尊重系统 reduce-motion。
/// 外观(shape/icon 尺寸/extended)与 FloatingActionButton 默认一致;
/// [label] 非空时渲染 FloatingActionButton.extended。
class XpFab extends StatefulWidget {
  const XpFab({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.tooltip,
    this.heroTag,
  }) : assert(icon != null || label != null, 'icon 与 label 至少提供一个');

  final VoidCallback? onPressed;

  /// 图标(icon-only FAB 时必传,label 传 null)。
  final Widget? icon;

  /// 标签(非空 = FloatingActionButton.extended)。
  final Widget? label;

  final String? tooltip;
  final Object? heroTag;

  @override
  State<XpFab> createState() => _XpFabState();
}

class _XpFabState extends State<XpFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget fab;
    if (widget.label != null) {
      fab = FloatingActionButton.extended(
        heroTag: widget.heroTag,
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        icon: widget.icon,
        label: widget.label!,
      );
    } else {
      fab = FloatingActionButton(
        heroTag: widget.heroTag,
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        child: widget.icon,
      );
    }

    if (reduceMotion) return fab;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: XpMotion.micro,
        curve: XpMotion.easeOut,
        child: fab,
      ),
    );
  }
}
