import 'package:flutter/material.dart';

/// 正常 toast 底色（Material 标准中性深灰，Android/iOS 原生 toast 同款）。
/// 固定写死而不跟随主题：避免错误分支使用 errorContainer（浅粉）以及
/// 主题色漂移导致 toast 变粉/变蓝，保证全局 toast 视觉一致。
const Color _kToastBackground = Color(0xFF323232);

/// 统一 SnackBar 入口:内置 hideCurrentSnackBar 前置,消除同屏 Hero tag 冲突。
/// 页面不再直接调 ScaffoldMessenger.showSnackBar。
void showXpSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        // 固定正常 toast 样式：中性深灰底 + 白字，不随主题/error 漂移。
        backgroundColor: _kToastBackground,
        duration: error
            ? const Duration(seconds: 4)
            : const Duration(seconds: 2),
      ),
    );
}
