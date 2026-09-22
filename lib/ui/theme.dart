import 'package:flutter/material.dart';

import '../state/theme_provider.dart';
import 'tokens/design_tokens.dart';
import 'widgets/xp_card.dart';

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

/// 页面转场选型的原因记录(见下方 pageTransitionsTheme):
/// 本 App 每页 AppBar 带磨砂 BackdropFilter,候选转场均有实测缺陷——
/// 自定义淡入/交叉淡化/fade-through:整页透明度动画包住磨砂栏,引擎逐帧
/// 重算模糊快照,进二级页明显闪烁;Zoom(M3 默认):toImage 快照在
/// Impeller/Vulkan 阻塞 UI 线程;PredictiveBack:磨砂铺开时实测定稿移除;
/// FadeForwards(Android U):本质仍是交叉淡化且 800ms 更长。
/// 原 CupertinoPageTransitionsBuilder 纯 Transform 滑动,但整页(含磨砂栏)
/// 一起移动 → 栏 BackdropFilter 采样区每帧变化 → 转场每帧重算模糊
/// (真机实测 raster 尖峰 34-42ms 的来源)。
/// 2026-09-22 第二轮 B1 改为 iOS push 原生拆层结构:route 级零移动
/// (XpPageTransitionsBuilder),由页面壳 XpRouteBar/XpRouteBody 自驱——
/// 栏固定 cross-fade(采样区不变 → 模糊零重算) + 内容区滑动(无模糊,
/// ClipRect 限制在栏下,不侵入栏采样区);旧页不做视差移动(静止被覆盖,
/// 同 iOS pop 的底层页)。animationsEnabled=false 时走零时长。
/// 转场时长/曲线由 [XpRoute] 承担(400ms easeOutCubic,见其注释),
/// 与 pageTransitionsTheme 正交:builder 只决定「route 移动与否」。

/// 页面转场拆层 builder:整页零移动,动画由页面壳自驱(见上方说明)。
class XpPageTransitionsBuilder extends PageTransitionsBuilder {
  const XpPageTransitionsBuilder();

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

// ── ThemeData 实例缓存 ────────────────────────────────────────────
// MaterialApp 内建 AnimatedTheme 按「ThemeData 实例是否变化」决定是否触发
// 200ms lerp + 全树 rebuild（输入相同实例则直接短路，不动画）。
// 不缓存时每次 XuPurseApp.build 都新建实例（fromSeed/全量对象树），
// 磨砂子项开关等与主题无关的 provider 波动也会被当成主题切换触发
// 假 lerp + 假 rebuild。按输入缓存后：无关波动零成本，真切换一次构建。
ThemeData? _cachedLight;
AppTheme? _lightKeyTheme;
bool? _lightKeyAnim;
bool? _lightKeyFrost;
ThemeData? _cachedDark;
bool? _darkKeyAnim;
bool? _darkKeyFrost;

ThemeData buildAppTheme(
  Brightness brightness,
  AppTheme theme, {
  bool? animationsEnabled,
  bool cardFrosted = false,
}) {
  final dark = brightness == Brightness.dark || theme.isDark;
  final animOn = animationsEnabled ?? theme.animationsEnabled;
  if (!dark &&
      _cachedLight != null &&
      identical(theme, _lightKeyTheme) &&
      _lightKeyAnim == animOn &&
      _lightKeyFrost == cardFrosted) {
    return _cachedLight!;
  }
  if (dark &&
      _cachedDark != null &&
      _darkKeyAnim == animOn &&
      _darkKeyFrost == cardFrosted) {
    return _cachedDark!;
  }
  final data = _buildAppTheme(brightness, theme, animOn, cardFrosted);
  if (dark) {
    _cachedDark = data;
    _darkKeyAnim = animOn;
    _darkKeyFrost = cardFrosted;
  } else {
    _cachedLight = data;
    _lightKeyTheme = theme;
    _lightKeyAnim = animOn;
    _lightKeyFrost = cardFrosted;
  }
  return data;
}

ThemeData _buildAppTheme(
  Brightness brightness,
  AppTheme theme,
  bool animOn,
  bool cardFrosted,
) {
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

  // 卡片磨砂：卡片表面换半透明白（α0.55），覆盖用户自定义卡色。
  // XpCard 在磨砂开启时自带真实高斯模糊层（σ10 + 白 0.55，见 XpCard.frost*），
  // 此处仅服务于内页原始 Card（统计/趋势等，无穿底内容、不叠真实模糊）。
  // 仅浅色模式生效：暗色下白色磨砂会让白字卡片内容不可读。
  final effectiveCardFrosted = cardFrosted && !dark;
  final frostCardColor = Colors.white.withValues(alpha: XpCard.frostAlpha);

  final CardThemeData cardTheme = switch (theme.cardStyle) {
    XpCardStyle.filled => CardThemeData(
      elevation: XpElevation.e0,
      color: effectiveCardFrosted
          ? frostCardColor
          : (cardColor ??
                scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
      shape: cardShape,
      margin: EdgeInsets.zero,
    ),
    XpCardStyle.outlined => CardThemeData(
      elevation: XpElevation.e0,
      color: effectiveCardFrosted
          ? frostCardColor
          : (cardColor ?? scheme.surface),
      shape: cardShape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
      margin: EdgeInsets.zero,
    ),
    XpCardStyle.elevated => CardThemeData(
      elevation: XpElevation.e1,
      shadowColor: XpElevation.shadow.withValues(alpha: 0.24),
      color: effectiveCardFrosted
          ? frostCardColor
          : (cardColor ?? scheme.surface),
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
      backgroundColor: theme.sheetColor,
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
              : const XpPageTransitionsBuilder(),
      },
    ),
  );
}
