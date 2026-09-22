import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../tokens/design_tokens.dart';

/// 统一卡片壳:圆角/样式/背景全部来自主题(AppTheme.cardStyle/cardRadius),
/// 页面不得再自绘 Container+BoxDecoration 或覆盖 Card 的 shape/margin。
///
/// margin 恒为 EdgeInsets.zero,外层间距由调用方 Padding 控制。
///
/// 按压微交互(onTap 非空时):按下缩放 0.98 + 阴影减弱,松手回弹,
/// 时长 XpMotion.micro 170ms easeOut;animationsEnabled=false 或系统
/// reduce-motion 时退化为纯 InkWell(无缩放)。
class XpCard extends StatefulWidget {
  const XpCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.onLongPress,
    this.clipBehavior,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 裁剪行为（如分组卡内嵌多行 ListTile 时传 [Clip.antiAlias],
  /// 让 ripple/按压态被圆角裁剪）。
  final Clip? clipBehavior;

  /// 卡片磨砂参数：真实高斯模糊 σ10 · 白 0.55（比弹窗磨砂更透）。
  /// FAB 磨砂（XpFab）共享同一参数，保证「卡片化」表面视觉一致。
  static const double frostSigma = 10;
  static const double frostAlpha = 0.55;

  @override
  State<XpCard> createState() => _XpCardState();
}

class _XpCardState extends State<XpCard> {
  bool _pressed = false;

  void _onHighlightChanged(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final cardStyle = Theme.of(context).cardTheme;
    final hasTap = widget.onTap != null;
    final baseElev = cardStyle.elevation ?? 0;
    final animOn =
        hasTap &&
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(currentThemeProvider).animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    // 卡片磨砂开启时：表面由下方真实模糊层（σ10 + 白 0.55）提供，
    // 内部 Card 置透明避免双层白。
    final cardsOn = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(frostedGlassProvider).cardsOn;

    final Widget padded = Padding(
      padding: widget.padding ?? const EdgeInsets.all(XpSpacing.l),
      child: widget.child,
    );

    // 按压动画只作用于模糊层之上的内容层：磨砂表面固定不动，
    // BackdropFilter 采样区不随按压缩放 → 按压期间零模糊重算。
    Widget card;
    if (!hasTap || !animOn) {
      card = Card(
        elevation: baseElev,
        shape: cardStyle.shape,
        margin: EdgeInsets.zero,
        clipBehavior: widget.clipBehavior,
        color: cardsOn ? Colors.transparent : null,
        child: padded,
      );
      if (hasTap) {
        card = InkWell(
          borderRadius: _borderRadiusOf(cardStyle.shape),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: card,
        );
      }
    } else {
      card = AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: XpMotion.micro,
        curve: XpMotion.easeOut,
        child: TweenAnimationBuilder<double>(
          duration: XpMotion.micro,
          curve: XpMotion.easeOut,
          tween: Tween<double>(
            end: _pressed ? math.max(0.0, baseElev - 1) : baseElev,
          ),
          builder: (context, elevation, child) => InkWell(
            borderRadius: _borderRadiusOf(cardStyle.shape),
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: _onHighlightChanged,
            child: Card(
              elevation: elevation,
              shape: cardStyle.shape,
              margin: EdgeInsets.zero,
              clipBehavior: widget.clipBehavior,
              color: cardsOn ? Colors.transparent : null,
              child: child,
            ),
          ),
          child: padded,
        ),
      );
    }

    if (cardsOn) {
      // 磨砂表面在最外层（固定不动），内容层缩放在其内；
      // RepaintBoundary 让每卡模糊+内容成独立图层，按压/ripple
      // 重绘不波及其他卡片。grouped + src 对齐栏级磨砂：
      // 一级页有 BackdropGroup 祖先时栏/卡共享一次引擎模糊，
      // src 防御父级 saveLayer（如 Opacity）下的混合异常。
      card = RepaintBoundary(
        child: _frostCard(
          card,
          cardStyle.shape ?? const RoundedRectangleBorder(),
        ),
      );
    }
    return card;
  }

  /// 卡片磨砂表面：G2 形状裁剪内做真实高斯模糊 + 半透明白（σ10 · α0.55）。
  Widget _frostCard(Widget card, ShapeBorder shape) {
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter.grouped(
        filter: ImageFilter.blur(
          sigmaX: XpCard.frostSigma,
          sigmaY: XpCard.frostSigma,
        ),
        blendMode: BlendMode.src,
        child: ColoredBox(
          color: Colors.white.withValues(alpha: XpCard.frostAlpha),
          child: card,
        ),
      ),
    );
  }

  static BorderRadius? _borderRadiusOf(ShapeBorder? shape) {
    final BorderRadiusGeometry? geometry = switch (shape) {
      RoundedRectangleBorder s => s.borderRadius,
      RoundedSuperellipseBorder s => s.borderRadius,
      _ => null,
    };
    if (geometry is BorderRadius) return geometry;
    if (geometry != null) {
      try {
        return geometry.resolve(TextDirection.ltr);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
