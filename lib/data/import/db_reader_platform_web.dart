import 'dart:typed_data';

import 'package:sqlite3/common.dart';
import 'package:sqlite3/wasm.dart' as wasm;
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;

import '../../core/utils/ids.dart';

/// Web（WASM）实现：加载 sqlite3.wasm 后以内存文件系统方式打开。
///
/// 首次调用会异步 fetch `web/sqlite3.wasm`（已随工程放入 web/ 目录）。
/// WASM 模块只加载一次，后续复用。
Future<CommonDatabase> openDatabaseFromBytes(Uint8List bytes) async {
  final sqlite3 = await _ensureWasm();
  final vfs = wasm.InMemoryFileSystem(
    name: 'xupurse_import_${nowMs()}_${genId().hashCode.abs()}',
  );
  final path = '/import.db';
  vfs.fileData[path] = Uint8Buffer()..addAll(bytes);
  sqlite3.registerVirtualFileSystem(vfs);
  return sqlite3.open(path, vfs: vfs.name);
}

wasm.WasmSqlite3? _instance;

Future<wasm.WasmSqlite3> _ensureWasm() async {
  if (_instance != null) return _instance!;
  final loaded = await wasm.WasmSqlite3.loadFromUrl(
    Uri.parse('sqlite3.wasm'),
  );
  _instance = loaded;
  return loaded;
}
