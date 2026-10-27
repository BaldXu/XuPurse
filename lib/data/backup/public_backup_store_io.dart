import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

/// 定时备份写公共目录的通道名（Android 原生实现见 MainActivity.kt）。
const String publicBackupChannel = 'xupurse/public_backup';

const MethodChannel _channel = MethodChannel(publicBackupChannel);

/// Android 上是否把定时备份写到系统公共目录。
///
/// 应用私有目录（app_flutter）会随卸载一起被删除，定时备份放那里等于没有备份，
/// 因此 Android 一律写到公共的 Download/XuPurse/。
bool get usesPublicBackupDir =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// 公共目录里的一个备份文件。
class PublicBackupEntry {
  const PublicBackupEntry({
    required this.name,
    required this.size,
    required this.modified,
  });

  final String name;
  final int size;
  final int modified;
}

/// 写入公共目录（同名覆盖）；返回展示路径（如 `Download/XuPurse/x.json`）。
Future<String> savePublicBackup(String name, String content) async {
  final path = await _channel.invokeMethod<String>('save', {
    'name': name,
    'content': content,
  });
  return path ?? 'Download/XuPurse/$name';
}

/// 读取公共目录里的指定文件；不存在返回 null。
Future<String?> readPublicBackup(String name) async {
  try {
    return await _channel.invokeMethod<String>('read', {'name': name});
  } on PlatformException {
    return null;
  }
}

/// 列出公共目录里的全部文件。
Future<List<PublicBackupEntry>> listPublicBackups() async {
  try {
    final raw = await _channel.invokeListMethod<dynamic>('list') ?? const [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(
          (m) => PublicBackupEntry(
            name: (m['name'] as String?) ?? '',
            size: (m['size'] as num?)?.toInt() ?? 0,
            modified: (m['modified'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((e) => e.name.isNotEmpty)
        .toList(growable: false);
  } on PlatformException {
    return const [];
  }
}

/// 删除公共目录里的指定文件。
Future<bool> deletePublicBackup(String name) async {
  try {
    return await _channel.invokeMethod<bool>('delete', {'name': name}) ?? false;
  } on PlatformException {
    return false;
  }
}

/// 公共目录的展示路径。
Future<String> publicBackupLocation() async {
  try {
    return await _channel.invokeMethod<String>('location') ?? 'Download/XuPurse/';
  } on PlatformException {
    return 'Download/XuPurse/';
  }
}

// —— 自选目录（SAF 树 URI） ——

/// 是否是 SAF 树 URI（用户自选目录）。
bool isTreeUri(String? dir) => dir != null && dir.startsWith('content://');

/// 弹系统目录选择器，返回可持久化的树 URI；用户取消返回 null。
Future<String?> pickBackupTreeDir() async {
  return _channel.invokeMethod<String>('pickTree');
}

/// 树 URI 转人话：`primary:1111/记账/xupurse` → `内部存储/1111/记账/xupurse`；
/// SD 卡卷（如 `1A2B-3C4D:记账`）→ `存储卡 1A2B-3C4D/记账`。
String treeDirLabel(String tree) {
  String id;
  try {
    // pathSegments 已自动百分号解码，别再 decodeComponent（会把 % 当非法转义抛错）
    id = Uri.parse(tree).pathSegments.last;
  } catch (_) {
    try {
      id = Uri.decodeComponent(tree.split('/').last);
    } catch (_) {
      return '已选目录';
    }
  }
  final colon = id.indexOf(':');
  if (colon < 0) return id.isEmpty ? '已选目录' : id;
  final volume = id.substring(0, colon);
  final rest = id.substring(colon + 1);
  final root = volume == 'primary' ? '内部存储' : '存储卡 $volume';
  return rest.isEmpty ? root : '$root/$rest';
}

/// 写入自选目录（同名覆盖）；返回文件名。
Future<String> saveTreeBackup(String tree, String name, String content) async {
  final saved = await _channel.invokeMethod<String>('saveTo', {
    'tree': tree,
    'name': name,
    'content': content,
  });
  return saved ?? name;
}

/// 读取自选目录里的指定文件；不存在返回 null。
Future<String?> readTreeBackup(String tree, String name) =>
    _channel.invokeMethod<String>('readFrom', {'tree': tree, 'name': name});

/// 列出指定目录/自选目录里的文件。
Future<List<PublicBackupEntry>> listTreeBackups(String tree) async {
  final raw =
      await _channel.invokeListMethod<dynamic>('listIn', {'tree': tree}) ??
      const [];
  return raw
      .whereType<Map<Object?, Object?>>()
      .map(
        (m) => PublicBackupEntry(
          name: (m['name'] as String?) ?? '',
          size: (m['size'] as num?)?.toInt() ?? 0,
          modified: (m['modified'] as num?)?.toInt() ?? 0,
        ),
      )
      .where((e) => e.name.isNotEmpty)
      .toList(growable: false);
}

/// 删除自选目录里的指定文件。
Future<bool> deleteTreeBackup(String tree, String name) async {
  try {
    return await _channel.invokeMethod<bool>('deleteIn', {
          'tree': tree,
          'name': name,
        }) ??
        false;
  } on PlatformException {
    return false;
  }
}
