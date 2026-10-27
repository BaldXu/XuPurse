import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'public_backup_store_io.dart';

export 'public_backup_store_io.dart'
    show PublicBackupEntry, isTreeUri, treeDirLabel, usesPublicBackupDir;

/// 旧版定时备份的固定文件名（仅用于兼容读取历史备份）。
const String autoBackupFileName = 'xupurse_auto_backup.json';

/// 定时备份文件名前缀：`xupurse_auto_20261023_004512.json`。
const String autoBackupPrefix = 'xupurse_auto_';

/// 保留的定时备份份数（超出后删最旧的）。
const int autoBackupKeep = 5;

bool _isAutoBackupName(String name) =>
    name.startsWith(autoBackupPrefix) && name.endsWith('.json');

String _two(int v) => v.toString().padLeft(2, '0');

String _stamp(DateTime t) =>
    '${t.year}${_two(t.month)}${_two(t.day)}_'
    '${_two(t.hour)}${_two(t.minute)}${_two(t.second)}';

/// 保存定时备份。
///
/// - Android + 已自选目录（SAF 树 URI）：写该目录；失败（SD 卡拔出 / 授权失效）
///   自动退回默认公共目录，保证这次备份不丢。
/// - Android 默认：公共目录 `Download/XuPurse/`，免运行时权限、卸载不删。
/// - 桌面：优先写配置目录 [dir]，否则应用文档目录（固定文件名覆盖）。
///
/// 文件名带时间戳，只保留最近 [autoBackupKeep] 份。返回展示路径。
Future<String> saveAutoBackup(String content, {String? dir}) async {
  final custom = (dir != null && dir.isNotEmpty) ? dir : null;
  if (usesPublicBackupDir) {
    final name = '$autoBackupPrefix${_stamp(DateTime.now())}.json';
    if (isTreeUri(custom)) {
      try {
        await saveTreeBackup(custom!, name, content);
        await _rotateTreeBackups(custom);
        return '${treeDirLabel(custom)}/$name';
      } catch (_) {
        // 授权失效或介质不可用：退回默认位置，绝不静默丢这次备份
      }
    }
    final path = await savePublicBackup(name, content);
    await _rotatePublicBackups();
    return path;
  }
  final target = await _targetDir(custom);
  final file = File(
    '${target.path}${Platform.pathSeparator}$autoBackupFileName',
  );
  await file.writeAsString(content, flush: true);
  return file.path;
}

/// 读取最近一次定时备份内容；不存在返回 null。
Future<String?> readAutoBackup({String? dir}) async {
  final custom = (dir != null && dir.isNotEmpty) ? dir : null;
  if (usesPublicBackupDir) {
    if (isTreeUri(custom)) {
      try {
        for (final entry in await listTreeBackups(custom!)) {
          if (!_isAutoBackupName(entry.name)) continue;
          final content = await readTreeBackup(custom, entry.name);
          if (content != null && content.isNotEmpty) return content;
        }
      } catch (_) {
        // 落到默认位置继续找
      }
    }
    for (final entry in await listAutoBackups()) {
      final content = await readPublicBackup(entry.name);
      if (content != null && content.isNotEmpty) return content;
    }
    return null;
  }
  final target = await _targetDir(custom);
  final file = File(
    '${target.path}${Platform.pathSeparator}$autoBackupFileName',
  );
  if (!await file.exists()) return null;
  return file.readAsString();
}

/// 列出默认公共目录里的定时备份（新的在前）；桌面返回空。
Future<List<PublicBackupEntry>> listAutoBackups() async {
  if (!usesPublicBackupDir || !await _hasPublicDir()) {
    return const <PublicBackupEntry>[];
  }
  final entries = await listPublicBackups();
  final list = entries.where((e) => _isAutoBackupName(e.name)).toList()
    ..sort((a, b) => b.name.compareTo(a.name)); // 文件名含时间戳，倒序即最新在前
  return list;
}

/// 列出当前配置目录里的定时备份（新的在前）：自选目录优先，否则默认公共目录。
Future<List<PublicBackupEntry>> listAutoBackupsIn({String? dir}) async {
  final custom = (dir != null && dir.isNotEmpty) ? dir : null;
  if (!usesPublicBackupDir) return const <PublicBackupEntry>[];
  if (isTreeUri(custom)) {
    try {
      final list = (await listTreeBackups(custom!))
          .where((e) => _isAutoBackupName(e.name))
          .toList()
        ..sort((a, b) => b.name.compareTo(a.name));
      if (list.isNotEmpty) return list;
    } catch (_) {
      // 退回默认目录
    }
  }
  return listAutoBackups();
}

/// 定时备份保存位置（展示用）。
Future<String> autoBackupLocation({String? dir}) async {
  final custom = (dir != null && dir.isNotEmpty) ? dir : null;
  if (usesPublicBackupDir) {
    if (isTreeUri(custom)) return treeDirLabel(custom!);
    return publicBackupLocation();
  }
  final target = await _targetDir(custom);
  return '${target.path}${Platform.pathSeparator}$autoBackupFileName';
}

/// 选择定时备份保存目录（IO 平台）。
///
/// - Android：弹 SAF 目录选择器，返回可持久化的树 URI（`content://...`），
///   之后读写都按该目录进行；分区存储下这是唯一能写任意路径的合规方式。
/// - Windows/macOS/Linux：系统目录选择器，返回普通路径。
/// - 用户取消返回 null。
Future<String?> configureAutoBackupDir() async {
  if (usesPublicBackupDir) {
    return pickBackupTreeDir();
  }
  final picked = await FilePicker.platform.getDirectoryPath(
    dialogTitle: '选择定时备份保存目录',
  );
  if (picked == null || picked.isEmpty) return null;
  if (picked.startsWith('content://')) {
    throw UnsupportedError('该平台暂不支持自定义目录，请使用默认位置');
  }
  return picked;
}

/// 清除自定义目录（恢复默认位置）。
Future<void> clearAutoBackupDir() async {}

/// 轮换：按文件名（时间戳）保留最新 [autoBackupKeep] 份（默认公共目录）。
Future<void> _rotatePublicBackups() async {
  final names = (await listAutoBackups())
      .map((e) => e.name)
      .toList(growable: false);
  if (names.length <= autoBackupKeep) return;
  for (final name in names.skip(autoBackupKeep)) {
    await deletePublicBackup(name);
  }
}

/// 轮换：自选目录里同样只保留最新 [autoBackupKeep] 份。
Future<void> _rotateTreeBackups(String tree) async {
  final names = (await listTreeBackups(tree))
      .map((e) => e.name)
      .where(_isAutoBackupName)
      .toList()
    ..sort((a, b) => b.compareTo(a));
  if (names.length <= autoBackupKeep) return;
  for (final name in names.skip(autoBackupKeep)) {
    await deleteTreeBackup(tree, name);
  }
}

/// Android 默认公共目录是否可用（读一次列表即知，失败当不可用）。
Future<bool> _hasPublicDir() async {
  try {
    await listPublicBackups();
    return true;
  } catch (_) {
    return false;
  }
}

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
