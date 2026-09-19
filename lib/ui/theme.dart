import 'package:flutter/material.dart';

import '../state/theme_provider.dart';
import 'tokens/design_tokens.dart';

/// XuPurse 主题:Material 3,由 [AppTheme] 配置驱动。
///
/// - 颜色:seedColor 生成 ColorScheme;background/cardColor 为浅色覆盖;
///   暗色主题(preset_dark)不使用用户覆盖色,完全由派生色构成。
/// - 字体:fontFamily + fontScale 作用于全局 textTheme。
/// - 卡片:样式(filled/outlined/elevated)+ 圆角由主题统一定制,页面不得绕过。
/// - 动画:pageTransitionsTheme / 弹窗等由 animationsEnabled 控制
///   (系统 reduce-motion 时在 main 层强制关闭)。
ThemeData buildAppTheme(
  Brightness brightness,
  AppTheme theme, {
  bool? animationsEnabled,
}) {
  final dark = brightness == Brightness.dark || theme.isDark;
  final scheme = ColorScheme.fromSeed(
    seedColor: theme.seedColor,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  final animOn = animationsEnabled ?? theme.animationsEnabled;
  // 暗色主题不应用用户的浅色背景/卡色覆盖(暗色 = 独立预设主题,已决策)。
  final background = dark ? null : theme.background;
  final cardColor = dark ? null : theme.cardColor;

  final baseTextTheme = dark
      ? Typography.material2021().white
      : Typography.material2021().black;
  final fontScale = theme.fontScale;
  final textTheme = (theme.fontFamily == null && fontScale == 1.0)
      ? baseTextTheme
      : baseTextTheme.apply(
          fontFamily: theme.fontFamily,
          fontSizeFactor: fontScale,
        );

  final cardRadius = BorderRadius.circular(theme.cardRadius ?? XpRadius.m);
  final cardShape = RoundedRectangleBorder(borderRadius: cardRadius);

  final CardThemeData cardTheme = switch (theme.cardStyle) {
    XpCardStyle.filled => CardThemeData(
      elevation: 0,
      color: cardColor ?? scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: cardShape,
      margin: EdgeInsets.zero,
    ),
    XpCardStyle.outlined => CardThemeData(
      elevation: 0,
      color: cardColor ?? scheme.surface,
      shape: cardShape.copyWith(
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    XpCardStyle.elevated => CardThemeData(
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.3),
      color: cardColor ?? scheme.surface,
      shape: cardShape,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
    ),
  };

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: cardTheme,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(XpRadius.m)),
      isDense: true,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(XpRadius.l)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: XpRadius.sheet,
      showDragHandle: true,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: animOn
              ? const ZoomPageTransitionsBuilder()
              : const FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
