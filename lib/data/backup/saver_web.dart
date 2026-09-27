import 'dart:convert';
import 'dart:js_interop';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;

/// 保存备份文件（Web 端）。
///
/// 优先用浏览器「另存为」对话框（File System Access API 的
/// `showSaveFilePicker`，Chrome/Edge 支持，需手写 JS interop）让用户
/// 选择保存位置；浏览器不支持时回退为 Blob 触发下载。
///
/// 返回展示文案；用户取消返回 null。浏览器出于安全不暴露所选路径，
/// 因此成功时返回文件名而非完整路径。
Future<String?> saveBackupTo(String fileName, String content) async {
  final viaPicker = await _trySaveViaPicker(fileName, content);
  if (viaPicker != null) return viaPicker; // 成功，或用户取消(null)
  return _downloadBlob(fileName, content);
}

/// 优先路径：showSaveFilePicker 弹「另存为」对话框。
/// 返回 null = 用户取消；返回文案 = 已写入；抛出 = 浏览器不支持 → 走下载。
Future<String?> _trySaveViaPicker(String fileName, String content) async {
  try {
    final handle = await _jsShowSaveFilePicker(_pickerOptions(fileName)).toDart;
    if (handle == null) return null; // 用户取消
    final writable =
        (await (handle as JSObject).createWritable().toDart) as JSObject;
    await writable.write(content.toJS).toDart;
    await writable.close().toDart;
    return '已保存到「$fileName」';
  } catch (_) {
    // 浏览器不支持 File System Access API（或用户拒绝权限）→ 回退下载
    return null;
  }
}

/// 回退路径：Blob + 临时 <a download> 触发浏览器下载。
String _downloadBlob(String fileName, String content) {
  final blob = web.Blob(<web.BlobPart>[content.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
  return '已触发下载（$fileName）';
}

/// 构造 showSaveFilePicker 的 options（suggestedName + types）。
JSObject _pickerOptions(String fileName) {
  return <String, Object?>{
        'suggestedName': fileName,
        'types': [
          {
            'description': 'XuPurse 备份',
            'accept': {
              'application/json': <String>['.json'],
            },
          },
        ],
      }.jsify()!
      as JSObject;
}

@JS('showSaveFilePicker')
external JSPromise<JSAny?> _jsShowSaveFilePicker(JSObject options);

extension _FileSystemFileHandle on JSObject {
  @JS('createWritable')
  external JSPromise<JSAny?> createWritable();
}

extension _FileSystemWritableFileStream on JSObject {
  @JS('write')
  external JSPromise<JSAny?> write(JSAny data);

  @JS('close')
  external JSPromise<JSAny?> close();
}

/// 选择备份文件并读取内容（Web 端）：FilePicker 返回字节，utf8 解码。
Future<({String name, String content})?> pickBackupFile() async {
  final result = await FilePicker.platform.pickFiles(
    dialogTitle: '选择备份文件',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (result == null || result.files.isEmpty) return null;
  final f = result.files.single;
  final bytes = f.bytes;
  if (bytes == null) return null;
  return (name: f.name, content: utf8.decode(bytes));
}
