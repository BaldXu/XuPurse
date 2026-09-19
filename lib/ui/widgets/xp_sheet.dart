import 'package:flutter/material.dart';

/// 统一底部弹窗入口:shape 由主题 bottomSheetTheme 提供(顶部圆角+拖动手柄),
/// 约定 isScrollControlled + 可选高度系数;调用方不再手写 RoundedRectangleBorder。
/// 出入场由 Material 3 内建(bottomSheetTheme 统一),主题动画开关控制页面转场。
Future<T?> showXpSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.7,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    builder: (ctx) => SizedBox(
      height: MediaQuery.heightOf(ctx) * heightFactor,
      child: builder(ctx),
    ),
  );
}

/// 限宽 AlertDialog:长文本确认弹窗在桌面宽屏不再被拉到接近全宽。
/// 项目内所有 showDialog(AlertDialog) 统一走这个封装。
Future<T?> showXpDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  required List<Widget> actions,
  double maxWidth = 400,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: contentWidget ?? (content != null ? Text(content) : null),
      ),
      actions: actions,
    ),
  );
}

/// 统一确认弹窗(取消 + 危险/普通确认),高频样板收敛。
Future<bool> confirmXpDialog(
  BuildContext context, {
  required String title,
  String? content,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  bool danger = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showXpDialog<bool>(
    context: context,
    title: title,
    content: content,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel),
      ),
      FilledButton(
        style: danger ? FilledButton.styleFrom(backgroundColor: scheme.error) : null,
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
  );
  return ok == true;
}

/// 统一加载指示(供页面 loading 态使用;动画系统接入后可换骨架屏)。
class XpLoading extends StatelessWidget {
  const XpLoading({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
