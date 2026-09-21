import 'package:flutter/material.dart';

/// 懒挂载 IndexedStack:子项首次被选中才构建,构建后常驻(状态保留)。
///
/// 与 [IndexedStack] 的差别:未访问过的子项不参与构建;
/// 访问过的子项保持挂载(切走时不可见但不销毁)。
/// 用于 MainShell 让「统计」等重页面只在首次点入时才产生构建成本。
///
/// 一级页面切换为**瞬时切换,不做内容动画**(Material 3 NavigationBar
/// 标准行为:运动反馈由导航栏指示器动画承担,页面内容直接替换)。
/// 历史上尝试过三种自定义过渡,均有视觉缺陷:
/// - 位移轮播:被反馈「移一小段后突切」;
/// - 交叉淡化:两页半透明叠加,文字互相叠印(重影闪屏,见用户录屏);
/// - fade-through(先出后进):交接瞬间两页透明度同时≈0,白色背景上
///   闪一帧近白屏;且磨砂 AppBar 的 BackdropFilter 在透明度动画期间
///   每帧重算模糊快照,引擎合成层易抖动。
/// 瞬时切换从根上绕开上述问题,也是微信/支付宝/Flutter Gallery 的做法。
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

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late final List<bool> _visited = List<bool>.generate(
    widget.children.length,
    (i) => i == widget.index,
  );

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == oldWidget.index) {
      return;
    }
    // 首次点入才挂载该页;已挂载页保持状态,仅切换可见性。
    setState(() => _visited[widget.index] = true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < widget.children.length; i++)
          if (_visited[i])
            Positioned.fill(
              child: Offstage(
                offstage: i != widget.index,
                // 隐藏页停掉动画驱动(滚动惯性等),避免白白消耗 ticker。
                child: TickerMode(
                  enabled: i == widget.index,
                  child: widget.children[i],
                ),
              ),
            ),
      ],
    );
  }
}
