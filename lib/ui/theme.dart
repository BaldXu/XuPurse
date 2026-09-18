import 'package:flutter/material.dart';

/// XuPurse 主题：Material 3 简洁风，seedColor 可配置（「主题外观」页切换）。
///
/// [background] / [cardColor] 为用户主题的页面背景 / 卡片背景覆盖；
/// 为 null 时跟随 Material 3 派生色。
ThemeData buildAppTheme(
  Brightness brightness,
  Color seedColor, {
  Color? background,
  Color? cardColor,
}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor ?? scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    ),
  );
}
