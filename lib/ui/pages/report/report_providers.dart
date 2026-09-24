import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../state/providers.dart';
import '../statistics/stats_shared.dart';

/// 「报告汇总」入口门槛。watch 账单数据版本，账单变化后重判，
/// 因此入口能随数据增长自动出现 / 消失。
final reportGateProvider = FutureProvider<ReportGate>((ref) async {
  ref.watch(statsDataVersionProvider);
  return ref.watch(reportRepoProvider).gateStats();
});

/// 年度报告列表（年份倒序）。
///
/// 读前先按数据指纹校准缓存（指纹命中时为空操作）；账单版本、本位币、汇率
/// 任一变化都会重跑，结果始终与底层数据一致。
final yearReportsProvider = FutureProvider<List<YearReport>>((ref) async {
  ref.watch(statsDataVersionProvider);
  final base = await ref.watch(baseCurrencyProvider.future);
  final rates = ref.watch(currencyServiceProvider);
  final repo = ref.watch(reportRepoProvider);
  await repo.ensureUpToDate(baseCurrency: base, rates: rates);
  return repo.listAll();
});

/// 年报告的明细数据（月度收支 + 收支分类构成 + 标签/备注排行 + 分类/标签表）。
///
/// 这些是按年实时查询的原始明细（不进缓存表），只在打开某年年报告时加载，
/// 因此用 autoDispose.family 按年缓存、离开页面即释放。
final yearDetailProvider = FutureProvider.autoDispose.family<YearDetail, int>((
  ref,
  year,
) async {
  ref.watch(statsDataVersionProvider);
  final repo = ref.watch(reportRepoProvider);
  final monthly = await repo.monthlyOfYear(year);
  final expenseByCategory = await repo.categorySumOfYear(
    year,
    BillType.expense,
  );
  final incomeByCategory = await repo.categorySumOfYear(year, BillType.income);
  final expenseByTag = await repo.tagSumOfYear(year);
  final expenseByComment = await repo.commentSumOfYear(year);
  final categories = await ref.watch(categoryRepoProvider).getAll();
  final tags = await ref.watch(tagRepoProvider).getAll();
  return YearDetail(
    monthly: monthly,
    expenseByCategory: expenseByCategory,
    incomeByCategory: incomeByCategory,
    expenseByTag: expenseByTag,
    expenseByComment: expenseByComment,
    categories: categories,
    tags: tags,
  );
});

/// 某年的明细数据包。
class YearDetail {
  const YearDetail({
    required this.monthly,
    required this.expenseByCategory,
    required this.incomeByCategory,
    required this.expenseByTag,
    required this.expenseByComment,
    required this.categories,
    required this.tags,
  });

  /// 1-12 月收支（固定 12 条）
  final List<({int month, int income, int expense})> monthly;

  /// 支出按叶子分类汇总
  final List<({String categoryId, int amount})> expenseByCategory;

  /// 收入按叶子分类汇总
  final List<({String categoryId, int amount})> incomeByCategory;

  /// 支出按标签汇总（同一账单打多个标签时各自计入）
  final List<({String tagId, int amount})> expenseByTag;

  /// 支出按备注汇总（金额降序 Top10；无备注的账单不计入）
  final List<({String comment, int amount})> expenseByComment;

  /// 全部分类（用于把叶子分类上溯到一级分类取名字）
  final List<Category> categories;

  /// 全部标签（标签排行取名字用）
  final List<Tag> tags;

  /// 分类自身名称查表（二级分类构成用）。
  String nameOf(String categoryId) {
    for (final c in categories) {
      if (c.id == categoryId) return c.name;
    }
    return '未知分类';
  }

  /// 标签名称查表。
  String tagName(String tagId) {
    for (final t in tags) {
      if (t.id == tagId) return t.name;
    }
    return '未知标签';
  }

  /// 一级分类名称查表。
  String topLevelName(String categoryId) {
    final byId = {for (final c in categories) c.id: c};
    var cur = categoryId;
    final seen = <String>{};
    while (true) {
      final c = byId[cur];
      if (c == null) return '未知分类';
      if (c.parentId == null || !seen.add(cur)) return c.name;
      cur = c.parentId!;
    }
  }

  /// 把叶子分类金额（[leafSum]）归并到一级分类，返回金额降序列表。
  List<({String name, int amount})> topLevelSum(
    List<({String categoryId, int amount})> leafSum,
  ) {
    final byId = {for (final c in categories) c.id: c};
    final agg = <String, int>{};
    for (final e in leafSum) {
      var cur = e.categoryId;
      final seen = <String>{};
      while (true) {
        final c = byId[cur];
        if (c == null || c.parentId == null || !seen.add(cur)) break;
        cur = c.parentId!;
      }
      agg[cur] = (agg[cur] ?? 0) + e.amount;
    }
    final list = [
      for (final e in agg.entries) (name: topLevelName(e.key), amount: e.value),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}
