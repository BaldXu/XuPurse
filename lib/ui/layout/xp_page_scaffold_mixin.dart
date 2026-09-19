import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';

/// 页面壳 mixin:统一 Scaffold + AppBar + 宽屏限宽居中。
///
/// 用法:State 混入本 mixin,build 里 `return buildXpScaffold(...)`。
/// 窄屏(手机竖屏/横屏)内容铺满,宽屏(桌面)按 [maxWidth] 限宽居中,
/// 与 MainShell 的断点体系一致。
mixin XpPageScaffold<T extends StatefulWidget> on State<T> {
  double get xpMaxWidth => 720;

  Widget buildXpScaffold({
    PreferredSizeWidget? appBar,
    Widget? body,
    Widget? floatingActionButton,
    Widget? bottomNavigationBar,
    bool? resizeToAvoidBottomInset,
  }) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: ContentWidthBox(maxWidth: xpMaxWidth, child: body ?? const SizedBox.shrink()),
    );
  }
}
