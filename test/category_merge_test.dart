import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/core/errors.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/domain/services/category_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseManager mgr;
  late CategoryService service;

  setUp(() async {
    mgr = DatabaseManager.inMemory();
    await mgr.createBook(name: '测试账本');
    service = CategoryService(mgr.current);
    await mgr.current.delete(mgr.current.categories).go();
  });

  Future<void> insertCategory(
    String id,
    String name, {
    String? parentId,
    String type = 'expense',
    String icon = 'bookmark',
    String color = '#5470C6',
    bool defaultSelect = false,
  }) async {
    final db = mgr.current;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            type: type,
            name: name,
            icon: Value(icon),
            color: Value(color),
            parentId: Value(parentId),
            customName: const Value(true),
            defaultSelect: Value(defaultSelect),
            sort: const Value(0),
            seedKey: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> insertBill(String id, String categoryId) async {
    final db = mgr.current;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            id: id,
            type: BillType.expense.name,
            categoryId: categoryId,
            amount: 10000,
            time: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  test('合并到保留分类：子分类记录一并合并，被合并分类删除，目标改名换图标', () async {
    // 餐饮(parent) / 早餐(child) / 交通(parent) / 打车(child)
    await insertCategory('food', '餐饮');
    await insertCategory('breakfast', '早餐', parentId: 'food');
    await insertCategory('transport', '交通');
    await insertCategory('taxi', '打车', parentId: 'transport');

    await insertBill('b1', 'breakfast');
    await insertBill('b2', 'taxi');
    await insertBill('b3', 'transport');

    final targetId = await service.mergeCategories(
      type: BillType.expense,
      selectedIds: ['food', 'transport'],
      targetId: 'food',
      name: '餐饮',
      icon: 'restaurant',
    );

    expect(targetId, 'food');
    final db = mgr.current;
    final cats = await db.select(db.categories).get();
    expect(cats.map((c) => c.id).toSet(), {
      'food',
      'breakfast',
    }, reason: '交通/打车被删除，目标餐饮保留其子分类');
    expect(cats.firstWhere((c) => c.id == 'food').icon, 'restaurant');

    final bills = await db.select(db.bills).get();
    final byId = {for (final b in bills) b.id: b.categoryId};
    expect(byId['b1'], 'breakfast', reason: '目标分类的子分类保留原状');
    expect(byId['b2'], 'food', reason: '被合并分类的子分类记录重定向到目标');
    expect(byId['b3'], 'food', reason: '被合并分类的账单重定向到目标');
  });

  test('输入新名称 → 新建分类，所有选中分类及其子分类合并进去', () async {
    await insertCategory('food', '餐饮');
    await insertCategory('breakfast', '早餐', parentId: 'food');
    await insertCategory('transport', '交通');

    await insertBill('b1', 'breakfast');
    await insertBill('b2', 'transport');

    final targetId = await service.mergeCategories(
      type: BillType.expense,
      selectedIds: ['food', 'transport'],
      name: '吃喝出行',
      icon: 'home',
    );

    final db = mgr.current;
    final cats = await db.select(db.categories).get();
    expect(cats.length, 1, reason: '原有分类全部合并，只剩新建目标');
    expect(cats.single.id, targetId);
    expect(cats.single.name, '吃喝出行');
    expect(cats.single.icon, 'home');
    expect(cats.single.parentId, isNull);

    final bills = await db.select(db.bills).get();
    for (final b in bills) {
      expect(b.categoryId, targetId);
    }
  });

  test('保留子分类为目标、父分类被合并 → 目标提升为一级分类', () async {
    await insertCategory('food', '餐饮');
    await insertCategory('breakfast', '早餐', parentId: 'food');
    await insertCategory('transport', '交通');

    await insertBill('b1', 'breakfast');
    await insertBill('b2', 'food');
    await insertBill('b3', 'transport');

    final targetId = await service.mergeCategories(
      type: BillType.expense,
      selectedIds: ['food', 'breakfast', 'transport'],
      targetId: 'breakfast',
      name: '早餐',
      icon: 'bakery_dining',
    );

    expect(targetId, 'breakfast');
    final db = mgr.current;
    final cats = await db.select(db.categories).get();
    expect(cats.length, 1, reason: '父分类与其他分类被合并，只剩目标');
    expect(cats.single.id, 'breakfast');
    expect(cats.single.parentId, isNull, reason: '父分类被合并后目标提升为一级分类');
    expect(cats.single.icon, 'bakery_dining');

    final bills = await db.select(db.bills).get();
    for (final b in bills) {
      expect(b.categoryId, 'breakfast');
    }
  });

  test('预算与导入映射引用重定向', () async {
    await insertCategory('food', '餐饮');
    await insertCategory('transport', '交通');

    final db = mgr.current;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: 'bd1',
            name: '餐饮预算',
            categoryId: Value('transport'),
            type: BillType.expense.name,
            periodType: 'month',
            amount: 100000,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.importMappings)
        .insert(
          ImportMappingsCompanion.insert(
            id: 'm1',
            provider: 'yimu',
            entityType: 'category',
            sourceId: '7',
            targetId: 'transport',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await service.mergeCategories(
      type: BillType.expense,
      selectedIds: ['food', 'transport'],
      targetId: 'food',
      name: '餐饮',
      icon: 'restaurant',
    );

    final budget = await db.select(db.budgets).getSingle();
    expect(budget.categoryId, 'food');
    final mapping = await db.select(db.importMappings).getSingle();
    expect(mapping.targetId, 'food');
  });

  test('校验：少于两个分类 / 目标非所选 / 名称为空', () async {
    await insertCategory('food', '餐饮');
    await insertCategory('transport', '交通');

    await expectLater(
      service.mergeCategories(
        type: BillType.expense,
        selectedIds: ['food'],
        name: '餐饮',
        icon: 'restaurant',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      service.mergeCategories(
        type: BillType.expense,
        selectedIds: ['food', 'transport'],
        targetId: 'nonexistent',
        name: '餐饮',
        icon: 'restaurant',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      service.mergeCategories(
        type: BillType.expense,
        selectedIds: ['food', 'transport'],
        name: '   ',
        icon: 'restaurant',
      ),
      throwsA(isA<AppException>()),
    );
  });
}
