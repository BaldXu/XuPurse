import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/errors.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/category_repository.dart';

/// 一级分类排序步长（内置分类即 100/200/300…；子分类步长 1）。
///
/// 编号留间隔是为了新增/插入时不必重排全表，也便于与内置分类的编号习惯一致。
const int kTopLevelSortStep = 100;

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

  /// 拖拽排序：把同一层级的兄弟分类按 [orderedIds] 的顺序重新编号。
  ///
  /// - [topLevel] = true：重排一级分类（编号 100 起、步长 100，与内置分类一致）；
  ///   false：重排同一父分类下的子分类（编号 1 起、步长 1）。
  /// - 只接受同层兄弟：一级层要求全都没有父分类，子分类层要求父分类一致
  ///   （不变量在这里兜底，跨层级/跨父分类的调用直接拒绝）。
  /// - **只写 sort，不碰 parentId**——拖动排序永远不会改变分类层级。
  /// - 重新编号使同层级内序号互不重复，顺手治好历史遗留的重号（手填 sort 撞号）。
  Future<void> reorderSiblings({
    required BillType type,
    required List<String> orderedIds,
    required bool topLevel,
  }) async {
    if (orderedIds.length < 2) return;
    if (orderedIds.toSet().length != orderedIds.length) {
      throw const ValidationException('排序数据里有重复的分类');
    }
    final all = await _categories.getByType(type);
    final byId = {for (final c in all) c.id: c};
    String? parentId;
    for (final id in orderedIds) {
      final c = byId[id];
      if (c == null) throw NotFoundException('分类不存在: $id');
      if (topLevel) {
        if (c.parentId != null) {
          throw const ValidationException('一级分类排序里混入了子分类');
        }
      } else {
        if (c.parentId == null) {
          throw const ValidationException('子分类排序里混入了一级分类');
        }
        parentId ??= c.parentId;
        if (c.parentId != parentId) {
          throw const ValidationException('不能在两个父分类之间拖动子分类');
        }
      }
    }
    await _categories.updateSortOrders(
      siblingSortMap(orderedIds, topLevel: topLevel),
    );
  }

  /// 同层按位置编号（列表长按拖动排序的唯一编号规则，UI 乐观更新也用它）：
  /// 一级分类 100/200/300…、子分类 1/2/3…。
  static Map<String, int> siblingSortMap(
    List<String> orderedIds, {
    required bool topLevel,
  }) => {
    for (var i = 0; i < orderedIds.length; i++)
      orderedIds[i]: (i + 1) * (topLevel ? kTopLevelSortStep : 1),
  };

  /// 目标层级末尾的排序值：一级分类步长 100、子分类步长 1。
  ///
  /// 新增分类、以及编辑时换了父分类（层级变了）都要用它——沿用「排在最后」
  /// 的直觉，且不会撞上已有序号；之后用户可在列表里长按拖动调整。
  Future<int> nextSort({required BillType type, String? parentId}) async {
    final all = await _categories.getByType(type);
    final siblings = all.where((c) => c.parentId == parentId);
    if (siblings.isEmpty) return parentId == null ? kTopLevelSortStep : 1;
    var maxSort = siblings.first.sort;
    for (final c in siblings) {
      if (c.sort > maxSort) maxSort = c.sort;
    }
    return maxSort + (parentId == null ? kTopLevelSortStep : 1);
  }

  /// 新建分类（删除含明细分类时「当场新建目标分类」复用）。返回新分类 id。
  ///
  /// [parentId] 非空时校验父分类存在且与 [type] 同类型。
  Future<String> createCategory({
    required BillType type,
    required String name,
    required String icon,
    String? color,
    String? parentId,
    int? sort,
  }) async {
    final nameTrim = name.trim();
    if (nameTrim.isEmpty) {
      throw const ValidationException('分类名称不能为空');
    }
    if (parentId != null) {
      final parent = await _categories.getById(parentId);
      if (parent == null || parent.type != type.name) {
        throw const ValidationException('父分类不存在或类型不一致');
      }
    }
    final now = nowMs();
    final id = genId();
    await _categories.insert(
      CategoriesCompanion.insert(
        id: id,
        type: type.name,
        name: nameTrim,
        icon: Value(icon),
        color: Value(color),
        parentId: Value(parentId),
        customName: const Value(true),
        defaultSelect: const Value(false),
        // 未指定时排到目标层级末尾（一级分类步长 100、子分类步长 1），
        // 之后在分类列表里长按拖动即可调整。
        sort: Value(sort ?? await nextSort(type: type, parentId: parentId)),
        seedKey: const Value(null),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  /// 删除分类并把它的引用（账单/预算/导入映射）迁移到 [targetCategoryId]。
  ///
  /// 用于「分类下还有明细」的删除：不允许明细失去分类归属。要求目标分类
  /// 存在、与被删分类同类型，且不是被删分类的子分类。单事务执行，任一
  /// 步失败全部回滚。
  Future<void> deleteWithReassign({
    required String categoryId,
    required String targetCategoryId,
  }) async {
    if (categoryId == targetCategoryId) {
      throw const ValidationException('新分类不能与原分类相同');
    }
    final source = await _categories.getById(categoryId);
    if (source == null) throw NotFoundException('分类不存在: $categoryId');
    final target = await _categories.getById(targetCategoryId);
    if (target == null) throw NotFoundException('目标分类不存在: $targetCategoryId');
    if (target.type != source.type) {
      throw const ValidationException('只能移动到同类型分类');
    }
    if (target.parentId == categoryId) {
      throw const ValidationException('不能移动到原分类的子分类');
    }
    if (await _categories.countChildren(categoryId) > 0) {
      throw const ValidationException('请先处理该分类下的子分类');
    }

    await _db.transaction(() async {
      await _db.customUpdate(
        'UPDATE bills SET category_id = ? WHERE category_id = ?',
        variables: [Variable(targetCategoryId), Variable(categoryId)],
        updates: {_db.bills},
        updateKind: UpdateKind.update,
      );
      await _db.customUpdate(
        'UPDATE budgets SET category_id = ? WHERE category_id = ?',
        variables: [Variable(targetCategoryId), Variable(categoryId)],
        updates: {_db.budgets},
        updateKind: UpdateKind.update,
      );
      await _db.customUpdate(
        'UPDATE import_mappings SET target_id = ? '
        "WHERE target_id = ? AND entity_type = 'category'",
        variables: [Variable(targetCategoryId), Variable(categoryId)],
        updates: {_db.importMappings},
        updateKind: UpdateKind.update,
      );
      await _categories.delete(categoryId);
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
        // 合并出来的新目标排在一级分类末尾：固定 0 会和别的分类撞号、顺序看运气。
        sort: Value(await nextSort(type: type, parentId: null)),
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
