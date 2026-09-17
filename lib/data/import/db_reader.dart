import 'dart:convert';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;

import '../../core/utils/ids.dart';

/// 打开内存中的第三方 .db 文件字节流（跨平台：Native 走 FFI，Web 走 WASM）。
///
/// 通过 sqlite3 包的 [InMemoryFileSystem] 把字节流挂载为虚拟文件后以只读方式打开，
/// 使用方读取完所有表后必须调用 [Database.dispose] 释放连接。
Database openDatabaseFromBytes(Uint8List bytes) {
  final vfs = InMemoryFileSystem(
    name: 'xupurse_import_${nowMs()}_${genId().hashCode.abs()}',
  );
  final path = '/import.db';
  vfs.fileData[path] = Uint8Buffer()..addAll(bytes);
  sqlite3.registerVirtualFileSystem(vfs);
  return sqlite3.open(path, vfs: vfs.name);
}

// ---------- 通用查询与行值安全读取（sqlite3 返回 int/double/String/Uint8List/null） ----------

/// 执行 SELECT 并返回行列表；表不存在或 SQL 失败返回空列表（防御第三方库结构差异）。
List<Map<String, Object?>> queryRows(Database db, String sql) {
  try {
    final result = db.select(sql);
    return [for (final row in result) Map<String, Object?>.from(row)];
  } catch (_) {
    return [];
  }
}

int? asInt(Object? v) => switch (v) {
  int i => i,
  double d => d.round(),
  String s => int.tryParse(s.trim()),
  _ => null,
};

double? asDouble(Object? v) => switch (v) {
  int i => i.toDouble(),
  double d => d,
  String s => double.tryParse(s.trim()),
  _ => null,
};

String asString(Object? v) => v?.toString() ?? '';

bool asBool(Object? v) => v == 1 || v == true || v == '1';

/// 安全解析 JSON 字符串为 Map；非法或空返回 {}。
Map<String, Object?> safeParseJson(Object? v) {
  if (v is! String || v.isEmpty) return {};
  try {
    final decoded = jsonDecode(v);
    if (decoded is Map) {
      return decoded.map((k, value) => MapEntry(k.toString(), value));
    }
    return {};
  } catch (_) {
    return {};
  }
}
