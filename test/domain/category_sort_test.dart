import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/core/errors.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/domain/services/category_service.dart';

/// 分类排序（分类管理页长按拖动）：只重编号 sort、绝不改动层级 parentId。
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
    int sort = 0,
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
            icon: const Value('bookmark'),
            color: const Value('#5470C6'),
            parentId: Value(parentId),
            customName: const Value(true),
            defaultSelect: const Value(false),
            sort: Value(sort),
            seedKey: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<Category> get(String id) => (mgr.current.select(
    mgr.current.categories,
  )..where((t) => t.id.equals(id))).getSingle();

  group('CategoryService.reorderSiblings 长按拖动排序', () {
    test('一级分类重排：按落点重新编号 100/200/300，层级 parentId 不变', () async {
      await insertCategory('a', '餐饮', sort: 0);
      await insertCategory('b', '交通', sort: 260);
      await insertCategory('c', '购物', sort: 30);

      await service.reorderSiblings(
        type: BillType.expense,
        orderedIds: ['c', 'a', 'b'],
        topLevel: true,
      );

      expect((await get('c')).sort, 100);
      expect((await get('a')).sort, 200);
      expect((await get('b')).sort, 300);
      for (final id in ['a', 'b', 'c']) {
        expect((await get(id)).parentId, isNull, reason: '拖动排序不得改动层级');
      }
    });

    test('子分类重排：同一父分类下编号 1/2/3，parentId 保持', () async {
      await insertCategory('p', '餐饮');
      await insertCategory('x', '早餐', parentId: 'p', sort: 9);
      await insertCategory('y', '午餐', parentId: 'p', sort: 0);
      await insertCategory('z', '晚餐', parentId: 'p', sort: 0);

      await service.reorderSiblings(
        type: BillType.expense,
        orderedIds: ['z', 'x', 'y'],
        topLevel: false,
      );

      expect((await get('z')).sort, 1);
      expect((await get('x')).sort, 2);
      expect((await get('y')).sort, 3);
      for (final id in ['x', 'y', 'z']) {
        expect((await get(id)).parentId, 'p');
      }
    });

    test('跨层级 / 跨父分类 / 重复 id 一律拒绝，且数据不动', () async {
      await insertCategory('p1', '餐饮');
      await insertCategory('p2', '交通');
      await insertCategory('x', '早餐', parentId: 'p1', sort: 5);
      await insertCategory('y', '午餐', parentId: 'p2', sort: 6);
      await insertCategory('top', '购物', sort: 7);

      // 子分类层里混进一级分类
      await expectLater(
        service.reorderSiblings(
          type: BillType.expense,
          orderedIds: ['top', 'x'],
          topLevel: false,
        ),
        throwsA(isA<ValidationException>()),
      );
      // 一级分类层里混进子分类
      await expectLater(
        service.reorderSiblings(
          type: BillType.expense,
          orderedIds: ['top', 'x'],
          topLevel: true,
        ),
        throwsA(isA<ValidationException>()),
      );
      // 两个不同父分类的子分类不能一起排
      await expectLater(
        service.reorderSiblings(
          type: BillType.expense,
          orderedIds: ['x', 'y'],
          topLevel: false,
        ),
        throwsA(isA<ValidationException>()),
      );
      // 重复 id
      await expectLater(
        service.reorderSiblings(
          type: BillType.expense,
          orderedIds: ['top', 'top'],
          topLevel: true,
        ),
        throwsA(isA<ValidationException>()),
      );

      expect((await get('x')).sort, 5);
      expect((await get('y')).sort, 6);
      expect((await get('top')).sort, 7);
    });

    test('类型外的分类不参与（收入分类不会被支出列表拖动影响）', () async {
      await insertCategory('a', '餐饮', sort: 100);
      await insertCategory('i', '工资', type: 'income', sort: 900);

      await service.reorderSiblings(
        type: BillType.expense,
        orderedIds: ['a'],
        topLevel: true,
      );

      expect((await get('a')).sort, 100);
      expect((await get('i')).sort, 900);
    });
  });

  group('CategoryService.nextSort 新分类落到层级末尾', () {
    test('空层级：一级分类 100、子分类 1', () async {
      expect(await service.nextSort(type: BillType.expense), 100);
      await insertCategory('p', '餐饮');
      expect(await service.nextSort(type: BillType.expense, parentId: 'p'), 1);
    });

    test('已有分类：max + 步长（一级 100、子分类 1）', () async {
      await insertCategory('a', '餐饮', sort: 100);
      await insertCategory('b', '交通', sort: 300);
      await insertCategory('p', '购物', sort: 500);
      await insertCategory('c', '早餐', parentId: 'p', sort: 2);

      expect(await service.nextSort(type: BillType.expense), 600);
      expect(await service.nextSort(type: BillType.expense, parentId: 'p'), 3);
    });

    test('createCategory 未指定 sort 时排在末尾（不再固定 0）', () async {
      await insertCategory('a', '餐饮', sort: 100);
      final id = await service.createCategory(
        type: BillType.expense,
        name: '新分类',
        icon: 'bookmark',
      );
      expect((await get(id)).sort, 200);
      expect((await get(id)).parentId, isNull);
    });
  });

  group('CategoryService.siblingSortMap 编号规则（UI 乐观更新共用）', () {
    test('一级分类 100/200/…，子分类 1/2/…', () {
      expect(CategoryService.siblingSortMap(['a', 'b', 'c'], topLevel: true), {
        'a': 100,
        'b': 200,
        'c': 300,
      });
      expect(CategoryService.siblingSortMap(['a', 'b', 'c'], topLevel: false), {
        'a': 1,
        'b': 2,
        'c': 3,
      });
    });
  });
}
