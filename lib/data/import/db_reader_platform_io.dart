import 'dart:typed_data';

import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as ffi;
import 'package:typed_data/typed_buffers.dart' show Uint8Buffer;

import '../../core/utils/ids.dart';

/// Native（FFI）实现：直接用 dart:ffi 的全局 sqlite3 实例打开内存库。
Future<CommonDatabase> openDatabaseFromBytes(Uint8List bytes) async {
  final vfs = ffi.InMemoryFileSystem(
    name: 'xupurse_import_${nowMs()}_${genId().hashCode.abs()}',
  );
  final path = '/import.db';
  vfs.fileData[path] = Uint8Buffer()..addAll(bytes);
  ffi.sqlite3.registerVirtualFileSystem(vfs);
  return ffi.sqlite3.open(path, vfs: vfs.name);
}
