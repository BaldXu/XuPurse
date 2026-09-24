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
///
/// 重页面「转场动画期间不卡」的两个开关（页面只需做最小声明，逻辑全在
/// 基类）：
/// 1. 首帧构建昂贵的页面 → buildXpScaffold 传 [buildBody]（转场期间出
///    骨架，completed 后首次构建真实内容，见 [xpPushSettled]）。
/// 2. 进页面就要拉数据/算摘要的重页面 → initState 里 [xpRunWhenSettled]
///    启动任务（把 DB 聚合/遍历等耗时任务推迟到转场结束后执行）。
mixin XpPageScaffold<T extends StatefulWidget> on State<T> {
  double get xpMaxWidth => 720;

  // ── push 转场结束探测（重页面首帧骨架短路用）────────────────────
  Animation<double>? _xpRouteAnim;
  bool _xpSettled = false;
  VoidCallback? _xpSettledTask;

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
    final route = ModalRoute.of(context);
    final anim = route?.animation;
    if (anim == null) return true; // 非 route 场景（如测试）不阻塞
    _xpEnsureRouteListener(anim);
    // 首帧 offstage 陷阱：ModalRoute 首帧会为 Hero 定位而离屏构建
    // （offstage），此刻 animation 代理 = kAlwaysCompleteAnimation
    // （status=completed），但转场其实刚起步（真实 controller 还在 0）。
    // 若按 completed 直接放行，重内容首帧即构建、骨架门形同虚设——
    // 转场最卡的正是首帧。offstage 在首帧后由 HeroController 翻回
    // false（routes.dart _animationProxy.parent 恢复真实动画），
    // 届时按真实动画判定，completed 事件由状态监听兜底。
    if (route!.offstage) {
      return false;
    }
    // 挂 listener 时动画可能早已 completed(初始路由/home 直渲首帧即
    // 1.0 paused,completed 事件已发过不会重发),补查一次,否则骨架永远
    // 等不到 completed 而常驻(骨架脉冲无限循环,页面卡死在 loading)。
    if (anim.status == AnimationStatus.completed) {
      _xpSettled = true;
      _xpRunSettledTask();
    }
    return _xpSettled;
  }

  /// 转场动画结束后再执行一次性的耗时任务（「进页面即拉数据」的重页面用）。
  ///
  /// 任务若在 initState 里同步启动（DB 聚合 / 遍历大量账单 / 生成摘要等），
  /// 会与转场动画抢主线程导致动画掉帧；用本方法把任务推迟到转场
  /// completed 后执行，动画零抢帧，用户感知为「转场完成后再加载」。
  /// 非 route 场景（tab 常驻 / 测试）下立即执行。
  ///
  /// 用法（通常 initState 里调用一次）：
  /// ```dart
  /// xpRunWhenSettled(_load);
  /// ```
  void xpRunWhenSettled(VoidCallback task) {
    if (_xpSettled) {
      task();
      return;
    }
    // ModalRoute.of 依赖 InheritedWidget 查询，不能在 initState 同步调用；
    // 推迟到首帧构建后再挂 listener / 判状态。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _xpSchedule(task);
    });
  }

  void _xpSchedule(VoidCallback task) {
    final route = ModalRoute.of(context);
    final anim = route?.animation;
    if (anim == null) {
      task(); // 非 route 场景（tab 常驻/测试）立即执行
      return;
    }
    // 首帧 offstage 陷阱同 [xpPushSettled]：此刻动画代理显示 completed 但
    // 转场刚起步，不能立即放行；挂 listener 等真实动画 completed 兜底。
    if (route!.offstage) {
      _xpSettledTask = task;
      _xpEnsureRouteListener(anim);
      return;
    }
    if (anim.status == AnimationStatus.completed) {
      _xpSettled = true;
      task();
      return;
    }
    _xpSettledTask = task;
    _xpEnsureRouteListener(anim);
  }

  void _xpEnsureRouteListener(Animation<double> anim) {
    if (!identical(anim, _xpRouteAnim)) {
      _xpRouteAnim = anim..addStatusListener(_xpOnRouteStatus);
    }
  }

  void _xpOnRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _xpSettled = true);
      _xpRunSettledTask();
    }
  }

  void _xpRunSettledTask() {
    final task = _xpSettledTask;
    if (task != null) {
      _xpSettledTask = null;
      task();
    }
  }

  // ── 首帧骨架门（无路由转场的常驻页：tab 页）────────────────────
  bool _xpFrameScheduled = false;
  bool _xpFirstSettledFlag = false;

  /// 首次挂载骨架门：无路由转场的页面（MainShell 的 tab 常驻页）用。
  ///
  /// 切 tab 首次挂载瞬间，整页树首帧全量构建会与导航栏指示器动画抢帧；
  /// 首帧只构建轻量骨架，首帧渲染完成后（addPostFrameCallback）自动
  /// setState 重建真实内容，把重构建推迟到切换瞬间之后。
  /// 用法同 [xpPushSettled]：
  /// ```dart
  /// if (!xpFirstSettled) {
  ///   return buildXpScaffold(appBar: appBar, body: const XpSkeletonPage());
  /// }
  /// ```
  /// 仅首个未挂载帧生效；挂载后再次切回本 tab 不重播（LazyIndexedStack
  /// 保持 State，_xpFirstSettledFlag 已置位）。
  bool get xpFirstSettled {
    if (_xpFirstSettledFlag) return true;
    if (!_xpFrameScheduled) {
      _xpFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _xpFirstSettledFlag = true);
      });
    }
    return false;
  }

  Widget buildXpScaffold({
    PreferredSizeWidget? appBar,
    Widget? body,

    /// 惰性 body 构建器：与 [body] 二选一，重页面用。
    ///
    /// push 转场进行期间自动用整页骨架占位（见 [xpPushSettled]），转场
    /// completed 后首次构建真实内容——骨架短路建在基类，页面无需
    /// `if (!xpPushSettled) return buildXpScaffold(loading: true);` 样板，
    /// 等价于手动短路写法。非 route 场景（tab 常驻/测试）下立即构建。
    WidgetBuilder? buildBody,
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
        // 转场骨架门：提供 buildBody 的页面在 push 转场进行中自动出整页
        // 骨架（重内容连 widget 树都不建，动画零抢帧），route animation
        // completed 后首次构建真实内容——骨架短路建在基类，页面零样板。
        final showSkeleton = loading || (buildBody != null && !xpPushSettled);
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
              key: ValueKey<bool>(showSkeleton),
              child: showSkeleton
                  ? const XpSkeletonPage()
                  : (buildBody != null
                        ? buildBody(context)
                        : body ?? const SizedBox.shrink()),
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

/// 弹窗进场骨架门（通用）：挂在任意 State 上（弹窗等非 [XpPageScaffold]
/// 场景），提供 [xpEnterSettled]。
///
/// showXpSheet / showGeneralDialog 弹窗的滑入动画期间只构建轻量骨架，
/// 重内容（分类网格 / 键盘等）连 widget 树都不建，动画零抢帧；route
/// animation completed 后自动 setState 重建真实内容。
/// 与 [XpPageScaffold.xpPushSettled] 同款语义（status 监听 + completed
/// 补查，避免「动画早已 completed 时骨架常驻卡死」），独立实现供弹窗用。
mixin XpSettleGate<T extends StatefulWidget> on State<T> {
  Animation<double>? _xpRouteAnim;
  bool _xpSettled = false;

  /// 弹窗滑入动画是否已结束（ completed ）。无路由动画（测试等）恒为 true。
  ///
  /// 用法：
  /// ```dart
  /// if (!xpEnterSettled) {
  ///   return const XpSkeletonPage();
  /// }
  /// ```
  bool get xpEnterSettled {
    if (_xpSettled) return true;
    final route = ModalRoute.of(context);
    final anim = route?.animation;
    if (anim == null) return true;
    if (!identical(anim, _xpRouteAnim)) {
      _xpRouteAnim = anim..addStatusListener(_xpOnRouteStatus);
    }
    // 首帧 offstage 陷阱：ModalRoute 首帧会为 Hero 定位而离屏构建
    // （offstage），此刻 animation 代理 = kAlwaysCompleteAnimation
    // （status=completed），但转场其实刚起步（真实 controller 还在 0）。
    // 若按 completed 直接放行，重内容首帧即构建、骨架门形同虚设——
    // 转场最卡的正是首帧。offstage 在首帧后由 HeroController 翻回
    // false（routes.dart _animationProxy.parent 恢复真实动画），
    // 届时按真实动画判定，completed 事件由状态监听兜底。
    if (route!.offstage) {
      return false;
    }
    if (anim.status == AnimationStatus.completed) _xpSettled = true;
    return _xpSettled;
  }

  void _xpOnRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _xpSettled = true);
    }
  }
}
