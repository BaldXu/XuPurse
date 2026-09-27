import 'dart:async';
import 'dart:js_interop';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

/// 定时备份固定文件名（Web 端展示用；真实落盘在配置目录或 OPFS）。
const String autoBackupFileName = 'xupurse_auto_backup.json';

/// 回退存储键（localStorage；仅兼容旧版本遗留备份）。
const String _storageKey = 'auto_backup_json';

/// 已配置目录名（localStorage，展示用；句柄本体在 IndexedDB）。
const String _dirNameKey = 'auto_backup_dir_name';

/// IndexedDB：持久化 FileSystemDirectoryHandle（structured clone 原生支持）。
const String _idbName = 'xupurse_auto_backup';
const String _idbStore = 'dirs';
const String _idbKey = 'dir';

// ---------- 目录配置 ----------

/// 选择定时备份保存目录（Web 端）。
///
/// 用 File System Access API 的 showDirectoryPicker（Chrome/Edge 支持），
/// 目录句柄持久化到 IndexedDB（跨刷新保留），返回目录名供展示；
/// 用户取消返回 null；浏览器不支持抛 [UnsupportedError]。
Future<String?> configureAutoBackupDir() async {
  try {
    final handle = await _jsShowDirectoryPicker(
      <String, Object?>{'mode': 'readwrite'}.jsify()! as JSObject,
    ).toDart;
    if (handle == null) return null; // 用户取消
    final name = (handle as JSObject).name;
    await _idbSaveHandle(handle);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dirNameKey, name);
    return name;
  } catch (_) {
    throw UnsupportedError('当前浏览器不支持选择保存目录（请用 Chrome / Edge）');
  }
}

/// 清除自定义目录（删除 IndexedDB 句柄 + localStorage 目录名）。
Future<void> clearAutoBackupDir() async {
  await _idbDeleteHandle();
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_dirNameKey);
}

// ---------- 读写（配置目录 → OPFS → localStorage 兼容兜底） ----------

/// 保存定时备份：优先写配置目录（权限仍在时），否则写浏览器私有文件系统
/// OPFS（无容量限制），OPFS 不可用时最后兜底 localStorage。
Future<String> saveAutoBackup(String content, {String? dir}) async {
  final handle = await _idbLoadHandle();
  if (handle != null && await _hasWritePermission(handle)) {
    try {
      await _writeToDir(handle, content);
      return '已保存到目录「${handle.name}」';
    } catch (_) {
      // 目录被删 / 权限失效等 → 继续回退
    }
  }
  try {
    await _writeToOpfs(content);
    // OPFS 写入成功后，清理旧版本遗留的 localStorage 大备份，释放空间。
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_storageKey)) {
      await prefs.remove(_storageKey);
    }
    return '浏览器私有文件系统（OPFS）';
  } catch (e) {
    // OPFS 不可用（隐私模式 / 非安全上下文）→ 最后兜底 localStorage
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.setString(_storageKey, content);
      return '浏览器本地存储（localStorage）';
    } catch (_) {
      throw Exception('写入浏览器文件系统失败：$e');
    }
  }
}

/// 读取上次定时备份内容；不存在返回 null。优先级同 [saveAutoBackup]。
Future<String?> readAutoBackup({String? dir}) async {
  final handle = await _idbLoadHandle();
  if (handle != null && await _hasWritePermission(handle)) {
    try {
      final text = await _readFromDir(handle);
      if (text != null) return text;
    } catch (_) {
      // 文件不存在等 → 继续回退
    }
  }
  try {
    final text = await _readFromOpfs();
    if (text != null) return text;
  } catch (_) {
    // OPFS 不可用 → 兼容读旧版本 localStorage 备份
  }
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_storageKey);
}

/// 定时备份保存位置（展示用）。[dir] = 配置的目录名。
Future<String> autoBackupLocation({String? dir}) async {
  if (dir != null && dir.isNotEmpty) return '目录「$dir」';
  return '浏览器私有文件系统（OPFS）';
}

// ---------- OPFS（浏览器私有文件系统，无容量限制） ----------

Future<void> _writeToOpfs(String content) async {
  final root = await web.window.navigator.storage.getDirectory().toDart;
  final file = await root
      .getFileHandle(
        autoBackupFileName,
        web.FileSystemGetFileOptions(create: true),
      )
      .toDart;
  final writable = await file.createWritable().toDart;
  await writable.write(content.toJS).toDart;
  await writable.close().toDart;
}

Future<String?> _readFromOpfs() async {
  final root = await web.window.navigator.storage.getDirectory().toDart;
  final file = await root.getFileHandle(autoBackupFileName).toDart;
  final text = await file.text().toDart;
  return text.toDart;
}

// ---------- File System Access API ----------

@JS('showDirectoryPicker')
external JSPromise<JSAny?> _jsShowDirectoryPicker(JSObject options);

extension _FsDirectoryHandle on JSObject {
  @JS('name')
  external String get name;

