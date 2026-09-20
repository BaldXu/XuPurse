import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// 列表项进视口轻微淡入(阶段2 stagger 试点):仅透明度,无位移/缩放,
/// 索引差分延迟(每项 +40ms,封顶 240ms)避免长列表尾部等待。
///
/// 性能守则:
/// - 只对「首次进视口」做一次动画(AnimationController forward 后不再重播);
/// - reduce-motion 时直接返回 child,不包任何动画;
/// - 超长列表(如首页千条账单)应限制使用范围或回退本组件。
class XpStaggerIn extends StatefulWidget {
  const XpStaggerIn({super.key, required this.index, required this.child});

  /// 列表项索引,用于差分延迟。
  final int index;

  final Widget child;

  @override
  State<XpStaggerIn> createState() => _XpStaggerInState();
}

class _XpStaggerInState extends State<XpStaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: XpMotion.component,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: XpMotion.easeOut,
  );

  @override
  void initState() {
    super.initState();
    // 首帧后启动,索引差分延迟(封顶 240ms,避免长列表尾部明显等待)
    final delayMs = (widget.index * 40).clamp(0, 240);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (delayMs == 0) {
        _controller.forward();
      } else {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(opacity: _curve, child: widget.child);
  }
}
