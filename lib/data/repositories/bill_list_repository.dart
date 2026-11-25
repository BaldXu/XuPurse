import 'package:drift/drift.dart';

import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import '../../domain/services/bill_list_classifier.dart';

/// 清单列表项：清单本体 + 汇总数字（非转账账单的金额合计）。
class BillListSummary {
  const BillListSummary({
    required this.list,
    required this.count,
    required this.total,
    this.minTime,
    this.maxTime,
  });

  final BillList list;
  final int count;

  /// 万分之元；只累加非转账账单。
  final int total;

  /// 清单内最早 / 最晚账单时间（无明细时为空）。
  final int? minTime;
  final int? maxTime;
}

/// 清单内一条明细：账单 + 它在清单里的分类归属。
class BillListItemView {
  const BillListItemView({required this.bill, this.sectionId});

  final Bill bill;

  /// null = 未分类。
  final String? sectionId;
}

/// 新建清单时自动带上的分类（用户可改名 / 删除 / 新增）。
const List<String> kDefaultListSectionNames = [
  '前期准备',
  '交通',
  '住宿',
  '餐饮',
  '购物',
  '其他',
];

/// 消费清单数据访问。
///
/// 清单与账单是多对多：一笔消费可同时属于「云南旅游」和「公司报销」。
/// 合计实时从 bills 聚合，不存冗余金额；清单内分类只属于该清单。
class BillListRepository {
  BillListRepository(this._db);

  final AppDatabase _db;

