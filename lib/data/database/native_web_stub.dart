import 'package:drift/drift.dart';

/// Web 端占位：`drift/native.dart` 的 FFI 版本在 web 编译会失败，
/// 而 `NativeDatabase.memory()` 仅测试使用（测试跑在 VM 上，不会走本文件）。
/// 用本 stub 让 web 编译通过，运行时不使用。
abstract final class NativeDatabase {
  static QueryExecutor memory() =>
      throw UnsupportedError('NativeDatabase is not available on web');
}
