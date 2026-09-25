import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// 按钮变体。
enum XpButtonVariant {
  /// 普通操作：卡片色实底——浅色模式下为卡片白底 + 主文字色；
  /// 暗色模式下为近黑底 + 白字。解决此前透明底按钮
  /// （OutlinedButton/TextButton）直接露出页面底色、观感单薄的问题。
  card,

  /// 危险操作：固定「红底白字」（删除、清空、覆盖恢复等不可恢复操作）。
  danger,
}

/// 统一按钮组件（普通/危险两类操作的唯一入口）。
///
/// - 普通按钮（[XpButtonVariant.card]，默认）使用「卡片色」实底：
///   浅色 = 卡片白底 + 主文字；暗色 = 不透明近黑底 + 白字，替代透明底按钮。
/// - 危险按钮（[XpButtonVariant.danger]）固定红底白字，警示样式全站唯一。
/// - 圆角走 Control 档（[XpRadius.c]=12），与输入框等控件对齐；
///   需要卡片级大圆角（m20）时传 [borderRadius]。
class XpButton extends StatelessWidget {
  const XpButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = XpButtonVariant.card,
    this.icon,
    this.leading,
    this.expand = false,
    this.height = 40,
    this.borderRadius = XpRadius.c,
    this.textStyle,
  });

  /// 点击回调；null = 禁用。
  final VoidCallback? onPressed;

  /// 按钮文案。
  final Widget child;

  /// 按钮变体：卡片色（默认）/ 危险红。
  final XpButtonVariant variant;

  /// 前导图标（Material 图标，走 FilledButton.icon 布局）。
  final IconData? icon;

  /// 自定义前导 widget（如 [AppIcon] / 加载指示器），优先于 [icon]。
  final Widget? leading;

  /// 是否占满可用宽度（底部操作栏、表单主按钮等）。
  final bool expand;

  /// 按钮高度（默认 40，与 Material 按钮一致）。
  final double height;

  /// 圆角（默认 [XpRadius.c]）。
  final double borderRadius;

  /// 覆盖文字样式。
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // 卡片色底必须不透明：暗色模式 / 主题未显式设卡色（此时卡色为半透
    // 明白）都回退到不透明表面色，避免按钮再次透出页面底色。
    final cardColor = Theme.of(context).cardTheme.color;
    final Color bg = switch (variant) {
      XpButtonVariant.card =>
        dark || cardColor == null || cardColor.a < 1.0
            ? scheme.surface
            : cardColor,
      XpButtonVariant.danger => XpSemanticColors.danger,
    };
    final Color fg = switch (variant) {
      XpButtonVariant.card => scheme.onSurface,
      XpButtonVariant.danger => Colors.white,
    };
    final style = FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: 0.38),
      disabledForegroundColor: fg.withValues(alpha: 0.38),
      shape: XpShape.smooth(borderRadius: BorderRadius.circular(borderRadius)),
      minimumSize: Size(expand ? double.infinity : 0, height),
      textStyle: textStyle,
    );

    if (leading != null) {
      return FilledButton(
        style: style,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading!,
            const SizedBox(width: XpSpacing.s),
            child,
          ],
        ),
      );
    }
    if (icon != null) {
      return FilledButton.icon(
        style: style,
        onPressed: onPressed,
        icon: Icon(icon),
        label: child,
      );
    }
    return FilledButton(style: style, onPressed: onPressed, child: child);
  }
}
