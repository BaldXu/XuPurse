import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/theme_provider.dart';
import 'tokens/design_tokens.dart';
import 'widgets/xp_card.dart';

/// XuPurse 主题:Material 3,由 [AppTheme] 配置驱动。
///
/// - 颜色:seedColor 生成 ColorScheme;background/cardColor 为浅色覆盖;
///   暗色主题(preset_dark)不使用用户覆盖色,完全由派生色构成。
/// - 字体:fontFamily + fontScale 作用于全局 textTheme。
/// - 卡片:样式(filled/outlined/elevated)+ 圆角由主题统一定制,页面不得绕过。
/// - 动画:pageTransitionsTheme / 弹窗等固定开启,仅系统「减少动画」
///   (MediaQuery.disableAnimations,main 层强制关闭时)走零时长。
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

/// 页面转场选型说明（见 pageTransitionsTheme）：
/// 统一由 [XpPageTransitionsBuilder] 承担「整页」双层级转场（2026-09-22 第三轮）：
/// - 新页（本路由 animation）：整页从右滑入（含 AppBar，消除旧版「栏先闪现、
///   内容后滑」的割裂感）+ 轻微放大（0.98→1.0，前景靠近感）；曲线 easeOutCubic
///   由 [XpRoute] 提供（进入/返回同曲线），builder 直接消费。
/// - 旧页（secondaryAnimation，本路由被新页覆盖时）：Scale 1.0→0.96 + 轻微左移
///   + 变暗遮罩 + 轻微模糊，产生「旧页后退、新页进入前景」的空间层级感。
/// - 返回 / 系统返回 / App 返回按钮都走同一 animation 反向，视觉天然一致。
/// 性能：旧页模糊 sigma 为独立常量（[XpMotion.pageExitBlur]），掉帧时置 0 退化
/// 为 Scale + Translate + Dim；磨砂开启时转场期间 BackdropFilter 会重算模糊
/// 快照（已知成本，磨砂默认关闭，见 FrostedGlassNotifier 注释）。
/// 动画关闭（设置 / 系统 reduce-motion）时 theme 选用
/// [_ZeroTransitionPageTransitionsBuilder]：零时长零移动；转场时长由各 builder
/// 的 transitionDuration 决定（此处 400ms / 关闭时 0ms），与路由层正交，
/// 避免「关动画后仍等待 400ms」。

/// 页面转场 builder：整页双层级转场（新页滑入 + 旧页后退），全站唯一入口。
class XpPageTransitionsBuilder extends PageTransitionsBuilder {
  const XpPageTransitionsBuilder();

  @override
  Duration get transitionDuration => XpMotion.page;

  @override
  Duration get reverseTransitionDuration => XpMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    return _XpPageTransition(
      animation: animation,
      secondaryAnimation:
          secondaryAnimation ?? const AlwaysStoppedAnimation<double>(0),
      child: child,
    );
  }
}

/// 双层级转场渲染：由「本路由进入动画」与「上方路由动画」共同驱动。
class _XpPageTransition extends StatefulWidget {
  const _XpPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  /// 本路由的进入动画（[XpRoute] 已套 easeOutCubic 曲线）。
  final Animation<double> animation;

  /// 上方路由的动画（本路由被覆盖为「旧页」时随之推进）。
  final Animation<double> secondaryAnimation;

  final Widget child;

  @override
  State<_XpPageTransition> createState() => _XpPageTransitionState();
}

class _XpPageTransitionState extends State<_XpPageTransition> {
  late Listenable _merged;

  @override
  void initState() {
    super.initState();
    _merged = Listenable.merge([widget.animation, widget.secondaryAnimation]);
  }

  @override
  void didUpdateWidget(_XpPageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation ||
        oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      _merged = Listenable.merge([widget.animation, widget.secondaryAnimation]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 实时模糊动效开关：关闭时 pageExitBlur 有效值归零，转场退化为
    // 纯位移 + 缩放 + 变暗（不再逐帧重算模糊快照，更省 GPU）。
    final blurOn = ProviderScope.containerOf(
      context,
      listen: true,
    ).read(transitionBlurProvider);
    return AnimatedBuilder(
      animation: _merged,
      // 页面本体作为 child 复用，动画帧只重建变换层，不重建页面。
      child: widget.child,
      builder: (context, child) {
        final enter = widget.animation.value;
        final back = widget.secondaryAnimation.value;
        Widget result = child!;

        // ── 本页被新页覆盖（旧页）：后退——缩放 + 轻微左移 + 模糊 + 变暗 ──
        if (back > 0) {
          result = Transform.translate(
            offset: Offset(-XpMotion.pageExitShift * back, 0),
            child: Transform.scale(
              scale: 1 - (1 - XpMotion.pageExitScaleTo) * back,
              child: result,
            ),
          );
          final blur = (blurOn ? XpMotion.pageExitBlur : 0.0) * back;
          if (blur > 0) {
            result = ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: result,
            );
          }
          final dim = XpMotion.pageExitDim * back;
          if (dim > 0.01) {
            result = Stack(
              fit: StackFit.expand,
              children: [
                result,
                // 变暗遮罩铺满本路由区域（含缩放后露出的边缘），位于上方
                // 新页之下，把视觉焦点让给新页。
                IgnorePointer(
                  child: ColoredBox(color: Colors.black.withValues(alpha: dim)),
                ),
              ],
            );
          }
        }

        // ── 本页作为新页进入：整页滑入 + 轻微放大（靠近感）──
        if (enter < 1) {
          result = ScaleTransition(
            scale: Tween<double>(
              begin: XpMotion.pageEnterScaleFrom,
              end: 1.0,
            ).animate(widget.animation),
            child: result,
          );
          result = SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(widget.animation),
            child: result,
          );
        }
        return result;
      },
    );
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
  final animOn = animationsEnabled ?? true;
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
