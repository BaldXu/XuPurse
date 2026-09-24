import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/category_repository.dart';

/// 分类业务：合并（分类管理页 -「分类合并」）。
class CategoryService {
  CategoryService(this._db) : _categories = CategoryRepository(_db);

  final AppDatabase _db;
  final CategoryRepository _categories;

  /// 合并分类：把 [selectedIds]（至少 2 个，须同类型）合并成一个分类。
  ///
  /// - 保留目标：当 [targetId] 为所选分类之一时保留它（其余所选分类并入），
  ///   目标分类原有的子分类**保留**；当 [targetId] 为 null 时按 [name]/
  ///   [icon]/[color] 新建一个一级分类。
  /// - 子分类跟随：任一被合并分类的所有子分类会一并合并（其账单也重定向），
  ///   用户无需逐个合并子分类。
  /// - 引用迁移：账单 / 预算 / 导入映射（entity_type=category）中的
  ///   category_id 引用全部重定向到目标，保证统计与再次导入不产生重复。
  /// - 若保留分类的父分类也被合并，则保留分类提升为一级分类（避免悬挂父引用）。
  /// - 单事务；被合并分类（含子分类）物理删除。返回目标分类 id。
  Future<String> mergeCategories({
    required BillType type,
    required List<String> selectedIds,
    String? targetId,
    required String name,
    required String icon,
    String? color,
  }) async {
    final nameTrim = name.trim();
    if (nameTrim.isEmpty) {
      throw const ValidationException('合并后分类名称不能为空');
    }
    final selected = selectedIds.toSet();
    if (selected.length < 2) {
      throw const ValidationException('请至少选择两个分类');
    }
    if (targetId != null && !selected.contains(targetId)) {
      throw const ValidationException('保留分类必须是所选分类之一');
    }

    final all = await _categories.getByType(type);
    final byId = {for (final c in all) c.id: c};
    for (final id in selected) {
      if (!byId.containsKey(id)) throw NotFoundException('分类不存在: $id');
    }

    final now = nowMs();
    // 保留分类的 defaultSelect 标记转移：默认分类被合并时不让记账默认丢失。
    final sourceHasDefault = all.any(
      (c) => c.defaultSelect && (c.id == targetId || selected.contains(c.id)),
    );

    return await _db.transaction(() async {
      // 合并集：每个被合并分类（选中项去掉目标）及其全部子分类。
      final sourceIds = <String>{};
      for (final id in selected) {
        if (id == targetId) continue;
        _collectWithDescendants(all, id, sourceIds);
      }
      // 目标若是某被合并分类的子分类，递归收集会把它也加入待删集，须剔除。
      if (targetId != null) sourceIds.remove(targetId);
      if (sourceIds.isEmpty) {
        throw const ValidationException('没有需要合并的分类');
      }
      final placeholders = List.filled(sourceIds.length, '?').join(',');

      // 1) 先确定目标分类（新建或保留），再迁移引用
      final targetCategoryId = await _resolveTarget(
        type: type,
        targetId: targetId,
        name: nameTrim,
        icon: icon,
        color: color,
        sourceHasDefault: sourceHasDefault,
        now: now,
      );

      // 2) 账单重定向（含被合并分类的全部子分类记录）
      await _db.customUpdate(
        'UPDATE bills SET category_id = ? WHERE category_id IN ($placeholders)',
        variables: [Variable(targetCategoryId), ..._vars(sourceIds)],
        updates: {_db.bills},
        updateKind: UpdateKind.update,
      );
      // 3) 预算重定向
      await _db.customUpdate(
        'UPDATE budgets SET category_id = ? WHERE category_id IN ($placeholders)',
        variables: [Variable(targetCategoryId), ..._vars(sourceIds)],
        updates: {_db.budgets},
        updateKind: UpdateKind.update,
      );
      // 4) 导入映射重定向（保证再次导入同一第三方文件不重建被合并分类）
      await _db.customUpdate(
        "UPDATE import_mappings SET target_id = ? "
        "WHERE target_id IN ($placeholders) AND entity_type = 'category'",
        variables: [Variable(targetCategoryId), ..._vars(sourceIds)],
        updates: {_db.importMappings},
        updateKind: UpdateKind.update,
      );

      // 5) 保留分类的父分类被合并 → 提升为一级分类（避免悬挂父引用）
      final kept = byId[targetCategoryId];
      if (kept != null &&
          kept.parentId != null &&
          sourceIds.contains(kept.parentId)) {
        await _categories.update(
          targetCategoryId,
          CategoriesCompanion(
            parentId: const Value(null),
            updatedAt: Value(now),
          ),
        );
      }

      // 6) 删除被合并分类（含全部子分类）
      await _db.customStatement(
        'DELETE FROM categories WHERE id IN ($placeholders)',
        [...sourceIds],
      );
      return targetCategoryId;
    });
  }

  /// 确定目标分类：已有分类则改名/换图标/换色；否则新建一级分类。
  Future<String> _resolveTarget({
    required BillType type,
    required String? targetId,
    required String name,
    required String icon,
    String? color,
    required bool sourceHasDefault,
    required int now,
  }) async {
    if (targetId != null) {
      final target = await _categories.getById(targetId);
      if (target == null) throw NotFoundException('分类不存在: $targetId');
      await _categories.update(
        targetId,
        CategoriesCompanion(
          name: Value(name),
          icon: Value(icon),
          color: Value(color ?? target.color),
          customName: const Value(true),
          defaultSelect: Value(sourceHasDefault || target.defaultSelect),
          updatedAt: Value(now),
        ),
      );
      return targetId;
    }
    final id = genId();
    await _categories.insert(
      CategoriesCompanion.insert(
        id: id,
        type: type.name,
        name: name,
        icon: Value(icon),
        color: Value(color),
        parentId: const Value(null),
        customName: const Value(true),
        defaultSelect: Value(sourceHasDefault),
        sort: const Value(0),
        seedKey: const Value(null),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// 收集 [id] 及其全部子分类到 [out]（父分类被合并时子分类自动跟随）。
  void _collectWithDescendants(List<Category> all, String id, Set<String> out) {
    if (!out.add(id)) return;
    for (final c in all) {
      if (c.parentId == id) _collectWithDescendants(all, c.id, out);
    }
  }

  static List<Variable<String>> _vars(Set<String> ids) => [
    for (final id in ids) Variable(id),
  ];
}
