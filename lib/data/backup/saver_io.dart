import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 保存备份文件到应用文档目录（IO 平台），返回保存路径。
Future<String> saveBackupFile(String fileName, String content) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsString(content);
  return file.path;
}
