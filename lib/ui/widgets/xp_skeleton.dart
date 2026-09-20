import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// 骨架屏 —— 页面/区块 loading 态的统一占位（ui-refactor-plan 0.2）。
///
/// - 色值取 `colorScheme.onSurface` 低透明度：浅色底上是冷灰蓝、暗色下自动反白；
/// - 呼吸脉冲（透明度 1.0 ↔ 0.5，1400ms）；系统开启「减弱动态效果」时静态显示；
/// - 组合方式：原语 [XpSkeletonBox] / [XpSkeletonLine] / [XpSkeletonCircle] 是静态形状，
///   [XpSkeletonList] / [XpSkeleton] 内部整组套一层脉冲，避免逐元素挂控制器。

/// 脉冲呼吸封装（内部使用）：单控制器 + 透明度渐变。
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: 1.0 - 0.5 * Curves.easeInOut.transform(_controller.value),
        child: child,
      ),
    );
  }
}

/// 骨架填充色：主文字色 8% 透明度（随主题适配暗色）。
Color _skeletonFill(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);

/// 静态原语：矩形块（width 为 null 时撑满可用宽度）。
class XpSkeletonBox extends StatelessWidget {
  const XpSkeletonBox({
    super.key,
    this.width,
    this.height = 100,
    this.borderRadius = const BorderRadius.all(Radius.circular(XpRadius.s)),
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: _skeletonFill(context),
        shape: XpShape.smooth(borderRadius: borderRadius),
      ),
    );
  }
}

/// 静态原语：文本行（胶囊形，height 默认 12 对应一行正文）。
class XpSkeletonLine extends StatelessWidget {
  const XpSkeletonLine({super.key, this.width, this.height = 12});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: _skeletonFill(context),
        shape: XpShape.smooth(
          borderRadius: BorderRadius.circular(XpRadius.pill),
        ),
      ),
    );
  }
}

/// 静态原语：圆形（分类图标位、头像位）。
class XpSkeletonCircle extends StatelessWidget {
  const XpSkeletonCircle({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: _skeletonFill(context),
        shape: const CircleBorder(),
      ),
    );
  }
}

/// 单个呼吸占位块：独立使用时的便捷封装（内部套脉冲）。
class XpSkeleton extends StatelessWidget {
  const XpSkeleton({
    super.key,
    this.width,
    this.height = 100,
    this.circle = false,
  });

  final double? width;
  final double height;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      child: circle
          ? XpSkeletonCircle(size: height)
          : XpSkeletonBox(width: width, height: height),
    );
  }
}

/// 账单流列表骨架：[圆形图标 | 两行文字 | 金额] 的逐行占位，整组呼吸。
///
/// 直接放进现有滚动容器（CustomScrollView 的 SliverFillRemaining、
/// Column 内的 Expanded 等），不自带滚动。
class XpSkeletonList extends StatelessWidget {
  const XpSkeletonList({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.symmetric(
      horizontal: XpSpacing.l,
      vertical: XpSpacing.s,
    ),
  });

  final int itemCount;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: _Rows(count: itemCount),
      ),
    );
  }
}

/// 整页骨架：标题行 + 汇总卡片块 + 账单流列表，自带滚动。
/// 供 `buildXpScaffold(loading: true)` 等整页 loading 场景使用。
class XpSkeletonPage extends StatelessWidget {
  const XpSkeletonPage({
    super.key,
    this.padding = const EdgeInsets.all(XpSpacing.l),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      child: _Pulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: XpSkeletonLine(width: 96, height: 20),
            ),
            const SizedBox(height: XpSpacing.l),
            const XpSkeletonBox(
              height: 96,
              borderRadius: BorderRadius.all(Radius.circular(XpRadius.m)),
            ),
            const SizedBox(height: XpSpacing.xl),
            const _Rows(count: 8),
          ],
        ),
      ),
    );
  }
}

/// 列表行组：奇偶行微差（标题/副标题宽度交替），避免完全机械。
class _Rows extends StatelessWidget {
  const _Rows({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: XpSpacing.l),
          _Row(variant: i.isOdd),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.variant});

  /// 奇偶行微差：标题/副标题宽度交替，避免完全机械。
  final bool variant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const XpSkeletonCircle(),
        const SizedBox(width: XpSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              XpSkeletonLine(width: variant ? 132 : 168),
              const SizedBox(height: XpSpacing.s),
              XpSkeletonLine(width: variant ? 88 : 104, height: 10),
            ],
          ),
        ),
        const SizedBox(width: XpSpacing.m),
        const XpSkeletonLine(width: 64, height: 14),
      ],
    );
  }
}