  /// 清单列表 + 汇总（单条 SQL 聚合，随三张表变化自动重算）。
  Stream<List<BillListSummary>> watchSummaries() {
    final query = _db.customSelect(
      '''
SELECT l.id, l.name, l.icon, l.color, l.note,
       l.created_at, l.updated_at,
       COUNT(b.id) AS cnt,
       COALESCE(SUM(
         CASE WHEN b.type <> 'transfer'
           THEN b.amount - COALESCE(
             (SELECT SUM(r.amount) FROM refunds r WHERE r.bill_id = b.id), 0)
           ELSE 0 END
       ), 0) AS total,
       MIN(b.time) AS min_time,
       MAX(b.time) AS max_time
FROM bill_lists l
LEFT JOIN bill_list_items li ON li.list_id = l.id
LEFT JOIN bills b ON b.id = li.bill_id
GROUP BY l.id
ORDER BY l.updated_at DESC
''',
      readsFrom: {
        _db.billLists,
        _db.billListItems,
        _db.bills,
        _db.refunds,
      },
    );
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          BillListSummary(
            list: BillList(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              icon: row.readNullable<String>('icon'),
              color: row.readNullable<String>('color'),
              note: row.readNullable<String>('note'),
              createdAt: row.read<int>('created_at'),
              updatedAt: row.read<int>('updated_at'),
            ),
            count: row.read<int>('cnt'),
            total: row.read<int>('total'),
            minTime: row.readNullable<int>('min_time'),
            maxTime: row.readNullable<int>('max_time'),
          ),
      ],
    );
  }

  /// 清单内的明细（含清单内分类 id，时间倒序）。
  Stream<List<BillListItemView>> watchItems(String listId) {
    final query =
        _db.select(_db.bills).join([
            innerJoin(
              _db.billListItems,
              _db.billListItems.billId.equalsExp(_db.bills.id),
            ),
          ])
          ..where(_db.billListItems.listId.equals(listId))
          ..orderBy([
            OrderingTerm.desc(_db.bills.time),
            OrderingTerm.desc(_db.bills.createdAt),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          BillListItemView(
            bill: row.readTable(_db.bills),
            sectionId: row.readTable(_db.billListItems).sectionId,
          ),
      ],
    );
  }

  /// 清单内分类（按 sort 升序）。
  Stream<List<BillListSection>> watchSections(String listId) {
    final query = _db.select(_db.billListSections)
      ..where((t) => t.listId.equals(listId))
      ..orderBy([(t) => OrderingTerm.asc(t.sort)]);
    return query.watch();
  }

  Future<List<BillListSection>> sectionsOf(String listId) {
    final query = _db.select(_db.billListSections)
      ..where((t) => t.listId.equals(listId))
      ..orderBy([(t) => OrderingTerm.asc(t.sort)]);
    return query.get();
  }

  /// 新建清单：同时写入默认分类。
  Future<String> create({
    required String name,
    String? icon,
    String? color,
    String? note,
  }) async {
    final id = genId();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _db
          .into(_db.billLists)
          .insert(
            BillListsCompanion.insert(
              id: id,
              name: name.trim(),
              icon: Value(icon),
              color: Value(color),
              note: Value(note),
              createdAt: now,
              updatedAt: now,
            ),
          );
      var sort = 0;
      for (final sectionName in kDefaultListSectionNames) {
        await _db
            .into(_db.billListSections)
            .insert(
              BillListSectionsCompanion.insert(
                id: genId(),
                listId: id,
                name: sectionName,
                sort: Value(sort++),
                createdAt: now,
              ),
            );
      }
    });
    return id;
  }

  Future<void> delete(String listId) =>
      (_db.delete(_db.billLists)..where((t) => t.id.equals(listId))).go();

  /// 批量加入明细（已存在的自动忽略，可重复调用）。
  Future<void> addBills(String listId, Iterable<String> billIds) async {
    final ids = billIds.toSet().toList();
    if (ids.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.batch((batch) {
      batch.insertAll(
        _db.billListItems,
        [
          for (final id in ids)
            BillListItemsCompanion.insert(
              listId: listId,
              billId: id,
              addedAt: now,
            ),
        ],
        mode: InsertMode.insertOrIgnore,
      );
    });
    await _touch(listId);
  }

  /// 从清单移除一笔（只删关联，不删账单）。
  Future<void> removeBill(String listId, String billId) async {
    await (_db.delete(_db.billListItems)..where(
          (t) => t.listId.equals(listId) & t.billId.equals(billId),
        ))
        .go();
    await _touch(listId);
  }

  /// 某账本内已在清单里的账单 id（多选页用来标记已添加）。
  Future<Set<String>> billIdsOf(String listId) async {
    final rows = await (_db.select(
      _db.billListItems,
    )..where((t) => t.listId.equals(listId))).get();
    return {for (final r in rows) r.billId};
  }

  // ---------- 清单内分类 ----------

  Future<String> createSection(String listId, String name) async {
    final sections = await sectionsOf(listId);
    final nextSort = sections.isEmpty ? 0 : sections.last.sort + 1;
    final id = genId();
    await _db
        .into(_db.billListSections)
        .insert(
          BillListSectionsCompanion.insert(
            id: id,
            listId: listId,
            name: name.trim(),
            sort: Value(nextSort),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    return id;
  }

  Future<void> renameSection(String sectionId, String name) =>
      (_db.update(_db.billListSections)..where((t) => t.id.equals(sectionId)))
          .write(BillListSectionsCompanion(name: Value(name.trim())));

  /// 删除分类：其下明细回到「未分类」，账单本身不受影响。
  Future<void> deleteSection(String listId, String sectionId) async {
    await _db.transaction(() async {
      await (_db.update(_db.billListItems)..where(
            (t) => t.listId.equals(listId) & t.sectionId.equals(sectionId),
          ))
          .write(const BillListItemsCompanion(sectionId: Value(null)));
      await (_db.delete(_db.billListSections)..where(
            (t) => t.id.equals(sectionId) & t.listId.equals(listId),
          ))
          .go();
    });
  }

  /// 设置某笔明细的清单内分类（null = 未分类）。
  Future<void> setSection(
    String listId,
    String billId,
    String? sectionId,
  ) async {
    await (_db.update(_db.billListItems)..where(
          (t) => t.listId.equals(listId) & t.billId.equals(billId),
        ))
        .write(BillListItemsCompanion(sectionId: Value(sectionId)));
  }

  /// 自动分类：只处理「未分类」的明细，不覆盖用户手动设置过的。
  ///
  /// 返回 (已分类笔数, 仍未识别笔数)。规则见 [BillListItemClassifier]。
  Future<(int, int)> autoClassify(String listId) async {
    final sections = await sectionsOf(listId);
    if (sections.isEmpty) return (0, 0);
    final byName = {for (final s in sections) s.name: s.id};

    final rows = await (_db.select(_db.bills).join([
      innerJoin(
        _db.billListItems,
        _db.billListItems.billId.equalsExp(_db.bills.id),
      ),
    ])..where(_db.billListItems.listId.equals(listId))).get();

    final categories = await _db.select(_db.categories).get();
    final catName = {for (final c in categories) c.id: c.name};

    var classified = 0;
    var unmatched = 0;
    for (final row in rows) {
      final item = row.readTable(_db.billListItems);
      if (item.sectionId != null) continue;
      final bill = row.readTable(_db.bills);
      if (bill.type == 'transfer') continue;
      final guessed = BillListItemClassifier.classify(
        categoryName: catName[bill.categoryId] ?? '',
        comment: bill.comment,
      );
      final sectionId = guessed == null ? null : byName[guessed];
      if (sectionId == null) {
        unmatched++;
        continue;
      }
      await (_db.update(_db.billListItems)..where(
            (t) => t.listId.equals(listId) & t.billId.equals(bill.id),
          ))
          .write(BillListItemsCompanion(sectionId: Value(sectionId)));
      classified++;
    }
    if (classified > 0) await _touch(listId);
    return (classified, unmatched);
  }

  Future<void> _touch(String listId) async {
    await (_db.update(_db.billLists)..where((t) => t.id.equals(listId))).write(
      BillListsCompanion(
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
