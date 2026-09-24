import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// 选择备份保存目录（IO 平台：系统目录选择器 / SAF）。
/// 返回目录路径；用户取消返回 null。
Future<String?> pickBackupDirectory() async {
  return FilePicker.platform.getDirectoryPath(dialogTitle: '选择备份保存位置');
}

/// 写入备份文件到指定目录，返回完整保存路径。
Future<String> saveBackupTo(
  String directory,
  String fileName,
  String content,
) async {
  final dir = Directory(directory);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(content);
  return file.path;
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
