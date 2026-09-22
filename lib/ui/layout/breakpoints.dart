import 'package:flutter/material.dart';

/// 自适应布局断点与内容限宽工具。
///
/// 窄屏（< [kWideBreakpoint]）保持手机竖屏版式；
/// 宽屏（>= [kWideBreakpoint]）使用侧边导航 + 限宽居中内容。
const double kWideBreakpoint = 800;

/// 当前是否处于宽屏（桌面横屏）布局。
bool isWideScreen(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kWideBreakpoint;

/// 宽屏下把内容限宽并水平居中，窄屏原样返回（铺满）。
class ContentWidthBox extends StatelessWidget {
  const ContentWidthBox({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!isWideScreen(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
