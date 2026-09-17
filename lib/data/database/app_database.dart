import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// 账本库：一个账本 = 一个独立数据库 `book-<id>`。
/// 包含账本内全部业务数据。
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Tags,
    TagGroups,
    Bills,
    BillTags,
    BalanceSnapshots,
    Transfers,
    Lends,
    Refunds,
    Reimbursements,
    Instalments,
    Budgets,
    ImportMappings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 生产环境：按账本 ID 建连（Web 端自动走 WASM/IndexedDB）。
  factory AppDatabase.forBook(String bookId) =>
      AppDatabase(driftDatabase(name: 'book-$bookId'));

  /// 测试环境：内存数据库。
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  /// 清空数据库：删除全部用户表并重置 schema 版本，下次打开时自动重建。
  ///
  /// 相比直接删除数据库文件，这种方式在 Native 与 Web（OPFS/IndexedDB）上
  /// 行为一致，用于「删除账本」场景。
  Future<void> wipe() async {
    final rows = await customSelect(
      "SELECT name, type FROM sqlite_master "
      "WHERE type IN ('table', 'view', 'trigger') AND name NOT LIKE 'sqlite_%'",
    ).get();
    for (final row in rows) {
      final name = row.data['name'] as String;
      final type = row.data['type'] as String;
      await customStatement('DROP ${type.toUpperCase()} IF EXISTS "$name"');
    }
    // 重置版本号，确保下次打开触发 onCreate 重建全部表结构。
    await customStatement('PRAGMA user_version = 0');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // 增量迁移：结构变更一律走 migration，禁止删库重建。
    },
  );
}
