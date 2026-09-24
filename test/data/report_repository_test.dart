import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/repositories/report_repository.dart';

void main() {
  late AppDatabase db;
  late ReportRepository repo;
  late int now;
  var seq = 0;

  setUp(() {
    db = AppDatabase.memory();
    repo = ReportRepository(db);
    now = DateTime.now().millisecondsSinceEpoch;
    seq = 0;
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> insertAccount({
    String name = '现金',
    String category = 'fund',
    int balance = 0,
  }) async {
    final id = 'acc-$name';
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            name: name,
            category: category,
            type: 'cash',
            initialBalance: Value(balance),
            currentBalance: Value(balance),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> insertCategory(String name, BillType type) async {
    final id = 'cat-$name';
    await db
        .into(db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            type: type.name,
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<String> insertBill({
    required BillType type,
    required String categoryId,
    required int amount,
    required int time,
    String? extra,
    String? incomeAccountId,
    String? comment,
  }) async {
    final id = 'bill-${seq++}';
    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            id: id,
            type: type.name,
            categoryId: categoryId,
            amount: amount,
            time: time,
            extra: Value(extra),
            comment: Value(comment),
            incomeAccountId: Value(incomeAccountId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> insertSnapshot({
    required String accountId,
    required int balance,
    required int timestamp,
    bool valid = true,
  }) => db
      .into(db.balanceSnapshots)
      .insert(
        BalanceSnapshotsCompanion.insert(
          id: 'snap-$accountId-$timestamp-$seq',
          accountId: accountId,
          balance: balance,
          timestamp: timestamp,
          type: SnapshotType.manual,
          isValid: Value(valid),
        ),
      );

  int ts(int y, [int m = 1, int d = 1]) =>
      DateTime(y, m, d).millisecondsSinceEpoch;

  Future<void> recompute() =>
      repo.ensureUpToDate(baseCurrency: 'CNY', rates: const {});

  Future<YearReport?> yearOf(int year) async {
    final all = await repo.listAll();
    for (final r in all) {
      if (r.year == year) return r;
    }
    return null;
  }

  group('ReportGate 门槛', () {
    test('空库未解锁', () async {
      final gate = await repo.gateStats();
      expect(gate.count, 0);
      expect(gate.unlocked, isFalse);
    });

    test('条数不足 10 条不解锁（即使跨度够）', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      for (var i = 0; i < 9; i++) {
        await insertBill(
          type: BillType.expense,
          categoryId: cat,
          amount: 1000,
          time: ts(2023, 1, 1 + i * 2),
        );
      }
      final gate = await repo.gateStats();
      expect(gate.count, 9);
      expect(gate.unlocked, isFalse);
    });

    test('跨度不足一周不解锁（即使条数够）', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      for (var i = 0; i < 12; i++) {
        await insertBill(
          type: BillType.expense,
          categoryId: cat,
          amount: 1000,
          time: ts(2023, 1, 1) + i * Duration.millisecondsPerHour,
        );
      }
      final gate = await repo.gateStats();
      expect(gate.count, 12);
      expect(gate.unlocked, isFalse);
    });

    test('条数与跨度都满足则解锁', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      for (var i = 0; i < 10; i++) {
        await insertBill(
          type: BillType.expense,
          categoryId: cat,
          amount: 1000,
          time: ts(2023, 1, 1 + i),
        );
      }
      final gate = await repo.gateStats();
      expect(gate.count, 10);
      expect(gate.unlocked, isTrue);
    });

    test('调账与「不计入收支」账单不计入门槛条数', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      for (var i = 0; i < 10; i++) {
        await insertBill(
          type: BillType.expense,
          categoryId: cat,
          amount: 1000,
          time: ts(2023, 1, 1 + i),
        );
      }
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 1000,
        time: ts(2023, 1, 12),
        extra: '{"isAdjustment":true}',
      );
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 1000,
        time: ts(2023, 1, 12),
        extra: '{"excludeFromStats":true}',
      );
      expect((await repo.gateStats()).count, 10);
    });
  });

  group('年度汇总', () {
    test('记录收支与调账分桶', () async {
      final catE = await insertCategory('餐饮', BillType.expense);
      final catI = await insertCategory('工资', BillType.income);
      await insertBill(
        type: BillType.income,
        categoryId: catI,
        amount: 200000,
        time: ts(2023, 3, 1),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catE,
        amount: 100000,
        time: ts(2023, 4, 1),
      );
      await insertBill(
        type: BillType.income,
        categoryId: catI,
        amount: 50000,
        time: ts(2023, 5, 1),
        extra: '{"isAdjustment":true}',
      );
      await recompute();

      final y = (await yearOf(2023))!;
      expect(y.income, 200000);
      expect(y.expense, 100000);
      expect(y.adjustNet, 50000);
      expect(y.adjustCount, 1);
      expect(y.billCount, 2);
    });

    test('「不计入收支」与转账不计入汇总', () async {
      final catE = await insertCategory('餐饮', BillType.expense);
      final catI = await insertCategory('工资', BillType.income);
      final catT = await insertCategory('转账', BillType.transfer);
      final acc = await insertAccount();
      await insertBill(
        type: BillType.income,
        categoryId: catI,
        amount: 200000,
        time: ts(2023, 3, 1),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catE,
        amount: 30000,
        time: ts(2023, 3, 2),
        extra: '{"excludeFromStats":true}',
      );
      await insertBill(
        type: BillType.income,
        categoryId: catI,
        amount: 40000,
        time: ts(2023, 3, 3),
        extra: '{"notInTotal":true}',
      );
      await insertBill(
        type: BillType.transfer,
        categoryId: catT,
        amount: 90000,
        time: ts(2023, 3, 4),
        incomeAccountId: acc,
      );
      await recompute();

      final y = (await yearOf(2023))!;
      expect(y.income, 200000);
      expect(y.expense, 0);
      expect(y.billCount, 1);
      expect(y.adjustCount, 0);
    });

    test('指纹命中跳过重算，账单变化后重新计算', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 10000,
        time: ts(2023, 2, 1),
      );
      await recompute();

      // 人为打标记：指纹一致时应跳过，标记保留即证明未重算。
      await (db.update(db.yearReports)..where((t) => t.year.equals(2023)))
          .write(const YearReportsCompanion(computedAt: Value(-1)));
      await recompute();
      expect((await yearOf(2023))!.computedAt, -1);

      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 20000,
        time: ts(2023, 2, 2),
      );
      await recompute();
      final y = (await yearOf(2023))!;
      expect(y.computedAt, isNot(-1));
      expect(y.expense, 30000);
      expect(y.billCount, 2);
    });

    test('年份账单清空后缓存行被删除', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 10000,
        time: ts(2023, 2, 1),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 10000,
        time: ts(2024, 2, 1),
      );
      await recompute();
      expect((await repo.listAll()).length, 2);

      await (db.delete(
        db.bills,
      )..where((t) => t.time.isSmallerThanValue(ts(2024)))).go();
      await recompute();
      final all = await repo.listAll();
      expect(all.length, 1);
      expect(all.single.year, 2024);
    });
  });

  group('明细查询', () {
    test('monthlyOfYear 固定 12 条且合计等于年度汇总', () async {
      final catE = await insertCategory('餐饮', BillType.expense);
      final catI = await insertCategory('工资', BillType.income);
      await insertBill(
        type: BillType.income,
        categoryId: catI,
        amount: 10000,
        time: ts(2023, 1, 15),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catE,
        amount: 3000,
        time: ts(2023, 1, 20),
      );
      await insertBill(
        type: BillType.income,
        categoryId: catI,
        amount: 20000,
        time: ts(2023, 12, 5),
      );
      // 调账与跨年账单不该出现
      await insertBill(
        type: BillType.expense,
        categoryId: catE,
        amount: 9999,
        time: ts(2023, 6, 1),
        extra: '{"isAdjustment":true}',
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catE,
        amount: 8888,
        time: ts(2024, 6, 1),
      );

      final monthly = await repo.monthlyOfYear(2023);
      expect(monthly.length, 12);
      expect(monthly[0].income, 10000);
      expect(monthly[0].expense, 3000);
      expect(monthly[11].income, 20000);
      expect(monthly[11].expense, 0);
      expect(monthly[5].expense, 0);

      await recompute();
      final y = (await yearOf(2023))!;
      expect(monthly.fold<int>(0, (s, m) => s + m.income), y.income);
      expect(monthly.fold<int>(0, (s, m) => s + m.expense), y.expense);
    });

    test('categorySumOfYear 按分类汇总且排除调账', () async {
      final catA = await insertCategory('餐饮', BillType.expense);
      final catB = await insertCategory('交通', BillType.expense);
      await insertBill(
        type: BillType.expense,
        categoryId: catA,
        amount: 5000,
        time: ts(2023, 1, 1),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catA,
        amount: 2500,
        time: ts(2023, 2, 1),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catB,
        amount: 1000,
        time: ts(2023, 3, 1),
      );
      await insertBill(
        type: BillType.expense,
        categoryId: catB,
        amount: 7777,
        time: ts(2023, 4, 1),
        extra: '{"isAdjustment":true}',
      );

      final sums = await repo.categorySumOfYear(2023, BillType.expense);
      final byCat = {for (final e in sums) e.categoryId: e.amount};
      expect(byCat[catA], 7500);
      expect(byCat[catB], 1000);
      expect(sums.length, 2);
    });

    test('tagSumOfYear / commentSumOfYear 按年聚合支出且口径同年度报告', () async {
      final cat = await insertCategory('餐饮', BillType.expense);
      // 带标签/备注的常规支出
      final bill1 = await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 3000,
        time: ts(2023, 2, 1),
        comment: '氪金',
      );
      // 无备注的常规支出（不计入备注排行）
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 2000,
        time: ts(2023, 3, 1),
      );
      // 双标签支出（各自计入该标签）
      final bill3 = await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 4000,
        time: ts(2023, 4, 1),
        comment: '氪金',
      );
      // 调账 / 不计入收支：标签与备注排行都应排除
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 9999,
        time: ts(2023, 5, 1),
        extra: '{"isAdjustment":true}',
        comment: '余额调整',
      );
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 8888,
        time: ts(2023, 6, 1),
        extra: '{"excludeFromStats":true}',
        comment: '大额氪金',
      );
      // 跨年账单不计入
      await insertBill(
        type: BillType.expense,
        categoryId: cat,
        amount: 7777,
        time: ts(2024, 6, 1),
        comment: '氪金',
      );
      for (final entry in [
        BillTagsCompanion.insert(billId: bill1, tagId: 'tag-a'),
        BillTagsCompanion.insert(billId: bill3, tagId: 'tag-a'),
        BillTagsCompanion.insert(billId: bill3, tagId: 'tag-b'),
      ]) {
        await db.into(db.billTags).insert(entry);
      }

      final tagSums = await repo.tagSumOfYear(2023);
      final byTag = {for (final e in tagSums) e.tagId: e.amount};
      expect(byTag['tag-a'], 7000);
      expect(byTag['tag-b'], 4000);
      expect(tagSums.length, 2);

      final commentSums = await repo.commentSumOfYear(2023);
      expect(commentSums, hasLength(1));
      expect(commentSums.single.comment, '氪金');
      expect(commentSums.single.amount, 7000);
    });
  });

  group('资产时点', () {
    test('有期初 / 期末快照时给出资产变动基准', () async {
      final cat = await insertCategory('工资', BillType.income);
      final acc = await insertAccount(balance: 0);
      await insertSnapshot(
        accountId: acc,
        balance: 1000000,
        timestamp: ts(2022, 12, 31),
      );
      await insertSnapshot(
        accountId: acc,
        balance: 1800000,
        timestamp: ts(2023, 12, 31),
      );
      await insertBill(
        type: BillType.income,
        categoryId: cat,
        amount: 200000,
        time: ts(2023, 6, 1),
      );
      await recompute();

      final y = (await yearOf(2023))!;
      expect(y.hasAssetBaseline, isTrue);
      expect(y.startAssets, 1000000);
      expect(y.endAssets, 1800000);
    });

    test('无快照时降级（hasAssetBaseline=false）', () async {
      final cat = await insertCategory('工资', BillType.income);
      await insertAccount(balance: 500000);
      await insertBill(
        type: BillType.income,
        categoryId: cat,
        amount: 10000,
        time: ts(2023, 6, 1),
      );
      await recompute();

      final y = (await yearOf(2023))!;
      expect(y.hasAssetBaseline, isFalse);
      expect(y.startAssets, 500000);
      expect(y.endAssets, 500000);
    });

    test('有快照但均晚于期初边界时，期初按 0 计（与趋势页口径一致）', () async {
      final cat = await insertCategory('工资', BillType.income);
      final acc = await insertAccount(balance: 0);
      // 账户首条快照在 2023 年中：2023 年初（1/1）时点该账户尚未入账 → 期初 0，
      // 不回落 current_balance（否则会虚增年初资产）。
      await insertSnapshot(
        accountId: acc,
        balance: 800000,
        timestamp: ts(2023, 6, 30),
      );
      await insertBill(
        type: BillType.income,
        categoryId: cat,
        amount: 10000,
        time: ts(2023, 6, 1),
      );
      await recompute();

      final y = (await yearOf(2023))!;
      expect(y.startAssets, 0);
      expect(y.endAssets, 800000);
      // 期初无快照 → 无完整资产基准，资产变动卡片按「缺少快照」处理。
      expect(y.hasAssetBaseline, isFalse);
    });

    test('作废快照不参与时点取值', () async {
      final cat = await insertCategory('工资', BillType.income);
      final acc = await insertAccount(balance: 0);
      await insertSnapshot(
        accountId: acc,
        balance: 999999,
        timestamp: ts(2023, 12, 31),
        valid: false,
      );
      await insertBill(
        type: BillType.income,
        categoryId: cat,
        amount: 10000,
        time: ts(2023, 6, 1),
      );
      await recompute();

      final y = (await yearOf(2023))!;
      expect(y.hasAssetBaseline, isFalse);
      // 回退到账户余额
      expect(y.endAssets, 0);
    });
  });
}
