import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/core/errors.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/data/repositories/bill_repository.dart';
import 'package:xupurse/domain/services/bill_service.dart';
import 'package:xupurse/domain/services/refund_service.dart';

/// 支出退款（明细页「退款」录入）：
/// - 数据库同时保留「原本 100 元支出」与「20 元退款」两条记录（绝不改写 amount）；
/// - 展示与月/年统计按净额 100 − 20 = 80；
/// - 退款**不计入收入**，只冲减原支出，并把钱退回原账户。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseManager mgr;
  late AppDatabase db;
  late BillService bills;
  late RefundService refunds;
  late BillRepository repo;
  late String accountId;
  late String expenseCategoryId;
  late String incomeCategoryId;

  int ts(int month, int day) =>
      DateTime(2026, month, day, 12).millisecondsSinceEpoch;

  final juneStart = DateTime(2026, 6, 1).millisecondsSinceEpoch;
  final julyStart = DateTime(2026, 7, 1).millisecondsSinceEpoch;
  final augStart = DateTime(2026, 8, 1).millisecondsSinceEpoch;

  setUp(() async {
    mgr = DatabaseManager.inMemory();
    await mgr.createBook(name: '测试账本');
    db = mgr.current;
    bills = BillService(db);
    refunds = RefundService(db);
    repo = BillRepository(db);
    accountId = (await (db.select(db.accounts)).get()).first.id;
    final cats = await (db.select(
      db.categories,
    )..where((t) => t.parentId.isNull())).get();
    expenseCategoryId = cats.firstWhere((c) => c.type == 'expense').id;
    incomeCategoryId = cats.firstWhere((c) => c.type == 'income').id;
  });

  Future<String> addExpense({int amount = 1000000, int? time}) => bills.addBill(
    type: BillType.expense,
    categoryId: expenseCategoryId,
    amount: amount,
    accountId: accountId,
    time: time ?? ts(6, 10),
  );

  Future<String> addIncome({int amount = 500000, int? time}) => bills.addBill(
    type: BillType.income,
    categoryId: incomeCategoryId,
    amount: amount,
    accountId: accountId,
    time: time ?? ts(6, 12),
  );

  Future<Bill> billOf(String id) =>
      (db.select(db.bills)..where((t) => t.id.equals(id))).getSingle();

  Future<int> balanceOf([String? id]) async => (await (db.select(
    db.accounts,
  )..where((t) => t.id.equals(id ?? accountId))).getSingle()).currentBalance;

  Future<List<Refund>> refundRows() => db.select(db.refunds).get();

  group('退款落库：原支出与退款两条记录并存', () {
    test('录入退款不改写原支出金额，refunds 表新增一条退款记录', () async {
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);

      final bill = await billOf(id);
      expect(bill.amount, 1000000, reason: '原本 100 元支出必须原样保留');
      expect(bill.type, 'expense');

      final rows = await refundRows();
      expect(rows.length, 1);
      expect(rows.single.billId, id);
      expect(rows.single.amount, 200000, reason: '20 元退款作为独立记录存在');
      expect(rows.single.time, bill.time, reason: '退款归集到原账单所在月份');
    });

    test('重复保存同一金额不会重复加钱、不会写出多条退款', () async {
      final before = await balanceOf();
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);
      await refunds.setRefund(billId: id, amount: 200000);

      expect((await refundRows()).length, 1);
      expect(await balanceOf(), before - 800000);
    });
  });

  group('统计口径：支出按净额，退款不计入收入', () {
    test('支出汇总 = 金额 − 退款；收入不受退款影响', () async {
      final id = await addExpense();
      await addIncome();
      await refunds.setRefund(billId: id, amount: 200000);

      expect(
        await repo.sumByType(juneStart, julyStart, BillType.expense),
        800000,
        reason: '原本 100 元支出退了 20 → 月支出按 80 计',
      );
      expect(
        await repo.sumByType(juneStart, julyStart, BillType.income),
        500000,
        reason: '退款不计入收入',
      );
    });

    test('收支柱出（首页月汇总/AI 摘要）支出按净额', () async {
      final id = await addExpense();
      await addIncome();
      await refunds.setRefund(billId: id, amount: 200000);

      final summary = await repo.summaryInRangeOnce(juneStart, julyStart);
      expect(summary.expense, 800000);
      expect(summary.income, 500000);
    });

    test('分类汇总按净额，退款仍记在原账单分类上', () async {
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);

      final byCat = await repo.sumByCategoryInRange(
        juneStart,
        julyStart,
        BillType.expense,
      );
      expect(byCat.length, 1);
      expect(byCat.single.categoryId, expenseCategoryId);
      expect(byCat.single.amount, 800000);
    });

    test('净额冲减落在原支出所在月份，不会跑到退款发生月', () async {
      final id = await addExpense(time: ts(6, 10));
      await refunds.setRefund(billId: id, amount: 200000);

      expect(
        await repo.sumByType(juneStart, julyStart, BillType.expense),
        800000,
      );
      expect(await repo.sumByType(julyStart, augStart, BillType.expense), 0);
    });

    test('退款写入后统计流自动按净额重算（readsFrom 含退款表）', () async {
      final id = await addExpense();
      final stream = repo.watchSummaryInRange(juneStart, julyStart);
      final seen = <int>[];
      final sub = stream.listen((s) => seen.add(s.expense));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(seen.last, 1000000);

      await refunds.setRefund(billId: id, amount: 200000);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(seen.last, 800000);
    });

    test('netAmountOf：只扣减支出账单，收入账单原样返回', () async {
      final eid = await addExpense();
      final iid = await addIncome();
      final e = await billOf(eid);
      final i = await billOf(iid);

      expect(netAmountOf(e, {eid: 200000}), 800000);
      expect(netAmountOf(e, const {}), 1000000);
      expect(netAmountOf(i, {iid: 200000}), 500000, reason: '收入账单永不因退款被扣减');
    });
  });

  group('余额与快照：退款把钱退回原账户', () {
    test('退款后账户余额回到净支出，并写 type=7 退款快照', () async {
      final before = await balanceOf();
      final id = await addExpense();
      expect(await balanceOf(), before - 1000000);

      await refunds.setRefund(billId: id, amount: 200000);
      expect(await balanceOf(), before - 800000);

      final snaps = await (db.select(
        db.balanceSnapshots,
      )..where((t) => t.billId.equals(id))).get();
      expect(snaps.any((s) => s.type == SnapshotType.refund), isTrue);
    });

    test('清空退款（填 0）：记录删除、余额回退、统计恢复原金额', () async {
      final before = await balanceOf();
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);

      await refunds.setRefund(billId: id, amount: 0);

      expect(await refundRows(), isEmpty);
      expect(await balanceOf(), before - 1000000);
      expect(
        await repo.sumByType(juneStart, julyStart, BillType.expense),
        1000000,
      );
    });

    test('删除账单：退款记录一并删除，余额回到初始', () async {
      final before = await balanceOf();
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);

      await bills.deleteBill(id);

      expect(await refundRows(), isEmpty);
      expect(await balanceOf(), before);
    });

    test('编辑账单换账户：退款回补跟着账户走', () async {
      final before = await balanceOf();
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'acc2',
              name: '现金B',
              category: 'fund',
              type: 'cash',
              initialBalance: const Value(0),
              currentBalance: const Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);

      await bills.updateBill(id, accountId: 'acc2');

      expect(await balanceOf(), before, reason: '原账户退回初始余额');
      expect(await balanceOf('acc2'), -800000, reason: '新账户净支出 80');
    });

    test('全量重算（算法三）把退款回补算进余额', () async {
      final before = await balanceOf();
      final id = await addExpense();
      await refunds.setRefund(billId: id, amount: 200000);

      // 人为破坏余额后重算，应恢复为「初始 − 80」
      await (db.update(db.accounts)..where((t) => t.id.equals(accountId)))
          .write(const AccountsCompanion(currentBalance: Value(123456)));
      await bills.recalculateAllBalances();

      expect(await balanceOf(), before - 800000);
    });
  });

  group('校验', () {
    test('退款金额不能超过支出金额', () async {
      final id = await addExpense(amount: 1000000);
      expect(
        () => refunds.setRefund(billId: id, amount: 1000001),
        throwsA(isA<ValidationException>()),
      );
    });

    test('收入账单不能登记退款', () async {
      final id = await addIncome();
      expect(
        () => refunds.setRefund(billId: id, amount: 100),
        throwsA(isA<ValidationException>()),
      );
    });

    test('退款合计查询：无退款为 0', () async {
      final id = await addExpense();
      expect(await refunds.totalOf(id), 0);
      await refunds.setRefund(billId: id, amount: 200000);
      expect(await refunds.totalOf(id), 200000);
      expect((await refunds.totals())[id], 200000);
    });
  });
}
