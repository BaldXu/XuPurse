import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../layout/breakpoints.dart';
import '../tokens/design_tokens.dart';
import '../widgets/xp_frosted_bar.dart';
import '../widgets/xp_skeleton.dart';

/// 页面壳 mixin:统一 Scaffold + AppBar + 宽屏限宽居中。
///
/// 用法:State 混入本 mixin,build 里 `return buildXpScaffold(...)`。
/// 窄屏(手机竖屏/横屏)内容铺满,宽屏(桌面)按 [maxWidth] 限宽居中,
/// 与 MainShell 的断点体系一致。
///
/// 整页 loading:传 `loading: true` 时 body 换为整页骨架 [XpSkeletonPage],
/// 加载完成后与真实内容做淡入切换(XpMotion.component)。
/// 块级异步请用 XpAsyncView.xpWhen,不要两者叠加。
///
/// 进场动画:由路由转场统一负责(theme 的 XpPageTransitionsBuilder
/// 整页滑入 + 旧页后退的双层级转场),mixin 内不再叠加内容级进场,
/// 避免双重动画。特殊页面如需内容级进场,可自行包一层 [XpEntrance]
/// (仅首次构建触发,尊重动画开关与 reduce-motion)。
/// 首帧构建昂贵的页面另见 [xpPushSettled] 的骨架短路用法。
mixin XpPageScaffold<T extends StatefulWidget> on State<T> {
  double get xpMaxWidth => 720;

  // ── push 转场结束探测（重页面首帧骨架短路用）────────────────────
  Animation<double>? _xpRouteAnim;
  bool _xpSettled = false;

  /// push 转场动画是否已结束（ completed ）。
  ///
  /// 首帧同步构建昂贵的页面（重图表 / 大量静态卡片）在 build 开头短路：
  /// ```dart
  /// if (!xpPushSettled) {
  ///   return buildXpScaffold(appBar: appBar, loading: true);
  /// }
  /// ```
  /// 转场进行期间只构建轻量骨架（跟随内容区滑入），重内容连 widget
  /// 树都不创建，动画零抢帧；completed 后自动 setState，真实内容
  /// 响应式构建——重构建落在转场之后，用户感知为「内容加载」。
  /// 动画关闭 / 零时长转场时 animation 立即 completed，首帧即内容。
  bool get xpPushSettled {
    if (_xpSettled) return true;
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null) return true; // 非 route 场景（如测试）不阻塞
    if (!identical(anim, _xpRouteAnim)) {
      _xpRouteAnim = anim..addStatusListener(_xpOnRouteStatus);
    }
    // 挂 listener 时动画可能早已 completed(初始路由/home 直渲首帧即
    // 1.0 paused,completed 事件已发过不会重发),补查一次,否则骨架永远
    // 等不到 completed 而常驻(骨架脉冲无限循环,页面卡死在 loading)。
    if (anim.status == AnimationStatus.completed) {
      _xpSettled = true;
    }
    return _xpSettled;
  }

  void _xpOnRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _xpSettled = true);
    }
  }

  Widget buildXpScaffold({
    PreferredSizeWidget? appBar,
    Widget? body,
    bool loading = false,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    bool? resizeToAvoidBottomInset,
    // 磨砂穿透：true 时磨砂模式下 body 不再被下推到栏底，页面主滚动视图
    // 自行用 [xpFrostedBleedTop] 作为 padding.top，滚动内容即可从磨砂栏
    // 后穿过（栏内 BackdropFilter 有内容可采，磨砂可见）。默认 false 保持
    // 原下推行为（栏下无穿透，栏呈纯色）。
    bool frostedBleed = false,
  }) {
    // Consumer 包裹:磨砂开关(全局 provider)变化时本页即时切换栏样式。
    return Consumer(
      builder: (context, ref, _) {
        final frosted =
            ref.watch(frostedGlassProvider).barsOn &&
            appBar != null; // 磨砂:任意 AppBar 统一包壳,全部页面默认生效。
        // 页面转场由 theme 的 PageTransitionsTheme 统一负责
        // (XpPageTransitionsBuilder 整页滑入),此处不再叠加进场动画,
        // 保证一个页面只有一个转场动画。
        Widget content = ContentWidthBox(
          maxWidth: xpMaxWidth,
          child: AnimatedSwitcher(
            duration: XpMotion.component,
            switchInCurve: XpMotion.easeOut,
            switchOutCurve: XpMotion.easeIn,
            // 骨架淡入淡出；真实内容不加壳级透明度过渡 —— 内容自己的
            // XpStaggerIn/转场已负责入场，两层淡入叠加会「闪两下」。
            transitionBuilder: (child, animation) {
              final isSkeleton = (child.key as ValueKey<bool>?)?.value ?? true;
              return isSkeleton
                  ? FadeTransition(opacity: animation, child: child)
                  : child;
            },
            child: KeyedSubtree(
              key: ValueKey<bool>(loading),
              child: loading
                  ? const XpSkeletonPage()
                  : body ?? const SizedBox.shrink(),
            ),
          ),
        );
        // 磨砂 AppBar:默认 body 用「状态栏 + AppBar 实际高度」下推,内容不
        // 穿过栏,栏呈纯色;`frostedBleed: true` 的页面自行处理顶部留白
        // (见 [xpFrostedBleedTop]),内容从磨砂栏后穿过,磨砂可见。
        // removeTop 防止内层主滚动视图默认避让再次叠加状态栏间距。
        if (frosted && !frostedBleed) {
          content = MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Padding(
              padding: EdgeInsets.only(
                top:
                    MediaQuery.paddingOf(context).top +
                    appBar.preferredSize.height,
              ),
              child: content,
            ),
          );
        }
        final bar = appBar;
        return Scaffold(
          extendBodyBehindAppBar: frosted,
          appBar: bar == null
              ? null
              : XpRouteBar(child: frosted ? XpFrostedShell(child: bar) : bar),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: content,
        );
      },
    );
  }
}

