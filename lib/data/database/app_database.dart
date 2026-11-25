import 'package:drift/drift.dart';
import 'package:drift/native.dart'
    if (dart.library.js_interop) 'native_web_stub.dart'
    show NativeDatabase;
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
    BillLocations,
    BillLists,
    BillListItems,
    BillListSections,
    BalanceSnapshots,
    Transfers,
    Lends,
    Refunds,
    Reimbursements,
    Instalments,
    Budgets,
    ImportMappings,
    YearReports,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// 生产环境：按账本 ID 建连（Web 端自动走 WASM/IndexedDB）。
  factory AppDatabase.forBook(String bookId) => AppDatabase(
    driftDatabase(
      name: 'book-$bookId',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  /// 测试环境：内存数据库。
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 6;

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
    // 账单删除时级联清理位置行；每个连接都要显式开启。
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      // 增量迁移：结构变更一律走 migration，禁止删库重建。
      if (from < 2) {
        // v2：新增年度报告汇总缓存表（纯派生数据，可随时全量重算）。
        await m.createTable(yearReports);
      }
      if (from < 3) {
        // v3：新增账单位置表；把历史 bills.location_lat/lng 回填进来
        // （导入数据可能带坐标，不能在新功能上线后丢失）。
        await m.createTable(billLocations);
        await customStatement(
          "INSERT OR IGNORE INTO bill_locations "
          "(bill_id, lat, lng, coord_system, source, captured_at) "
          "SELECT id, location_lat, location_lng, 'wgs84', 'import', "
          "COALESCE(created_at, 0) FROM bills "
          "WHERE location_lat IS NOT NULL AND location_lng IS NOT NULL",
        );
      }
      if (from < 4) {
        // v4：消费清单（事件账本）+ 清单与明细的多对多关联。
        await m.createTable(billLists);
        await m.createTable(billListItems);
      }
      if (from < 5) {
        // v5：清单内分类（只属于清单），明细增加分类归属列。
        await m.createTable(billListSections);
        // from < 4 分支里的 createTable(billListItems) 用的是当前 schema，
        // 已经带上 section_id；从旧版本一路升上来时这里再加会报
        // duplicate column name。先查列再决定是否补。
        final columns = await customSelect(
          'PRAGMA table_info(bill_list_items)',
        ).get();
        final hasSectionId = columns.any(
          (row) => row.read<String>('name') == 'section_id',
        );
        if (!hasSectionId) {
          await m.addColumn(billListItems, billListItems.sectionId);
        }
      }
      if (from < 6) {
        // v6：给 v5 之前已存在的清单补一套默认分类
        // （新建清单在仓库层会写入默认分类，这里只处理历史数据）。
        await customStatement('''
INSERT INTO bill_list_sections (id, list_id, name, sort, created_at)
SELECT lower(hex(randomblob(16))), l.id, n.name, n.sort,
       CAST(strftime('%s','now') AS INTEGER) * 1000
FROM bill_lists l
JOIN (
  SELECT '前期准备' AS name, 0 AS sort
  UNION ALL SELECT '交通', 1
  UNION ALL SELECT '住宿', 2
  UNION ALL SELECT '餐饮', 3
  UNION ALL SELECT '购物', 4
  UNION ALL SELECT '其他', 5
) n
WHERE NOT EXISTS (
  SELECT 1 FROM bill_list_sections s WHERE s.list_id = l.id
)
''');
      }
    },
  );
}
