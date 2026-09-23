import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../tokens/design_tokens.dart';
import 'xp_card.dart';

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
    // 卡片化按钮：背景跟随卡片主题（磨砂/卡片颜色选择），图标用主题色。
    // 与「由卡片包裹」的要求一致——FAB 与卡片共享同一套表面。
    final scheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color;
    // 卡片磨砂开启时：表面由下方真实模糊层提供（参数与 XpCard 卡片磨砂
    // 完全一致，保证 FAB 与卡片视觉统一），FAB 背景置透明避免双层白。
    final cardsOn = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(frostedGlassProvider).cardsOn;

    // 磨砂时显式确定 shape 供 ClipPath 裁剪（与 FAB M3 默认外观一致）。
    final ShapeBorder shape = widget.label != null
        ? const StadiumBorder()
        : Theme.of(context).floatingActionButtonTheme.shape ??
              const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              );

    Widget fab;
    if (widget.label != null) {
      fab = FloatingActionButton.extended(
        heroTag: widget.heroTag,
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        backgroundColor: cardsOn ? Colors.transparent : cardColor,
        foregroundColor: scheme.primary,
        elevation: cardsOn ? 0 : null,
        icon: widget.icon,
        label: widget.label!,
      );
    } else {
      fab = FloatingActionButton(
        heroTag: widget.heroTag,
        tooltip: widget.tooltip,
        onPressed: widget.onPressed,
        backgroundColor: cardsOn ? Colors.transparent : cardColor,
        foregroundColor: scheme.primary,
        elevation: cardsOn ? 0 : null,
        shape: cardsOn ? shape : null,
        child: widget.icon,
      );
    }

    // 按压缩放只作用于模糊层之上的内容层：磨砂表面固定不动，
    // BackdropFilter 采样区不随按压缩放 → 按压期间零模糊重算。
    if (!reduceMotion) {
      fab = Listener(
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

    if (cardsOn) {
      // 结构/参数对齐 XpCard._frostCard：普通 BackdropFilter + src、
      // RepaintBoundary（grouped 共享快照的闪灰黑问题见 xp_card.dart 注释）。
      fab = RepaintBoundary(child: _frostFab(fab, shape));
    }
    return fab;
  }

  /// 磨砂表面：形状裁剪内做真实高斯模糊 + 半透明白（参数同 XpCard）。
  Widget _frostFab(Widget fab, ShapeBorder shape) {
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: XpCard.frostSigma,
          sigmaY: XpCard.frostSigma,
        ),
        blendMode: BlendMode.src,
        child: ColoredBox(
          color: Colors.white.withValues(alpha: XpCard.frostAlpha),
          child: fab,
        ),
      ),
    );
  }
}
