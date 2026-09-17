import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/domain/services/bill_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseManager mgr;
  late BillService service;

  setUp(() async {
    mgr = DatabaseManager.inMemory();
    await mgr.createBook(name: '测试账本');
    final db = mgr.current;
    service = BillService(db);
    // 清空种子账户，建立两个测试账户
    await db.delete(db.accounts).go();
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: 'acc-a',
            name: '账户A',
            category: 'fund',
            type: 'bank',
            initialBalance: Value(1000000),
            currentBalance: Value(1000000),
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: 'acc-b',
            name: '账户B',
            category: 'fund',
            type: 'bank',
            initialBalance: Value(500000),
            currentBalance: Value(500000),
            createdAt: 1,
            updatedAt: 1,
          ),
        );
  });

  test('转账含手续费：转出 -amount、转入 +toAmount，Transfers 表记录 fee', () async {
    final db = mgr.current;
    final billId = await service.addBill(
      type: BillType.transfer,
      categoryId: 'transfer-cat',
      amount: 300000, // 30 元
      accountId: 'acc-a',
      incomeAccountId: 'acc-b',
      time: 1700000000000,
      comment: '转账',
      transferToAmount: 295000, // 手续费 0.5 元
    );

    final a = await (db.select(
      db.accounts,
    )..where((t) => t.id.equals('acc-a'))).getSingle();
    final b = await (db.select(
      db.accounts,
    )..where((t) => t.id.equals('acc-b'))).getSingle();
    expect(a.currentBalance, 700000, reason: '转出扣 30 元');
    expect(b.currentBalance, 795000, reason: '转入 +29.5 元');

    final transfer = await (db.select(
      db.transfers,
    )..where((t) => t.billId.equals(billId))).getSingle();
    expect(transfer.fromAccountId, 'acc-a');
    expect(transfer.toAccountId, 'acc-b');
    expect(transfer.amount, 300000);
    expect(transfer.toAmount, 295000);
    expect(transfer.fee, 5000);

    // 快照：转出 type=3、转入 type=4
    final snapshots = await db.select(db.balanceSnapshots).get();
    expect(snapshots.length, 2);
    expect(snapshots.any((s) => s.type == SnapshotType.transferOut), isTrue);
    expect(snapshots.any((s) => s.type == SnapshotType.transferIn), isTrue);
  });

  test('删除转账账单：余额回滚 + Transfers 记录删除', () async {
    final db = mgr.current;
    final billId = await service.addBill(
      type: BillType.transfer,
      categoryId: 'transfer-cat',
      amount: 300000,
      accountId: 'acc-a',
      incomeAccountId: 'acc-b',
      time: 1700000000000,
      transferToAmount: 295000,
    );

    await service.deleteBill(billId);

    final a = await (db.select(
      db.accounts,
    )..where((t) => t.id.equals('acc-a'))).getSingle();
    final b = await (db.select(
      db.accounts,
    )..where((t) => t.id.equals('acc-b'))).getSingle();
    expect(a.currentBalance, 1000000);
    expect(b.currentBalance, 500000);
    final transfers = await (db.select(
      db.transfers,
    )..where((t) => t.billId.equals(billId))).get();
    expect(transfers, isEmpty);
  });

  test('修改转账手续费：转入端余额按新到账金额联动，Transfers 更新', () async {
    final db = mgr.current;
    final billId = await service.addBill(
      type: BillType.transfer,
      categoryId: 'transfer-cat',
      amount: 300000,
      accountId: 'acc-a',
      incomeAccountId: 'acc-b',
      time: 1700000000000,
      transferToAmount: 295000,
    );

    // 改手续费：到账 290000（手续费 1 元）
    await service.updateBill(billId, transferToAmount: 290000);

    final b = await (db.select(
      db.accounts,
    )..where((t) => t.id.equals('acc-b'))).getSingle();
    expect(b.currentBalance, 790000);
    final transfer = await (db.select(
      db.transfers,
    )..where((t) => t.billId.equals(billId))).getSingle();
    expect(transfer.toAmount, 290000);
    expect(transfer.fee, 10000);
  });
}
