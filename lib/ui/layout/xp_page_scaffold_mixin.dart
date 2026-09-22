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
/// 进场动画:由路由转场统一负责(theme 的 XpPageTransitionsBuilder,
/// 栏静止 + 内容区滑动的拆层结构),mixin 内不再叠加内容级进场,避免
/// 双重动画。特殊页面如需内容级进场,可自行包一层 [XpEntrance]
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
  }) {
    // Consumer 包裹:磨砂开关(全局 provider)变化时本页即时切换栏样式。
    return Consumer(
      builder: (context, ref, _) {
        final frosted =
            ref.watch(frostedGlassProvider).barsOn &&
            appBar != null; // 磨砂:任意 AppBar 统一包壳,全部页面默认生效。
        // 页面转场由 theme 的 PageTransitionsTheme 统一负责
        // (XpPageTransitionsBuilder 拆层滑动),此处不再叠加进场动画,
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
        // 磨砂 AppBar:body 延伸到 AppBar 底下,顶部用「状态栏 + AppBar 实际
        // 高度」留白,滚动内容可从磨砂栏后穿过。removeTop 防止内层主滚动视图
        // (ListView/CustomScrollView 默认避让)再次叠加状态栏间距。
        if (frosted) {
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
          body: XpRouteBody(child: content),
        );
      },
    );
  }
}

/// 页面进场动画:内容淡入 + 上移 8dp(XpMotion.page),仅首次构建触发
/// (State 只创建一次,后续 rebuild 不重播)。
///
/// 关闭条件:用户设置 animationsEnabled=false,或系统「减少动画」
/// (MediaQuery.disableAnimationsOf,设置变化时即时响应)。
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
    final animOn =
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(currentThemeProvider).animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
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

/// 统一页面路由:时长/曲线与全站 motion token 对齐(替代裸 MaterialPageRoute)。
///
/// - 时长 [XpMotion.page](400ms,双向同速)——比 SDK 默认 300ms 更舒缓优雅;
/// - 曲线 easeOutCubic 非线性缓出(起步轻快收尾放缓,iOS push 同款手感),
///   正反向同曲线;曲线单一来源在 route 层,[XpRouteBody] 直接消费,
///   不再二次包 curve。
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
  Duration get transitionDuration => XpMotion.page;

  @override
  Duration get reverseTransitionDuration => XpMotion.page;

  @override
  Animation<double> createAnimation() {
    return CurvedAnimation(
      parent: controller!,
      curve: XpMotion.easeOut,
      reverseCurve: XpMotion.easeOut,
    );
  }
}

/// 转场拆层-栏:固定不动,不参与转场动画(读当前 route 动画,仅为确认存在)。
///
/// 配合 [XpPageTransitionsBuilder](route 级零移动)使用:栏静止、内容滑动。
/// **严禁对栏做透明度/移动动画**——磨砂栏 BackdropFilter 在透明度动画下
/// 每帧重算模糊快照(theme.dart 已记录该候选方案实测缺陷)。栏固定后
/// 采样区不变,且内容滑动被 [XpRouteBody] 的 ClipRect 限制在栏下不侵入
/// 采样区 → 转场全程零模糊重算(iOS push 原生结构,栏即时显示)。
class XpRouteBar extends StatelessWidget implements PreferredSizeWidget {
  const XpRouteBar({super.key, required this.child});

  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// 转场拆层-内容区:横向滑动(读当前 route 动画)。
///
/// 只滑动内容区(栏以下),不带动磨砂栏;ClipRect 把滑动范围限制在 body
/// 区域——内容滑入时不会侵入固定栏区域,栏磨砂采样内容保持不变,
/// 零模糊重算。pop 时动画反向,内容自动右滑出(iOS pop 同款)。
///
/// 动画曲线单一来源 = route 的 createAnimation(XpRoute 覆写为
/// easeOutCubic),此处不再二次包 curve。动画开关关闭
/// (animationsEnabled=false / 系统 reduce-motion)时直接返回 child:
/// 壳层滑动不受 pageTransitionsTheme 的 zero builder 控制,必须自判,
/// 否则「关动画」后内容区仍滑动(视觉残留)。
class XpRouteBody extends StatelessWidget {
  const XpRouteBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final anim = ModalRoute.of(context)?.animation;
    if (anim == null) return child;
    final animOn =
        ProviderScope.containerOf(
          context,
          listen: false,
        ).read(currentThemeProvider).animationsEnabled &&
        !MediaQuery.disableAnimationsOf(context);
    if (!animOn) return child;
    return ClipRect(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }
}
