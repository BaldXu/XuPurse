import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 定时备份固定文件名（IO 平台）。覆盖 = 写同一个文件。
const String autoBackupFileName = 'xupurse_auto_backup.json';

/// 保存定时备份：优先写入配置目录 [dir]，否则应用文档目录。
/// 返回展示文案（完整路径）。
///
/// 应用文档目录是应用私有目录：Android/iOS 无需任何存储权限
/// （不碰公共存储，天然兼容 scoped storage）。
Future<String> saveAutoBackup(String content, {String? dir}) async {
  final target = await _targetDir(dir);
  final file = File(
    '${target.path}${Platform.pathSeparator}$autoBackupFileName',
  );
  await file.writeAsString(content, flush: true);
  return file.path;
}

/// 读取上次定时备份内容；不存在返回 null。优先配置目录 [dir]。
Future<String?> readAutoBackup({String? dir}) async {
  final target = await _targetDir(dir);
  final file = File(
    '${target.path}${Platform.pathSeparator}$autoBackupFileName',
  );
  if (!await file.exists()) return null;
  return file.readAsString();
}

/// 定时备份保存位置（展示用）。
Future<String> autoBackupLocation({String? dir}) async {
  final target = await _targetDir(dir);
  return '${target.path}${Platform.pathSeparator}$autoBackupFileName';
}

/// 选择定时备份保存目录（IO 平台）。
///
/// - Windows/macOS/Linux：系统目录选择器，返回普通路径。
/// - Android：SAF 返回 content:// 树 URI，dart:io 无法直接写入，
///   抛 [UnsupportedError] 由调用方提示使用默认位置。
/// - 用户取消返回 null。
Future<String?> configureAutoBackupDir() async {
  final picked = await FilePicker.platform.getDirectoryPath(
    dialogTitle: '选择定时备份保存目录',
  );
  if (picked == null || picked.isEmpty) return null;
  if (picked.startsWith('content://')) {
    throw UnsupportedError('该平台暂不支持自定义目录，请使用默认位置');
  }
  return picked;
}

/// 清除自定义目录（IO 平台：配置存在调用方 prefs，此处无全局状态）。
Future<void> clearAutoBackupDir() async {}

Future<Directory> _targetDir(String? dir) async {
  if (dir != null && dir.isNotEmpty) {
    final d = Directory(dir);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return d;
  }
  return getApplicationDocumentsDirectory();
}
