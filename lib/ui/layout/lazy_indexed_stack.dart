import 'package:flutter/material.dart';

/// 懒挂载 IndexedStack:子项首次被选中才构建,构建后常驻(状态保留)。
///
/// 与 [IndexedStack] 的差别:未访问过的子项不参与构建;
/// 访问过的子项保持挂载(切走时不可见但不销毁)。
/// 用于 MainShell 让「统计」等重页面只在首次点入时才产生构建成本。
///
/// 在此基础上叠加一级页面切换动效:交叉淡入淡出——
/// 新页淡入(easeOutCubic)、旧页同步淡出(easeIn),300ms。
/// 之前用位移轮播式被用户反馈「移一小段后突切」;纯淡化更顺。
/// 淡入淡出安全的前提:磨砂 BackdropFilter 已用 [BlendMode.src]
/// (官方推荐用于 saveLayer 场景),不再出现重影。
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack>
    with SingleTickerProviderStateMixin {
  late final List<bool> _visited = List<bool>.generate(
    widget.children.length,
    (i) => i == widget.index,
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  // 新页淡入:起步快、收尾稳。
  late final CurvedAnimation _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  // 旧页淡出:反向缓动,与淡入形成自然交叉。
  late final CurvedAnimation _fadeOut = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeIn,
  );

  // 静止页的恒定不透明度动画(动画参数变化不改变包裹结构)。
  static const _one = AlwaysStoppedAnimation<double>(1.0);

  int _outgoingIndex = -1; // 正在淡出的旧页;-1 表示无过渡

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _outgoingIndex = -1);
      }
    });
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index) {
      return;
    }
    _visited[widget.index] = true;
    _outgoingIndex = oldWidget.index.clamp(0, widget.children.length - 1);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _fadeOut.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animating = _outgoingIndex >= 0;
    return Stack(
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Positioned.fill(
            child: Offstage(
              // 平时仅当前页参与布局绘制;过渡中旧页保持可见以完成淡出。
              offstage:
                  !(i == widget.index || (animating && i == _outgoingIndex)),
              child: TickerMode(
                enabled:
                    i == widget.index || (animating && i == _outgoingIndex),
                child: _wrap(i, animating),
              ),
            ),
          ),
      ],
    );
  }

  /// 恒定包裹结构:每个子页恒为 IgnorePointer > FadeTransition > child,
  /// 动画起止只改参数不改结构,避免 Element 重建导致页面 State 丢失、
  /// 进场动画(XpEntrance)重播。
  Widget _wrap(int i, bool animating) {
    Animation<double> opacity = _one;
    var ignore = false;
    if (animating && i == _outgoingIndex) {
      // 旧页:淡出,并吞掉指针事件。
      opacity = Tween<double>(begin: 1, end: 0).animate(_fadeOut);
      ignore = true;
    } else if (animating && i == widget.index) {
      // 新页:淡入。
      opacity = Tween<double>(begin: 0, end: 1).animate(_fadeIn);
    }
    return IgnorePointer(
      ignoring: ignore,
      child: FadeTransition(opacity: opacity, child: widget.children[i]),
    );
  }
}
