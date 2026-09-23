import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/domain/ai/ai_scope.dart';
import 'package:xupurse/domain/ai/stats_context.dart';
import 'package:xupurse/state/providers.dart';

void main() {
  test('AiStatsContext.build：分类/标签逐月生成且不因 record sort 丢失', () async {
    final db = AppDatabase.memory();
    final now = DateTime.now();
    // 上个月某天 + 本月某天，制造跨两个月的数据
    final thisMonth = DateTime(now.year, now.month, 5);
    final lastMonth = DateTime(now.year, now.month - 1, 20);
    final t1 = thisMonth.millisecondsSinceEpoch;
    final t0 = lastMonth.millisecondsSinceEpoch;

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-food',
            type: BillType.expense.name,
            name: '餐饮',
            createdAt: t0,
            updatedAt: t0,
          ),
        );
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(
            id: 'tag-travel',
            name: '旅行',
            createdAt: t0,
            updatedAt: t0,
          ),
        );
    // 上月支出 1 笔 30000，本月支出 2 笔 5000+5000（同分类同标签）
    Future<void> ins(String id, int time, int amount) => db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            id: id,
            type: BillType.expense.name,
            categoryId: 'cat-food',
            amount: amount,
            time: time,
            createdAt: t0,
            updatedAt: t0,
          ),
        );
    await ins('b-a', t0, 30000);
    await ins('b-b', t1, 5000);
    await ins('b-c', t1, 5000);
    for (final b in ['b-a', 'b-b', 'b-c']) {
      await db
          .into(db.billTags)
          .insert(BillTagsCompanion.insert(billId: b, tagId: 'tag-travel'));
    }

    final container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    final scope = AiScope.defaultScope.copyWith(
      range: AiScopeRange.m6,
      includeTags: true,
    );
    final text = await AiStatsContext(container).build(override: scope);

    // ignore: avoid_print
    print('===== 生成结果 =====\n$text\n===== 结束 =====');

    final lm = '${lastMonth.year}/${lastMonth.month}';
    final cm = '${now.year}/${now.month}';

    // 分类：上月的 30000 与本月两笔合计 10000 分开，且不再因 sort 丢失
    expect(text, contains('### 支出分类 Top10（$lm）'));
    expect(text, contains('### 支出分类 Top10（$cm）'));
    expect(text, contains('cat-food'));
    // 上月段应含 3.00，本月段应含 1.00，而不是合并成 4.00
    final lmIdx = text.indexOf('### 支出分类 Top10（$lm）');
    final cmIdx = text.indexOf('### 支出分类 Top10（$cm）');
    expect(lmIdx, isNot(-1));
    expect(cmIdx, greaterThan(lmIdx));
    expect(text.substring(lmIdx, cmIdx), contains('3.00'));
    expect(text.substring(lmIdx, cmIdx), isNot(contains('4.00')));

    // 标签：同样逐月
    expect(text, contains('### 支出标签 Top10（$lm）'));
    expect(text, contains('### 支出标签 Top10（$cm）'));
    expect(text, contains('tag-travel'));
  });

  test('AiStatsContext.build：全部档位超 24 个月时保留最近月份并提示', () async {
    final db = AppDatabase.memory();
    final now = DateTime.now();
    // 3 年前（应被截断丢弃）与本月的两笔支出
    final old = DateTime(now.year - 3, 1, 15);
    final recent = DateTime(now.year, now.month, 5);
    final tOld = old.millisecondsSinceEpoch;
    final tRecent = recent.millisecondsSinceEpoch;

    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: 'cat-food',
            type: BillType.expense.name,
            name: '餐饮',
            createdAt: tOld,
            updatedAt: tOld,
          ),
        );
    Future<void> ins(String id, int time) => db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            id: id,
            type: BillType.expense.name,
            categoryId: 'cat-food',
            amount: 10000,
            time: time,
            createdAt: tOld,
            updatedAt: tOld,
          ),
        );
    await ins('b-old', tOld);
    await ins('b-new', tRecent);

    final container = ProviderContainer(
      overrides: [dbProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    addTearDown(db.close);

    final text = await AiStatsContext(
      container,
    ).build(override: AiScope.defaultScope.copyWith(range: AiScopeRange.all));

    // 保留最近 24 个月：本月有逐月分类，3 年前的月份被截断丢弃
    expect(text, contains('### 支出分类 Top10（${now.year}/${now.month}）'));
    expect(text, isNot(contains('（${old.year}/${old.month}）')));
    // 截断时给出口径提示
    expect(text, contains('仅列出最近 24 个月'));
  });
}
