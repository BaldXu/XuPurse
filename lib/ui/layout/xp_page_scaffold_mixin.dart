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
/// 进场动画:由路由转场统一负责(theme 的 CupertinoPageTransitionsBuilder),
/// mixin 内不再叠加内容级进场,避免双重动画。特殊页面如需内容级进场,
/// 可自行包一层 [XpEntrance](仅首次构建触发,尊重动画开关与 reduce-motion)。
mixin XpPageScaffold<T extends StatefulWidget> on State<T> {
  double get xpMaxWidth => 720;

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
        // 页面转场由 theme 的 PageTransitionsTheme 统一负责(Cupertino 滑动),
        // 此处不再叠加进场动画,保证一个页面只有一个转场动画。
        Widget content = ContentWidthBox(
          maxWidth: xpMaxWidth,
          child: AnimatedSwitcher(
            duration: XpMotion.component,
            switchInCurve: XpMotion.easeOut,
            switchOutCurve: XpMotion.easeIn,
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
        return Scaffold(
          extendBodyBehindAppBar: frosted,
          appBar: frosted ? XpFrostedShell(child: appBar) : appBar,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: content,
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
