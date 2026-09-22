import 'package:flutter/material.dart';

/// 统一 SnackBar 入口:内置 hideCurrentSnackBar 前置,消除同屏 Hero tag 冲突。
/// 页面不再直接调 ScaffoldMessenger.showSnackBar。
void showXpSnack(BuildContext context, String message, {bool error = false}) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? scheme.errorContainer : null,
        duration: error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 2),
      ),
    );
}
