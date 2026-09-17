import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/database/database_manager.dart';
import '../data/import/import_service.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/bill_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/snapshot_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../domain/services/account_service.dart';
import '../domain/services/bill_service.dart';
import '../domain/services/currency_service.dart';

/// 数据库管理器（main 中完成账本初始化后 override 注入）。
final databaseManagerProvider = Provider<DatabaseManager>(
  (ref) =>
      throw UnimplementedError('databaseManagerProvider 必须在 main 中 override'),
);

/// 当前账本数据库（同步获取，main 已保证 openBook 完成）。
final dbProvider = Provider<AppDatabase>(
  (ref) => ref.watch(databaseManagerProvider).current,
);

// ---------- Repository ----------

final billRepoProvider = Provider(
  (ref) => BillRepository(ref.watch(dbProvider)),
);
final accountRepoProvider = Provider(
  (ref) => AccountRepository(ref.watch(dbProvider)),
);
final categoryRepoProvider = Provider(
  (ref) => CategoryRepository(ref.watch(dbProvider)),
);
final snapshotRepoProvider = Provider(
  (ref) => SnapshotRepository(ref.watch(dbProvider)),
);
final tagRepoProvider = Provider((ref) => TagRepository(ref.watch(dbProvider)));
final budgetRepoProvider = Provider(
  (ref) => BudgetRepository(ref.watch(dbProvider)),
);

// ---------- Service ----------

final billServiceProvider = Provider(
  (ref) => BillService(ref.watch(dbProvider)),
);
final accountServiceProvider = Provider(
  (ref) => AccountService(ref.watch(dbProvider)),
);

/// 第三方导入引擎
final importServiceProvider = Provider(
  (ref) => ImportService(ref.watch(dbProvider)),
);

/// 多币种服务（状态 = 当前生效汇率表）
final currencyServiceProvider =
    NotifierProvider<CurrencyService, Map<String, double>>(CurrencyService.new);

/// 当前账本本位币（Books.baseCurrency，默认 CNY）
final baseCurrencyProvider = FutureProvider<String>((ref) async {
  final mgr = ref.watch(databaseManagerProvider);
  final global = await mgr.global();
  final id = mgr.currentBookId;
  if (id == null) return 'CNY';
  final book = await (global.select(
    global.books,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
  return book?.baseCurrency ?? 'CNY';
});

// ---------- 数据流 ----------

/// 首页账单加载条数（懒加载：滚动到底 +50）
final billsLimitProvider = StateProvider<int>((ref) => 50);

/// 首页账单流（时间倒序分页）
final billsProvider = StreamProvider<List<Bill>>((ref) {
  return ref
      .watch(billRepoProvider)
      .watchPage(limit: ref.watch(billsLimitProvider));
});

/// 全部分类（账单列表展示分类名/图标用）
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepoProvider).watchAll();
});

/// 账户流
final accountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountRepoProvider).watchAll();
});

/// 总资产流（fund + includeInAssets + enabled；外币账户按汇率折算到本位币）
final totalAssetsProvider = StreamProvider<int>((ref) {
  final base = ref.watch(baseCurrencyProvider).value ?? 'CNY';
  final rates = ref.watch(currencyServiceProvider);
  return ref.watch(accountRepoProvider).watchAll().map((accounts) {
    var total = 0;
    for (final a in accounts) {
      if (a.category != 'fund' || !a.includeInAssets || !a.enabled) continue;
      total += convertAmount(a.currentBalance, a.currency, base, rates);
    }
    return total;
  });
});

/// 本月收支柱出
final monthSummaryProvider = StreamProvider<({int expense, int income})>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month).millisecondsSinceEpoch;
  final end = DateTime(now.year, now.month + 1).millisecondsSinceEpoch;
  return ref.watch(billRepoProvider).watchSummaryInRange(start, end);
});

/// 全部标签流
final tagsProvider = StreamProvider<List<Tag>>((ref) {
  return ref.watch(tagRepoProvider).watchAll();
});

/// 总资产历史趋势（全部有效快照，时间升序，响应式）
final snapshotsProvider = StreamProvider<List<BalanceSnapshot>>((ref) {
  return ref.watch(snapshotRepoProvider).watchAll();
});
