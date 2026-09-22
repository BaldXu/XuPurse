import 'package:drift/drift.dart';
import 'package:drift/native.dart'
    if (dart.library.js_interop) 'native_web_stub.dart'
    show NativeDatabase;
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'global_database.g.dart';

/// 全局库 `xupurse.db`：账本列表与应用级数据。
@DriftDatabase(tables: [Books])
class GlobalDatabase extends _$GlobalDatabase {
  GlobalDatabase(super.e);

  factory GlobalDatabase.open() => GlobalDatabase(
    driftDatabase(
      name: 'xupurse',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  factory GlobalDatabase.memory() => GlobalDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
