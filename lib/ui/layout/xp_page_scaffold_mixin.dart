import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import '../tokens/design_tokens.dart';
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
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: ContentWidthBox(
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
      ),
    );
  }
}