  @JS('queryPermission')
  external JSPromise<JSString> queryPermission(JSObject descriptor);

  @JS('getFileHandle')
  external JSPromise<JSObject?> getFileHandle(String name, [JSObject? options]);
}

extension _FsFileHandle on JSObject {
  @JS('createWritable')
  external JSPromise<JSAny?> createWritable();

  @JS('text')
  external JSPromise<JSString> text();
}

extension _FsWritableStream on JSObject {
  @JS('write')
  external JSPromise<JSAny?> write(JSAny data);

  @JS('close')
  external JSPromise<JSAny?> close();
}

Future<bool> _hasWritePermission(JSObject handle) async {
  try {
    final state = await handle
        .queryPermission(
          <String, Object?>{'mode': 'readwrite'}.jsify()! as JSObject,
        )
        .toDart;
    return state.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

Future<void> _writeToDir(JSObject handle, String content) async {
  final file = await handle
      .getFileHandle(
        autoBackupFileName,
        <String, Object?>{'create': true}.jsify()! as JSObject,
      )
      .toDart;
  if (file == null) throw Exception('无法创建备份文件');
  final writable = (await file.createWritable().toDart) as JSObject;
  await writable.write(content.toJS).toDart;
  await writable.close().toDart;
}

Future<String?> _readFromDir(JSObject handle) async {
  final file = await handle.getFileHandle(autoBackupFileName).toDart;
  if (file == null) return null;
  final text = await file.text().toDart;
  return text.toDart;
}

// ---------- IndexedDB（持久化目录句柄，最小 interop） ----------

@JS('indexedDB')
external JSObject get _indexedDB;

extension _IdbFactory on JSObject {
  @JS('open')
  external JSObject open(String name, [int? version]);
}

extension _IdbRequest on JSObject {
  external JSAny? get result;

  external set onsuccess(JSFunction? v);

  external set onerror(JSFunction? v);

  external set onupgradeneeded(JSFunction? v);
}

extension _IdbDatabase on JSObject {
  @JS('objectStoreNames')
  external JSObject get objectStoreNames;

  @JS('createObjectStore')
  external JSObject createObjectStore(String name);

  @JS('transaction')
  external JSObject transaction(JSAny storeNames, [JSAny? mode]);
}

extension _IdbDomStringList on JSObject {
  @JS('contains')
  external bool contains(String name);
}

extension _IdbTransaction on JSObject {
  @JS('objectStore')
  external JSObject objectStore(String name);
}

extension _IdbObjectStore on JSObject {
  @JS('put')
  external JSObject put(JSAny value, [JSAny? key]);

  @JS('get')
  external JSObject get(JSAny key);

  @JS('delete')
  external JSObject delete(JSAny key);
}

/// 把 IDBRequest 事件回调转 Future（只关心成功/失败，不取 result——
/// put/delete 的 result 是 key 字符串、get 的 result 可能是句柄或 undefined，
/// 类型不一，不能统一强转；需要 result 的场景单独读 request.result）。
Future<void> _idbRequestFuture(JSObject request) {
  final completer = Completer<void>();
  request.onsuccess = ((JSAny _) {
    completer.complete();
  }).toJS;
  request.onerror = ((JSAny _) {
    completer.completeError(Exception('IndexedDB 操作失败'));
  }).toJS;
  return completer.future;
}

Future<JSObject> _idbOpen() async {
  final req = _indexedDB.open(_idbName, 1);
  req.onupgradeneeded = ((JSAny _) {
    try {
      // onupgradeneeded 时 result 必为数据库实例。
      final db = req.result as JSObject;
      if (!db.objectStoreNames.contains(_idbStore)) {
        db.createObjectStore(_idbStore);
      }
    } catch (e) {
      // ignore: avoid_print
      print('IDB onupgradeneeded error: $e');
    }
  }).toJS;
  await _idbRequestFuture(req);
  return req.result as JSObject;
}

Future<void> _idbSaveHandle(JSObject handle) async {
  final db = await _idbOpen();
  final tx = db.transaction(_idbStore.toJS, 'readwrite'.toJS);
  final store = tx.objectStore(_idbStore);
  await _idbRequestFuture(store.put(handle, _idbKey.toJS));
}

Future<JSObject?> _idbLoadHandle() async {
  try {
    final db = await _idbOpen();
    final tx = db.transaction(_idbStore.toJS, 'readonly'.toJS);
    final store = tx.objectStore(_idbStore);
    final req = store.get(_idbKey.toJS);
    await _idbRequestFuture(req);
    final r = req.result;
    if (r == null || r.isUndefinedOrNull) return null;
    return r as JSObject;
  } catch (_) {
    return null;
  }
}

Future<void> _idbDeleteHandle() async {
  try {
    final db = await _idbOpen();
    final tx = db.transaction(_idbStore.toJS, 'readwrite'.toJS);
    final store = tx.objectStore(_idbStore);
    await _idbRequestFuture(store.delete(_idbKey.toJS));
  } catch (_) {
    // 无句柄可删
  }
}
