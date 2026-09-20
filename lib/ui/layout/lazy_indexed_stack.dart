import 'package:flutter/material.dart';

/// 懒挂载 IndexedStack:子项首次被选中才构建,构建后常驻(状态保留)。
///
/// 与 [IndexedStack] 的差别:未访问过的子项用零尺寸占位、不参与构建;
/// 访问过的子项与 IndexedStack 一样保持挂载(切走时不可见但不销毁)。
/// 用于 MainShell 让「统计」等重页面只在首次点入时才产生构建成本。
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
    // didUpdateWidget 之后框架必然 rebuild,此处无需 setState。
    _visited[widget.index] = true;
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _visited[i] ? widget.children[i] : const SizedBox.shrink(),
      ],
    );
  }
}
