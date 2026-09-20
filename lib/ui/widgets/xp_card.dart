import 'dart:math' as math;

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

    final Widget padded = Padding(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: widget.child,
    );

    if (!hasTap || !animOn) {
      Widget card = Card(
        elevation: baseElev,
        shape: cardStyle.shape,
        margin: EdgeInsets.zero,
        clipBehavior: widget.clipBehavior,
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
      return card;
    }

    return AnimatedScale(
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
            child: child,
          ),
        ),
        child: padded,
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
