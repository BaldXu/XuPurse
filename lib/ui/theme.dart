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
/// 关闭转场动画时的零时长 builder(Flutter SDK 无 NoTransition 内建实现)。
class _ZeroTransitionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _ZeroTransitionPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

ThemeData buildAppTheme(
  Brightness brightness,
  AppTheme theme, {
  bool? animationsEnabled,
}) {
  final dark = brightness == Brightness.dark || theme.isDark;
  ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: theme.seedColor,
    brightness: dark ? Brightness.dark : Brightness.light,
  );
  // fromSeed 会把深色 seed 稀释成 tonal palette；浅色模式下恢复品牌原色
  // （如克莱因蓝 #002FA7），保证主色纯正。
  if (!dark && theme.seedColor.computeLuminance() < 0.35) {
    scheme = scheme.copyWith(primary: theme.seedColor, onPrimary: Colors.white);
  }
  final animOn = animationsEnabled ?? theme.animationsEnabled;
  // 暗色主题不应用用户的浅色背景/卡色覆盖(暗色 = 独立预设主题,已决策)。
  final background = dark ? null : theme.background;
  final cardColor = dark ? null : theme.cardColor;

  final baseTextTheme = dark
      ? Typography.material2021().white
      : Typography.material2021().black;
  final fontScale = theme.fontScale;
  // 挂载设计排印阶梯，再应用用户字体/缩放（apply 不覆盖 fontFeatures 等字段）。
  var textTheme = baseTextTheme.merge(
    const TextTheme(
      displayLarge: XpTextStyles.display,
      headlineMedium: XpTextStyles.h1,
      headlineSmall: XpTextStyles.h3,
      titleLarge: XpTextStyles.h2,
    ),
  );
  if (theme.fontFamily != null || fontScale != 1.0) {
    textTheme = textTheme.apply(
      fontFamily: theme.fontFamily,
      fontSizeFactor: fontScale,
    );
  }

  final cardRadius = BorderRadius.circular(theme.cardRadius ?? XpRadius.m);
  final cardShape = XpShape.smooth(borderRadius: cardRadius);

  final CardThemeData cardTheme = switch (theme.cardStyle) {
    XpCardStyle.filled => CardThemeData(
      elevation: XpElevation.e0,
      color: cardColor ?? scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: cardShape,
      margin: EdgeInsets.zero,
    ),
    XpCardStyle.outlined => CardThemeData(
      elevation: XpElevation.e0,
      color: cardColor ?? scheme.surface,
      shape: cardShape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
      margin: EdgeInsets.zero,
    ),
    XpCardStyle.elevated => CardThemeData(
      elevation: XpElevation.e1,
      shadowColor: XpElevation.shadow.withValues(alpha: 0.24),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(XpRadius.s),
      ),
      isDense: true,
    ),
    dialogTheme: DialogThemeData(
      shape: XpShape.smooth(borderRadius: BorderRadius.circular(XpRadius.l)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: XpRadius.sheet,
      showDragHandle: true,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: XpShape.smooth(borderRadius: BorderRadius.circular(XpRadius.s)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: !animOn
              ? const _ZeroTransitionPageTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
