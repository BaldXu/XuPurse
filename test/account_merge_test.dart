import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/domain/services/account_service.dart';
import 'package:xupurse/domain/services/bill_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseManager mgr;
  late AccountService accounts;
  late BillService bills;

  setUp(() async {
    mgr = DatabaseManager.inMemory();
    await mgr.createBook(name: '测试账本');
    final db = mgr.current;
    accounts = AccountService(db);
    bills = BillService(db);
    await db.delete(db.accounts).go();
    // 两个账户 + 转移等引用
    for (final (id, name, bal) in [
      ('acc-a', '招商', 1000000),
      ('acc-b', '招商银行', 2000000),
    ]) {
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: id,
              name: name,
              category: 'fund',
              type: 'bank',
              initialBalance: Value(bal),
              currentBalance: Value(bal),
              createdAt: 1,
              updatedAt: 1,
            ),
          );
    }
  });

  test('合并账户：账单/快照/转账引用重定向 + 被合并账户删除 + 可重命名', () async {
    final db = mgr.current;

    // 在 acc-a 上记一笔支出
    await bills.addBill(
      type: BillType.expense,
      categoryId: 'cat-x',
      amount: 10000,
      accountId: 'acc-a',
      time: 1700000000000,
    );
    // 在 acc-b 上记一笔收入
    await bills.addBill(
      type: BillType.income,
      categoryId: 'cat-y',
      amount: 50000,
      accountId: 'acc-b',
      time: 1700000001000,
    );
    // acc-a → acc-b 转账（含手续费）
    await bills.addBill(
      type: BillType.transfer,
      categoryId: 'cat-t',
      amount: 30000,
      accountId: 'acc-a',
      incomeAccountId: 'acc-b',
      time: 1700000002000,
      transferToAmount: 29500,
    );

    // 导入映射：acc-a 曾由第三方映射而来
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.importMappings)
        .insert(
          ImportMappingsCompanion.insert(
            id: 'm1',
            provider: 'yimu',
            entityType: 'account',
            sourceId: '11',
            targetId: 'acc-a',
            createdAt: now,
            updatedAt: now,
          ),
        );

    // 执行合并：acc-a → acc-b，重命名 acc-b
    await accounts.mergeAccounts(
      targetId: 'acc-b',
      sourceIds: ['acc-a'],
      newName: '招商银行（合并）',
    );

    final remaining = await db.select(db.accounts).get();
    expect(remaining.length, 1);
    expect(remaining.single.name, '招商银行（合并）');

    // 所有账单都指向 acc-b（含转账转入端）
    final billRows = await db.select(db.bills).get();
    expect(billRows.length, 3);
    for (final b in billRows) {
      expect(b.accountId, 'acc-b');
      if (b.incomeAccountId != null) expect(b.incomeAccountId, 'acc-b');
    }
    // 快照引用重定向
    final snaps = await db.select(db.balanceSnapshots).get();
    expect(snaps, isNotEmpty);
    for (final s in snaps) {
      expect(s.accountId, 'acc-b');
    }
    // 转账扩展重定向
    final transfers = await db.select(db.transfers).get();
    expect(transfers.single.fromAccountId, 'acc-b');
    expect(transfers.single.toAccountId, 'acc-b');
    // 导入映射重定向（再次导入一木同一文件不会重建 acc-a）
    final mapping = await db.select(db.importMappings).getSingle();
    expect(mapping.targetId, 'acc-b');
  });

  test('合并后保留账户余额为原值', () async {
    final db = mgr.current;
    await accounts.mergeAccounts(targetId: 'acc-b', sourceIds: ['acc-a']);
    final accB = await (db.select(
      db.accounts,
    )..where((t) => t.id.equals('acc-b'))).getSingle();
    expect(accB.currentBalance, 2000000, reason: '余额以保留账户为准');
  });

  test('批量改币种', () async {
    final db = mgr.current;
    await accounts.setCurrencies(['acc-a', 'acc-b'], 'USD');
    final all = await db.select(db.accounts).get();
    for (final a in all) {
      expect(a.currency, 'USD');
    }
  });

  test('lastActiveTimes：取账户 updatedAt / 最近账单 / 最近快照的最大值', () async {
    // acc-a 无账单：最后活跃 = updatedAt（1）
    // acc-b 加一笔收入（记账会刷新 updatedAt 并写快照，时间 1700000100000）
    await bills.addBill(
      type: BillType.income,
      categoryId: 'cat-y',
      amount: 50000,
      accountId: 'acc-b',
      time: 1700000100000,
    );
    final active = await accounts.lastActiveTimes(['acc-a', 'acc-b']);
    expect(active['acc-a'], 1);
    expect(active['acc-b']!, greaterThanOrEqualTo(1700000100000));
    expect(active['acc-b']!, greaterThan(active['acc-a']!));
    expect(active.containsKey('unknown-id'), isFalse, reason: '不存在的账户不返回');
  });
}
