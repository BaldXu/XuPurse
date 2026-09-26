import 'package:flutter_test/flutter_test.dart';
import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/core/errors.dart';
import 'package:xupurse/core/utils/amount.dart';
import 'package:xupurse/core/utils/bill_extra.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/data/repositories/bill_repository.dart';
import 'package:xupurse/data/repositories/snapshot_repository.dart';
import 'package:xupurse/domain/services/account_service.dart';
import 'package:xupurse/domain/services/bill_service.dart';
import 'package:xupurse/domain/services/currency_service.dart';

void main() {
  late DatabaseManager manager;
  late AppDatabase db;
  late AccountService accountService;
  late BillService billService;
  late SnapshotRepository snapshots;
  late BillRepository billRepo;
  late int now;

  setUp(() async {
    manager = DatabaseManager.inMemory();
    final bookId = await manager.createBook(name: '服务测试');
    db = await manager.openBook(bookId);
    accountService = AccountService(db);
    billService = BillService(db);
    snapshots = SnapshotRepository(db);
    billRepo = BillRepository(db);
    now = DateTime.now().millisecondsSinceEpoch;
  });

  tearDown(() async {
    await manager.dispose();
  });

  /// 建一个指定初始余额的测试账户
  Future<String> newAcc(
    String name, {
    int initial = 0,
    String category = 'fund',
    bool includeInAssets = true,
  }) => accountService.createAccount(
    name: name,
    category: AccountCategory.values.byName(category),
    type: AccountType.cash,
    initialBalance: initial,
    includeInAssets: includeInAssets,
  );

  Future<Account> acc(String id) async => (await accountService.getById(id))!;

  group('BillService.addBill 余额联动（算法一）', () {
    test('支出：余额减少 + 消费快照', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      final catId = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'food')
          .id;

      final billId = await billService.addBill(
        type: BillType.expense,
        categoryId: catId,
        amount: yuanToAmount(23.5),
        accountId: accId,
        time: now,
      );

      expect((await acc(accId)).currentBalance, yuanToAmount(76.5));
      final snap = await snapshots.listByBill(billId);
      expect(snap, hasLength(1));
      expect(snap.single.type, SnapshotType.expense);
      expect(snap.single.balance, yuanToAmount(76.5));
      expect(snap.single.isValid, isTrue);
    });

    test('收入：余额增加 + 收入快照', () async {
      final accId = await newAcc('钱包');
      final catId = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'wage')
          .id;

      await billService.addBill(
        type: BillType.income,
        categoryId: catId,
        amount: yuanToAmount(5000),
        accountId: accId,
        time: now,
      );

      expect((await acc(accId)).currentBalance, yuanToAmount(5000));
    });

    test('转账：双向变动 + 转出/转入两条快照', () async {
      final fromId = await newAcc('A', initial: yuanToAmount(1000));
      final toId = await newAcc('B');
      final catId = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'transfer')
          .id;

      final billId = await billService.addBill(
        type: BillType.transfer,
        categoryId: catId,
        amount: yuanToAmount(300),
        accountId: fromId,
        incomeAccountId: toId,
        time: now,
      );

      expect((await acc(fromId)).currentBalance, yuanToAmount(700));
      expect((await acc(toId)).currentBalance, yuanToAmount(300));
      final snpas = await snapshots.listByBill(billId);
      expect(snpas, hasLength(2));
      expect(snpas.map((s) => s.type).toSet(), {
        SnapshotType.transferOut,
        SnapshotType.transferIn,
      });
    });

    test('参数校验', () async {
      final accId = await newAcc('X');
      final catId = 'cat-fake';

      expect(
        () => billService.addBill(
          type: BillType.expense,
          categoryId: catId,
          amount: 0,
          accountId: accId,
          time: now,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => billService.addBill(
          type: BillType.transfer,
          categoryId: catId,
          amount: 100,
          accountId: accId,
          incomeAccountId: accId,
          time: now,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => billService.addBill(
          type: BillType.expense,
          categoryId: catId,
          amount: 100,
          accountId: null,
          time: now,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('BillService.updateBill / deleteBill', () {
    late String accId, catId, billId;
    setUp(() async {
      accId = await newAcc('测试现金', initial: yuanToAmount(100));
      catId = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'food')
          .id;
      billId = await billService.addBill(
        type: BillType.expense,
        categoryId: catId,
        amount: yuanToAmount(30),
        accountId: accId,
        time: now,
      );
    });

    test('修改金额：旧影响反向 + 新影响正向', () async {
      await billService.updateBill(billId, amount: yuanToAmount(45));

      // 100 - 30 = 70（旧），70 + 30 = 100，100 - 45 = 55
      expect((await acc(accId)).currentBalance, yuanToAmount(55));
      final oldSnaps = await snapshots.listByBill(billId);
      // 旧快照失效 + 新快照生效
      final valid = oldSnaps.where((s) => s.isValid).toList();
      final invalid = oldSnaps.where((s) => !s.isValid).toList();
      expect(valid, hasLength(1));
      expect(valid.single.balance, yuanToAmount(55));
      expect(invalid, hasLength(1));
    });

    test('支出改转账：账户影响正确重算', () async {
      final toId = await newAcc('B');
      await billService.updateBill(
        billId,
        type: BillType.transfer,
        accountId: accId,
        incomeAccountId: toId,
        amount: yuanToAmount(20),
      );

      // 100 - 30 + 30 - 20 = 80
      expect((await acc(accId)).currentBalance, yuanToAmount(80));
      expect((await acc(toId)).currentBalance, yuanToAmount(20));
    });

    test('删除账单：余额恢复 + 快照失效', () async {
      await billService.deleteBill(billId);

      expect((await acc(accId)).currentBalance, yuanToAmount(100));
      expect(await billRepo.getById(billId), isNull);
      final snaps = await snapshots.listByBill(billId);
      expect(snaps.where((s) => s.isValid), isEmpty);
      // 幂等删除
      await billService.deleteBill(billId);
    });
  });

  group('AccountService.setBalance 手动调账（算法二）', () {
    test('正向调账：调账账单 + MANUAL 快照 + 余额设值', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      final target = yuanToAmount(188.8);

      await accountService.setBalance(accId, target, note: '盘点');

      expect((await acc(accId)).currentBalance, target);
      final all = await billRepo.getAll();
      final adjust = all.singleWhere(
        (b) => b.extra?.contains('isAdjustment') == true,
      );
      expect(adjust.type, 'income');
      expect(adjust.amount, target - yuanToAmount(100));
      final snaps = await snapshots.listByBill(adjust.id);
      expect(snaps.single.type, SnapshotType.manual);
      expect(snaps.single.balance, target);
    });

    test('负向调账', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      await accountService.setBalance(accId, yuanToAmount(50));
      final all = await billRepo.getAll();
      final adjust = all.singleWhere(
        (b) => b.extra?.contains('isAdjustment') == true,
      );
      expect(adjust.type, 'expense');
      expect(adjust.amount, yuanToAmount(50));
    });

    test('generateBill=false：不生成调账账单，快照 billId 为空', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      final target = yuanToAmount(150);

      await accountService.setBalance(
        accId,
        target,
        note: '盘点',
        generateBill: false,
      );

      expect((await acc(accId)).currentBalance, target);
      // 不产生任何账单
      expect(await billRepo.getAll(), isEmpty);
      final snaps = await snapshots.listByAccount(accId, validOnly: false);
      final snap = snaps.single;
      expect(snap.type, SnapshotType.manual);
      expect(snap.balance, target);
      expect(snap.billId, isNull);
    });

    test('generateBill=true：生成调账账单，快照关联 billId', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      final target = yuanToAmount(150);

      await accountService.setBalance(
        accId,
        target,
        note: '盘点',
        generateBill: true,
      );

      final all = await billRepo.getAll();
      final adjust = all.singleWhere(
        (b) => b.extra?.contains('isAdjustment') == true,
      );
      expect(adjust.type, 'income');
      expect(adjust.amount, yuanToAmount(50));
      final snaps = await snapshots.listByBill(adjust.id);
      expect(snaps.single.billId, adjust.id);
    });

    test('diff == 0：不产生任何记录', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      await accountService.setBalance(accId, yuanToAmount(100));
      expect(await billRepo.getAll(), isEmpty);
      expect(await snapshots.listByAccount(accId, validOnly: false), isEmpty);
    });

    test('账户不存在抛错', () async {
      expect(
        () => accountService.setBalance('no-such', 100),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('AccountService 账户管理', () {
    test('创建账户：重名校验 + 余额初始化', () async {
      await newAcc('测试支付宝');
      expect(() => newAcc('测试支付宝'), throwsA(isA<ValidationException>()));
      final id = await newAcc('储蓄卡', initial: yuanToAmount(10));
      expect((await acc(id)).currentBalance, yuanToAmount(10));
    });

    test('删除账户：有账单拒绝，无账单可删', () async {
      final accId = await newAcc('待删');
      final catId = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'food')
          .id;
      await billService.addBill(
        type: BillType.expense,
        categoryId: catId,
        amount: 100,
        accountId: accId,
        time: now,
      );
      expect(
        () => accountService.deleteAccount(accId),
        throwsA(isA<ValidationException>()),
      );

      // 清空账单后可删
      for (final b in await billRepo.getAll()) {
        await billService.deleteBill(b.id);
      }
      await accountService.deleteAccount(accId);
      expect(await accountService.getById(accId), isNull);
    });

    test('watchTotalAssets 只统计资产账户', () async {
      await newAcc('测试现金', initial: yuanToAmount(100));
      // debt 默认 includeInAssets=true，计入总资产（口径对齐 cent-xyx）
      await newAcc('花呗', initial: yuanToAmount(999), category: 'debt');
      expect(
        await accountService.watchTotalAssets().first,
        yuanToAmount(100) + yuanToAmount(999),
      );

      // 排除资产统计后不计入
      await newAcc(
        '白条',
        initial: yuanToAmount(50),
        category: 'debt',
        includeInAssets: false,
      );
      expect(
        await accountService.watchTotalAssets().first,
        yuanToAmount(100) + yuanToAmount(999),
      );
    });
  });

  group('BillService.recalculateAllBalances 重算（算法三）', () {
    test('跳过调账与导入账单，普通账单累加', () async {
      final accId = await newAcc('重算账户', initial: yuanToAmount(10));
      final foodCat = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'food')
          .id;
      final wageCat = (await db.select(db.categories).get())
          .firstWhere((c) => c.seedKey == 'wage')
          .id;

      // 支出 -30、收入 +100 → 期望 10 - 30 + 100 = 80
      await billService.addBill(
        type: BillType.expense,
        categoryId: foodCat,
        amount: yuanToAmount(30),
        accountId: accId,
        time: now,
      );
      await billService.addBill(
        type: BillType.income,
        categoryId: wageCat,
        amount: yuanToAmount(100),
        accountId: accId,
        time: now,
      );
      // 手动调账把余额改成 1000（调账账单重算时跳过）
      await accountService.setBalance(accId, yuanToAmount(1000));

      // 用导入标记伪造一笔账单（重算跳过）
      await billService.addBill(
        type: BillType.expense,
        categoryId: foodCat,
        amount: yuanToAmount(777),
        accountId: accId,
        time: now,
        extra: const BillExtra(isYimu: true),
      );

      await billService.recalculateAllBalances();

      // 重算 = initial(10) - 30 + 100 = 80；调账(-900 效果)与导入账单跳过
      expect((await acc(accId)).currentBalance, yuanToAmount(80));
    });
  });

  group('AccountService.addHistoricalSnapshot 历史快照', () {
    test('新增 HISTORICAL 快照，不改变当前余额', () async {
      final accId = await newAcc('测试现金', initial: yuanToAmount(100));
      await accountService.addHistoricalSnapshot(
        accountId: accId,
        balance: yuanToAmount(66.6),
        timestamp: 1700000000000,
        note: '月末对账',
      );

      // 当前余额不变（历史快照只是记录，不参与余额）
      expect((await acc(accId)).currentBalance, yuanToAmount(100));
      final snaps = await snapshots.listByAccount(accId, validOnly: false);
      expect(snaps, hasLength(1));
      expect(snaps.single.type, SnapshotType.historical);
      expect(snaps.single.balance, yuanToAmount(66.6));
      expect(snaps.single.timestamp, 1700000000000);
      expect(snaps.single.note, '月末对账');
      expect(snaps.single.billId, isNull);
    });

    test('账户不存在抛错', () async {
      expect(
        () => accountService.addHistoricalSnapshot(
          accountId: 'no-such',
          balance: 100,
          timestamp: 1,
        ),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('多币种账单（外币记账）', () {
    Future<String> foodCat() async => (await db.select(db.categories).get())
        .firstWhere((c) => c.seedKey == 'food')
        .id;

    test('外币支出：amount 为账户币种换算值，余额按换算值变动，币种字段落库', () async {
      final accId = await newAcc('CNY现金', initial: yuanToAmount(100));
      final converted = convertAmount(
        yuanToAmount(100),
        'USD',
        'CNY',
        CurrencyService.builtinRates,
      );

      await billService.addBill(
        type: BillType.expense,
        categoryId: await foodCat(),
        amount: converted,
        accountId: accId,
        time: now,
        currencyCode: 'USD',
        currencyAmount: yuanToAmount(100),
        baseCurrency: 'CNY',
      );

      // 余额按换算后的账户币种金额变动（100 元 - 100 USD≈720 元）
      expect((await acc(accId)).currentBalance, yuanToAmount(100) - converted);
      final bill = (await billRepo.getAll()).single;
      expect(bill.currencyCode, 'USD');
      expect(bill.currencyAmount, yuanToAmount(100));
      expect(bill.baseCurrency, 'CNY');
    });

    test('updateBill 保留币种字段', () async {
      final accId = await newAcc('CNY现金', initial: yuanToAmount(100));
      final converted = convertAmount(
        yuanToAmount(50),
        'USD',
        'CNY',
        CurrencyService.builtinRates,
      );
      final billId = await billService.addBill(
        type: BillType.expense,
        categoryId: await foodCat(),
        amount: converted,
        accountId: accId,
        time: now,
        currencyCode: 'USD',
        currencyAmount: yuanToAmount(50),
        baseCurrency: 'CNY',
      );

      await billService.updateBill(billId, comment: '改备注不改币种');

      final bill = (await billRepo.getAll()).single;
      expect(bill.comment, '改备注不改币种');
      expect(bill.currencyCode, 'USD');
      expect(bill.currencyAmount, yuanToAmount(50));
    });
  });
}
