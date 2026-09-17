import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../database/app_database.dart';

/// 分类数据访问（两级树；查询结果按 sort, name 排序）。
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// 监听全部分类（跨类型，用于账单列表展示分类名/图标）
  Stream<List<Category>> watchAll() =>
      (_db.select(_db.categories)..orderBy([
            (t) => OrderingTerm.asc(t.sort),
            (t) => OrderingTerm.asc(t.name),
          ]))
          .watch();

  /// 监听指定类型的全部分类（含父子，UI 自行组树）
  Stream<List<Category>> watchByType(BillType type) =>
      (_db.select(_db.categories)
            ..where((t) => t.type.equals(type.name))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sort),
              (t) => OrderingTerm.asc(t.name),
            ]))
          .watch();

  Future<List<Category>> getByType(BillType type) =>
      (_db.select(_db.categories)
            ..where((t) => t.type.equals(type.name))
            ..orderBy([
              (t) => OrderingTerm.asc(t.sort),
              (t) => OrderingTerm.asc(t.name),
            ]))
          .get();

  Future<List<Category>> getAll() =>
      (_db.select(_db.categories)..orderBy([
            (t) => OrderingTerm.asc(t.sort),
            (t) => OrderingTerm.asc(t.name),
          ]))
          .get();

  Future<Category?> getById(String id) => (_db.select(
    _db.categories,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// 按种子 key 查找（幂等初始化）
  Future<Category?> findBySeedKey(String seedKey) => (_db.select(
    _db.categories,
  )..where((t) => t.seedKey.equals(seedKey))).getSingleOrNull();

  /// 按名称查找指定类型的分类（导入映射）
  Future<Category?> findByName(BillType type, String name) =>
      (_db.select(_db.categories)
            ..where((t) => t.type.equals(type.name) & t.name.equals(name)))
          .getSingleOrNull();

  /// 某类型的默认选中分类（defaultSelect 标记）
  Future<Category?> findDefault(BillType type) =>
      (_db.select(_db.categories)
            ..where(
              (t) => t.type.equals(type.name) & t.defaultSelect.equals(true),
            )
            ..limit(1))
          .getSingleOrNull();

  /// 子分类数量（删除父分类前的校验）
  Future<int> countChildren(String parentId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM categories WHERE parent_id = ?',
          variables: [Variable(parentId)],
        )
        .getSingle();
    return row.data['c'] as int;
  }

  Future<void> insert(CategoriesCompanion entry) =>
      _db.into(_db.categories).insert(entry);

  Future<void> update(String id, CategoriesCompanion entry) =>
      (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(entry);

  Future<void> delete(String id) =>
      (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
}
