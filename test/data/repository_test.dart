import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/repositories/account_repository.dart';
import 'package:xupurse/data/repositories/bill_repository.dart';
import 'package:xupurse/data/repositories/category_repository.dart';
import 'package:xupurse/data/repositories/snapshot_repository.dart';
import 'package:xupurse/data/repositories/tag_repository.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late BillRepository bills;
  late SnapshotRepository snapshots;
  late TagRepository tags;
  late int now;

  setUp(() async {
    db = AppDatabase.memory();
    accounts = AccountRepository(db);
    categories = CategoryRepository(db);
    bills = BillRepository(db);
    snapshots = SnapshotRepository(db);
    tags = TagRepository(db);
    now = DateTime.now().millisecondsSinceEpoch;
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> insertAccount({
    String name = '测试账户',
    String category = 'fund',
    String type = 'cash',
    int initialBalance = 0,
  }) async {
    final id = 'acc-${name.hashCode.abs()}';
    await accounts.insert(
      AccountsCompanion.insert(
        id: id,
        name: name,
        category: category,
        type: type,
        initialBalance: Value(initialBalance),
        currentBalance: Value(initialBalance),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<String> insertCategory(String name, BillType type) async {
    final id = 'cat-$name';
    await categories.insert(
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
    String? accountId,
    String? incomeAccountId,
    required int time,
  }) async {
    final id = 'bill-${bills.hashCode.abs()}-$time-$amount';
    await bills.insert(
      BillsCompanion.insert(
        id: id,
        type: type.name,
        categoryId: categoryId,
        amount: amount,
        accountId: Value(accountId),
        incomeAccountId: Value(incomeAccountId),
        time: time,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  group('AccountRepository', () {
    test('insert / getById / findByName', () async {
      final id = await insertAccount(name: '钱包');
      final acc = await accounts.getById(id);
      expect(acc, isNotNull);
      expect(acc!.name, '钱包');

      final byName = await accounts.findByName('钱包');
      expect(byName!.id, id);
      expect(await accounts.findByName('不存在'), isNull);
    });

    test('setBalance / addBalance', () async {
      final id = await insertAccount(initialBalance: 100000);
      await accounts.addBalance(id, -30000);
      expect((await accounts.getById(id))!.currentBalance, 70000);

      await accounts.setBalance(id, 99999);
      expect((await accounts.getById(id))!.currentBalance, 99999);
    });

    test('totalAssets 只统计 fund + includeInAssets + enabled', () async {
      await insertAccount(name: '现金', initialBalance: 50000);
      await insertAccount(name: '银行卡', type: 'bank', initialBalance: 100000);
      final debtId = await insertAccount(
        name: '花呗',
        category: 'debt',
        type: 'credit',
        initialBalance: 20000,
      );
      expect(await accounts.totalAssets(), 150000);

      // 排除资产统计的账户
      await accounts.update(
        debtId,
        const AccountsCompanion(includeInAssets: Value(false)),
      );
      expect(await accounts.totalAssets(), 150000);

      // 停用账户不计入
      await accounts.update(
        debtId,
        const AccountsCompanion(enabled: Value(false)),
      );
      expect(await accounts.totalAssets(), 150000);
    });

    test('enabledOnly 过滤', () async {
      final id = await insertAccount(name: '停用账户');
      await accounts.update(id, const AccountsCompanion(enabled: Value(false)));
      expect((await accounts.getAll(enabledOnly: true)), isEmpty);
      expect((await accounts.getAll()), hasLength(1));
    });

    test('getAssetAccounts 排除 debt', () async {
      await insertAccount(name: '现金');
      await insertAccount(name: '花呗', category: 'debt', type: 'credit');
      final assetAccounts = await accounts.getAssetAccounts();
      expect(assetAccounts, hasLength(1));
      expect(assetAccounts.single.name, '现金');
    });
  });

  group('CategoryRepository', () {
    test('getByType / findByName', () async {
      await insertCategory('餐饮', BillType.expense);
      await insertCategory('工资', BillType.income);

      expect((await categories.getByType(BillType.expense)).single.name, '餐饮');
      expect((await categories.getByType(BillType.income)).single.name, '工资');
      final found = await categories.findByName(BillType.expense, '餐饮');
      expect(found, isNotNull);
      // 类型不匹配查不到
      expect(await categories.findByName(BillType.income, '餐饮'), isNull);
    });

    test('countChildren', () async {
      final parentId = await insertCategory('购物', BillType.expense);
      await insertCategory('服装', BillType.expense);
      final childId = 'cat-服装';
      await categories.update(
        childId,
        CategoriesCompanion(parentId: Value(parentId)),
      );
      expect(await categories.countChildren(parentId), 1);
      expect(await categories.countChildren(childId), 0);
    });
  });

  group('BillRepository', () {
    late String foodCatId, salaryCatId, accA, accB;

    setUp(() async {
      foodCatId = await insertCategory('餐饮', BillType.expense);
      salaryCatId = await insertCategory('工资', BillType.income);
      accA = await insertAccount(name: 'A');
      accB = await insertAccount(name: 'B');
    });

    test('insert / getById / watchPage 时间倒序', () async {
      final t0 = now - 10000;
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: t0,
      );
      await insertBill(
        type: BillType.income,
        categoryId: salaryCatId,
        amount: 500000,
        accountId: accA,
        time: now,
      );

      final list = await bills.watchPage().first;
      expect(list, hasLength(2));
      expect(list.first.time, now); // 新的在前
    });

    test('watchPage 按类型过滤', () async {
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: now,
      );
      await insertBill(
        type: BillType.income,
        categoryId: salaryCatId,
        amount: 500000,
        accountId: accA,
        time: now,
      );

      final expenses = await bills.watchPage(type: BillType.expense).first;
      expect(expenses, hasLength(1));
      expect(expenses.single.type, 'expense');
    });

    test('watchPage 按账户过滤（含转账双方）', () async {
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: now,
      );
      await insertBill(
        type: BillType.transfer,
        categoryId: foodCatId,
        amount: 2000,
        accountId: accA,
        incomeAccountId: accB,
        time: now,
      );

      final ofA = await bills.watchPage(accountId: accA).first;
      expect(ofA, hasLength(2));
      final ofB = await bills.watchPage(accountId: accB).first;
      expect(ofB, hasLength(1));
    });

    test('watchPage 时间段过滤', () async {
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: 1000,
      );
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 2000,
        accountId: accA,
        time: 5000,
      );
      final list = await bills.watchPage(start: 1000, end: 5000).first;
      expect(list, hasLength(1));
      expect(list.single.amount, 1000);
    });

    test('sumByType 按类型汇总', () async {
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: now,
      );
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 2000,
        accountId: accA,
        time: now,
      );
      await insertBill(
        type: BillType.income,
        categoryId: salaryCatId,
        amount: 500000,
        accountId: accA,
        time: now,
      );

      final total = await bills.sumByType(0, now + 1, BillType.expense);
      expect(total, 3000);
      final income = await bills.sumByType(0, now + 1, BillType.income);
      expect(income, 500000);
    });

    test('countByAccountId 双方都计数', () async {
      await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: now,
      );
      await insertBill(
        type: BillType.transfer,
        categoryId: foodCatId,
        amount: 2000,
        accountId: accA,
        incomeAccountId: accB,
        time: now,
      );
      expect(await bills.countByAccountId(accA), 2);
      expect(await bills.countByAccountId(accB), 1);
    });

    test('setBillTags / tagIdsOf 整体替换', () async {
      final billId = await insertBill(
        type: BillType.expense,
        categoryId: foodCatId,
        amount: 1000,
        accountId: accA,
        time: now,
      );
      final tag1 = 'tag-1', tag2 = 'tag-2';
      await tags.insert(
        TagsCompanion.insert(
          id: tag1,
          name: '旅行',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tags.insert(
        TagsCompanion.insert(
          id: tag2,
          name: '工作',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await bills.setBillTags(billId, [tag1, tag2]);
      expect(await bills.tagIdsOf(billId), unorderedEquals([tag1, tag2]));

      await bills.setBillTags(billId, [tag1]);
      expect(await bills.tagIdsOf(billId), [tag1]);
    });
  });

  group('SnapshotRepository', () {
    test('insert / latestByAccount / listByAccount', () async {
      final accId = await insertAccount(name: '快照账户');
      await snapshots.insert(
        BalanceSnapshotsCompanion.insert(
          id: 'snap-1',
          accountId: accId,
          balance: 100000,
          timestamp: now,
          type: SnapshotType.manual,
        ),
      );
      await snapshots.insert(
        BalanceSnapshotsCompanion.insert(
          id: 'snap-2',
          accountId: accId,
          balance: 90000,
          timestamp: now + 1,
          type: SnapshotType.expense,
          billId: const Value('bill-x'),
        ),
      );

      final latest = await snapshots.latestByAccount(accId);
      expect(latest!.id, 'snap-2');

      final list = await snapshots.listByAccount(accId);
      expect(list.map((s) => s.id).toList(), ['snap-1', 'snap-2']); // 升序
    });

    test('invalidateByBill 失效后 validOnly 查询排除', () async {
      final accId = 'acc-snap';
      await accounts.insert(
        AccountsCompanion.insert(
          id: accId,
          name: 'S',
          category: 'fund',
          type: 'cash',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await snapshots.insert(
        BalanceSnapshotsCompanion.insert(
          id: 'snap-a',
          accountId: accId,
          balance: 100,
          timestamp: now,
          type: SnapshotType.expense,
          billId: const Value('bill-z'),
        ),
      );
      await snapshots.invalidateByBill('bill-z');
      expect(await snapshots.listByAccount(accId), isEmpty);
      expect(
        (await snapshots.listByAccount(accId, validOnly: false)),
        hasLength(1),
      );
      expect(await snapshots.listByBill('bill-z'), hasLength(1));
    });
  });
}
