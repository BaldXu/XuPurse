import 'package:flutter/services.dart';

/// 保存备份文件（Web 端 v1 兜底）：把 JSON 复制到剪贴板（避免依赖 dart:html）。
Future<String> saveBackupFile(String fileName, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  return '已复制到剪贴板（$fileName）';
}
