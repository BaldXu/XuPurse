import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// 备份保存：弹出系统「保存文件」窗口写盘。
///
/// - Android：`ACTION_CREATE_DOCUMENT`（SAF），由系统 ContentResolver 写入，
///   无需任何存储权限，天然兼容 Android 11+ scoped storage（直接用 dart:io
///   写共享目录会被系统拒绝，报 `Operation not permitted / errno=1`）。
/// - iOS：`UIDocumentPicker` 导出，同样无需权限。
///
/// 返回保存路径（展示用）；用户取消返回 null。
Future<String?> saveBackupTo(String fileName, String content) async {
  return FilePicker.platform.saveFile(
    dialogTitle: '保存备份文件',
    fileName: fileName,
    type: FileType.any,
    bytes: utf8.encode(content),
  );
}

/// 选择备份文件并读取内容（IO 平台）。返回文件名与内容；取消返回 null。
Future<({String name, String content})?> pickBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: '选择备份文件',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;
  final f = result.files.single;
  final path = f.path;
  if (path == null) return null;
  final file = File(path);
  return (name: f.name, content: await file.readAsString());
}
