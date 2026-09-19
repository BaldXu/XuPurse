import '../../core/constants/enums.dart';
import '../database/app_database.dart';
import '../seed/default_categories.dart';
import 'import_models.dart';

/// 第三方分类名 → XuPurse 种子分类的模糊匹配（一木为准，昼虎/钱迹挂靠）。
///
/// 匹配顺序：
/// 1. 精确匹配映射表（各 source 专属表）→ 种子 key
/// 2. 种子分类名称精确匹配（限定支出/收入类型）
/// 3. 名称包含匹配（如「餐饮」→「食品餐饮」、「理发」→「理发美容」）
/// 4. 全部未命中 → null（调用方走各自 fallback / 新建逻辑）
abstract final class CategoryFuzzyMatcher {
  /// 在 [ctx] 的现有分类里做名称精确匹配。
  static Category? exactMatch(MapperContext ctx, String name, BillType type) =>
      ctx.categoryByTypeName(type, name.trim());

  /// 在种子分类里做名称包含匹配（种名含关键词或关键词含种名，双向且 ≥2 字）。
  static String? seedKeyByContain(String name, BillType type) {
    final n = name.trim();
    if (n.length < 2) return null;
    for (final seed in allSeedCategories) {
      if (seed.type != type) continue;
      final sn = seed.name.trim();
      if (sn.length < 2) continue;
      if (sn.contains(n) || n.contains(sn)) return seed.key;
    }
    return null;
  }
}
