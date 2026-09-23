import 'package:flutter/material.dart';

/// 多页面懒加载栈：只构建当前页与已访问页，未访问页切到时才首次构建。
///
/// 切换时新页以「覆盖淡入」转场出现：旧页保持不动（全程不透明），
/// 新页在其上方 180ms 淡入，动画结束后新页落到 Stack 主位、旧页
/// 转入 [Offstage] 保活。相比历史方案：
///
/// - 瞬时切换（无过渡）→ 首访页整页首次光栅化帧，页内所有
///   BackdropFilter 同时 readback 未就绪纹理，整页闪灰黑。
/// - 交叉淡化 / fade-through → 两页同时半透明叠加，文字重影、
///   闪近白屏（历史上线后均有用户录屏反馈，已回滚）。
/// - 覆盖淡入：旧页全程不透明，不存在半透明叠加；首访页在不可见的
///   淡入层完成首帧构建与光栅化，其磨砂元素 readback 的是下方已
///   稳定的旧页图层，不会闪黑；已访问页内容早已就绪，readback 的
///   也是稳定纹理。转场期间新页内容渐显，等价于「内容没准备好前不
///   显示」，且光栅化与转场动画并行，不拖慢切换。
///
/// 页面经 [GlobalKey] 保活：转场结束换位（淡入层 → Stack 主位 /
/// 主位 → Offstage）时 State 随 key 迁移，切走再切回列表滚动位置
/// 等状态不丢。
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({super.key, required this.index, required this.pages});

  final int index;
  final List<Widget> pages;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack>
    with TickerProviderStateMixin {
  /// 是否已首次构建过。未访问的页面完全不构建（懒加载）。
  late final List<bool> _visited;

  /// 每个页面的保活 key，转场换位时 State 随 key 迁移。
  final List<GlobalKey> _pageKeys = <GlobalKey>[];

  /// 当前占据 Stack 主位（底层、不透明）的页面。
  int _displayIndex = 0;

  /// 转场中正在淡入的页面（Stack 顶层）。
  int? _incomingIndex;
  AnimationController? _incomingController;
  CurvedAnimation? _incomingAnimation;

  @override
  void initState() {
    super.initState();
    _visited = List<bool>.filled(widget.pages.length, false);
    _visited[widget.index] = true;
    _displayIndex = widget.index;
    for (var i = 0; i < widget.pages.length; i++) {
      _pageKeys.add(GlobalKey());
    }
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index && widget.index != _displayIndex) {
      _beginTransition(widget.index);
    }
  }

  @override
  void dispose() {
    _incomingController?.dispose();
    super.dispose();
  }

  void _beginTransition(int target) {
    if (target < 0 || target >= widget.pages.length) return;
    // 打断进行中的转场：直接落到被打断转场的终点。
    final interrupted = _incomingIndex;
    if (interrupted != null) {
      _incomingController!.stop();
      _incomingController!.dispose();
      _incomingController = null;
      _incomingAnimation = null;
      _incomingIndex = null;
      _displayIndex = interrupted;
    }
    if (target == _displayIndex) {
      setState(() {});
      return;
    }
    setState(() {
      // 懒加载：本帧起新页开始构建，在不可见的淡入层完成首帧光栅化。
      _visited[target] = true;
      _incomingIndex = target;
    });
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _incomingController = controller;
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    );
    _incomingAnimation = animation;
    animation.addStatusListener(_handleTransitionEnd);
    controller.forward();
  }

  void _handleTransitionEnd(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final incoming = _incomingIndex;
    if (incoming == null) return;
    _incomingController!.dispose();
    _incomingController = null;
    _incomingAnimation = null;
    _incomingIndex = null;
    // 新页落到 Stack 主位（key 保活，State 迁移），旧页转 Offstage。
    setState(() => _displayIndex = incoming);
  }

  @override
  Widget build(BuildContext context) {
    final incoming = _incomingIndex;
    final children = <Widget>[];
    for (var i = 0; i < widget.pages.length; i++) {
      final page = KeyedSubtree(key: _pageKeys[i], child: widget.pages[i]);
      if (i == _displayIndex) {
        children.add(page);
      } else if (i == incoming) {
        children.add(FadeTransition(opacity: _incomingAnimation!, child: page));
      } else if (_visited[i]) {
        children.add(Offstage(child: page));
      }
    }
    return Stack(fit: StackFit.expand, children: children);
  }
}
