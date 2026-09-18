import 'package:flutter_test/flutter_test.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/data/database/global_database.dart';
import 'package:xupurse/data/seed/default_categories.dart';

void main() {
  late DatabaseManager manager;

  setUp(() {
    manager = DatabaseManager.inMemory();
  });

  tearDown(() async {
    await manager.dispose();
  });

  group('createBook 建库与种子', () {
    test('创建账本并登记到全局库', () async {
      final bookId = await manager.createBook(name: '测试账本');
      expect(bookId, isNotEmpty);

      final globalDb = await manager.global();
      final books = await globalDb.select(globalDb.books).get();
      expect(books, hasLength(1));
      expect(books.single.name, '测试账本');
      expect(books.single.baseCurrency, 'CNY');
    });

    test('种子分类完整写入', () async {
      final bookId = await manager.createBook(name: '种子');
      final db = await manager.openBook(bookId);
      final categories = await db.select(db.categories).get();
      expect(
        categories.map((c) => c.seedKey),
        containsAll(['shopping', 'food', 'wage']),
      );
      // 不含父级 key 的数量与种子一致
      expect(categories.length, allSeedCategories.length);
    });

    test('种子账户写入 4 个默认账户', () async {
      final bookId = await manager.createBook(name: '账户种子');
      final db = await manager.openBook(bookId);
      final accounts = await db.select(db.accounts).get();
      expect(
        accounts.map((a) => a.name),
        containsAll(['支付宝', '微信支付', '现金', '银行卡']),
      );
      expect(accounts.every((a) => a.category == 'fund'), isTrue);
    });

    test('种子幂等：重复 seedBook 不产生重复数据', () async {
      final bookId = await manager.createBook(name: '幂等');
      final db = await manager.openBook(bookId);
      await manager.seedBook(db);
      final categories = await db.select(db.categories).get();
      expect(categories.length, allSeedCategories.length);
    });

    test('父子关系正确建立', () async {
      final bookId = await manager.createBook(name: '父子');
      final db = await manager.openBook(bookId);
      final all = await db.select(db.categories).get();
      final byKey = {
        for (final c in all)
          if (c.seedKey != null) c.seedKey!: c,
      };
      final clothing = byKey['clothing']!;
      final shopping = byKey['shopping']!;
      expect(clothing.parentId, shopping.id);
      expect(shopping.parentId, isNull);
    });

    test('updateBookBaseCurrency 修改本位币', () async {
      final bookId = await manager.createBook(name: '本位币');
      expect((await _bookOf(manager, bookId)).baseCurrency, 'CNY');

      await manager.updateBookBaseCurrency(bookId, 'USD');

      expect((await _bookOf(manager, bookId)).baseCurrency, 'USD');
    });
  });

  group('多账本隔离', () {
    test('两个账本数据互不可见', () async {
      final bookA = await manager.createBook(name: 'A');
      final bookB = await manager.createBook(name: 'B');
      final dbA = await manager.openBook(bookA);
      final dbB = await manager.openBook(bookB);

      final now = DateTime.now().millisecondsSinceEpoch;
      await dbA
          .into(dbA.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'acc-a-only',
              name: 'A 专属账户',
              category: 'fund',
              type: 'cash',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final namesA = (await dbA.select(dbA.accounts).get()).map((a) => a.name);
      final namesB = (await dbB.select(dbB.accounts).get()).map((a) => a.name);
      expect(namesA, contains('A 专属账户'));
      expect(namesB, isNot(contains('A 专属账户')));
    });

    test('openBook 复用同一实例', () async {
      final bookId = await manager.createBook(name: '复用');
      final db1 = await manager.openBook(bookId);
      final db2 = await manager.openBook(bookId);
      expect(identical(db1, db2), isTrue);
    });

    test('deleteBook 级联清理', () async {
      final bookId = await manager.createBook(name: '待删除');
      var db = await manager.openBook(bookId);
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'acc-x',
              name: '临时账户',
              category: 'fund',
              type: 'cash',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await manager.deleteBook(bookId);

      final globalDb = await manager.global();
      final books = await globalDb.select(globalDb.books).get();
      expect(books, isEmpty);

      // 重新打开同名 ID 的库：表已重建且无数据
      db = await manager.openBook(bookId);
      final accounts = await db.select(db.accounts).get();
      final categories = await db.select(db.categories).get();
      expect(accounts, isEmpty);
      // wipe 后重开触发 onCreate，不会自动种子（种子由 createBook 显式触发）
      expect(categories, isEmpty);
    });
  });
}

/// 取全局库中指定账本记录。
Future<Book> _bookOf(DatabaseManager manager, String bookId) async {
  final globalDb = await manager.global();
  return (globalDb.select(
    globalDb.books,
  )..where((t) => t.id.equals(bookId))).getSingle();
}
