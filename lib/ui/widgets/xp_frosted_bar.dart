import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// 磨砂玻璃容器:固定白色高斯模糊(不随主题色变化)。
///
/// 内容(列表/卡片)从栏底穿过时透出模糊影像,形成磨砂质感。
/// 必须配合 [Scaffold.extendBody] / [Scaffold.extendBodyBehindAppBar]
/// 使用,否则栏下只有背景色,模糊无内容可透。
///
/// 普通 [BackdropFilter] + [BlendMode.src] 各自捕获快照(σ15 · α0.30)：
/// - src 防御父级 saveLayer(如 Opacity)下的混合异常(官方文档推荐做法)；
/// - 不用 grouped 共享快照：Flutter 3.35 上共享快照滚动/重建会整帧闪
///   灰黑(Impeller/Skia 均复现,真机视频已确认),各自捕获彻底规避。
class XpFrostedContainer extends StatelessWidget {
  const XpFrostedContainer({
    super.key,
    this.child = const SizedBox.expand(),
    this.sigma = 15,
    this.alpha = 0.30,
  });

  /// 作为 AppBar 的磨砂底层时可省略(由 Positioned.fill 撑满)。
  final Widget child;

  /// 高斯模糊半径。
  final double sigma;

  /// 白色磨砂底的不透明度(叠在模糊内容之上,保证前景可读性)。
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        blendMode: BlendMode.src,
        child: ColoredBox(
          color: Colors.white.withValues(alpha: alpha),
          child: child,
        ),
      ),
    );
  }
}

/// 磨砂壳:把任意 [PreferredSizeWidget](通常是 [AppBar])包成磨砂栏。
///
/// 结构 = 磨砂底层铺满 + 透明背景的原 AppBar;子页面无需任何改动,
/// 由 buildXpScaffold 统一包装。通过 AppBarTheme 覆盖把原栏背景变透明,
/// 保持 title/actions/bottom 全部原样。
class XpFrostedShell extends StatelessWidget implements PreferredSizeWidget {
  const XpFrostedShell({super.key, required this.child});

  /// 原始栏(通常为 AppBar,须未显式指定不透明背景色)。
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        const Positioned.fill(child: XpFrostedContainer()),
        Theme(
          data: theme.copyWith(
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              elevation: 0,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
