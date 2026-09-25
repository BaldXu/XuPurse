import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// 保存备份文件（Web 端 v1 兜底）：把 JSON 复制到剪贴板（避免依赖 dart:html）。
/// 返回展示文案。
Future<String?> saveBackupTo(String fileName, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  return '已复制到剪贴板（$fileName）';
}

/// 选择备份文件并读取内容（Web 端）：FilePicker 返回字节，utf8 解码。
Future<({String name, String content})?> pickBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: '选择备份文件',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;
  final f = result.files.single;
  final bytes = f.bytes;
  if (bytes == null) return null;
  return (name: f.name, content: utf8.decode(bytes));
}
