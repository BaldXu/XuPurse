import 'package:flutter/material.dart';

/// 统一卡片壳:圆角/样式/背景全部来自主题(AppTheme.cardStyle/cardRadius),
/// 页面不得再自绘 Container+BoxDecoration 或覆盖 Card 的 shape/margin。
///
/// margin 恒为 EdgeInsets.zero,外层间距由调用方 Padding 控制。
class XpCard extends StatelessWidget {
  const XpCard({super.key, required this.child, this.padding, this.onTap});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cardStyle = Theme.of(context).cardTheme;
    Widget card = Card(
      elevation: cardStyle.elevation,
      shape: cardStyle.shape,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
    if (onTap != null) {
      card = InkWell(borderRadius: _borderRadiusOf(cardStyle.shape), onTap: onTap, child: card);
    }
    return card;
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
