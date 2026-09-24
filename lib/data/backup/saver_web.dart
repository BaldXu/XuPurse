import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

/// Web 端无目录选择能力：选择目录时直接返回固定标记，页面据此展示为
/// 「复制到剪贴板」，并放行备份按钮。
const String kWebClipboardLocation = 'web://clipboard';

/// 选择备份保存位置（Web 端 v1 兜底）：返回固定标记表示进入剪贴板模式。
Future<String?> pickBackupDirectory() async => kWebClipboardLocation;

/// 保存备份文件（Web 端 v1 兜底）：把 JSON 复制到剪贴板（避免依赖 dart:html）。
Future<String> saveBackupTo(
  String directory,
  String fileName,
  String content,
) async {
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