/// 磨砂穿透顶部留白：状态栏 + 栏实际高度（`frostedBleed: true` 页面用）。
///
/// 用法（页面需 watch 磨砂开关保证切换时即时响应）：
/// ```dart
/// final appBar = AppBar(...);
/// final bleedTop = ref.watch(frostedGlassProvider).barsOn
///     ? xpFrostedBleedTop(context, appBar)
///     : 0.0;
/// return buildXpScaffold(
///   appBar: appBar,
///   frostedBleed: true,
///   body: ListView(padding: EdgeInsets.only(top: bleedTop, ...), ...),
/// );
/// ```
/// 该留白是滚动视图 padding 的一部分，会随内容滚出，实现 iOS 式
/// 「内容从磨砂栏后穿过」。注意取 viewPadding（Scaffold 对
/// extendBodyBehindAppBar 的 body 会移除 padding.top，viewPadding 不受影响）。
double xpFrostedBleedTop(BuildContext context, PreferredSizeWidget bar) =>
    MediaQuery.viewPaddingOf(context).top + bar.preferredSize.height;

/// 页面进场动画:内容淡入 + 上移 8dp(XpMotion.page),仅首次构建触发
/// (State 只创建一次,后续 rebuild 不重播)。
///
/// 关闭条件:系统「减少动画」(MediaQuery.disableAnimationsOf,设置变化时即时响应);
/// 转场动画固定开启,不再提供用户开关。
class XpEntrance extends StatefulWidget {
  const XpEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<XpEntrance> createState() => _XpEntranceState();
}

class _XpEntranceState extends State<XpEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: XpMotion.page,
  )..forward();
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: XpMotion.easeOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animOn = !MediaQuery.disableAnimationsOf(context);
    if (!animOn) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => FadeTransition(
        opacity: _curve,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}

/// 统一页面路由:全库页面 push 的唯一入口(替代裸 MaterialPageRoute)。
///
/// - 曲线:easeOutCubic 非线性缓出(起步轻快收尾放缓,iOS push 同款手感),
///   正反向同曲线;曲线单一来源在本路由的 [createAnimation],转场 builder
///   (theme 的 XpPageTransitionsBuilder)直接消费,不再二次包 curve。
/// - 时长:由 theme 的 pageTransitionsTheme 决定——XpPageTransitionsBuilder
///   400ms、动画关闭时 _ZeroTransitionPageTransitionsBuilder 归零。不在
///   路由层重复定义,避免「关闭动画后仍等待 400ms」。
///
/// 全库 push 一律走本路由,保证每条转场时长/曲线一致。
class XpRoute<T> extends MaterialPageRoute<T> {
  XpRoute({
    required super.builder,
    super.settings,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  });

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: controller!,
      curve: XpMotion.easeOut,
      reverseCurve: XpMotion.easeOut,
    );
  }
}

/// 转场栏壳:整页转场(theme 的 XpPageTransitionsBuilder)已让栏随页面一起
/// 滑入,此处仅保留 [RepaintBoundary] 做重绘隔离:页面 body 的重建/重绘
/// 不波及栏内 BackdropFilter 的模糊层,避免重建期快照重捕获出现黑帧
/// (明细页过度滑动、统计页切换分类等刷新动作后的磨砂闪黑)。
class XpRouteBar extends StatelessWidget implements PreferredSizeWidget {
  const XpRouteBar({super.key, required this.child});

  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: child);
  }
}
