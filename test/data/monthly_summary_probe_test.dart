import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/repositories/bill_repository.dart';

void main() {
  late AppDatabase db;
  late BillRepository bills;
  late int now;

  setUp(() async {
    db = AppDatabase.memory();
    bills = BillRepository(db);
    now = DateTime(2026, 8, 15, 12).millisecondsSinceEpoch; // 固定本地 2026-08-15
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBill({
    required BillType type,
    required int amount,
    required int time,
    String? extra,
  }) async {
    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            id: 'probe-$time-$amount-$type.name-${extra ?? ''}',
            type: type.name,
            categoryId: 'cat-x',
            amount: amount,
            time: time,
            extra: Value(extra),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  test('watchMonthlySummaryInRange 按月分组收支', () async {
    // 2026-07: 支出 300 > 收入 200（超支）
    await insertBill(
      type: BillType.expense,
      amount: 30000,
      time: DateTime(2026, 7, 3, 10).millisecondsSinceEpoch,
    );
    await insertBill(
      type: BillType.income,
      amount: 20000,
      time: DateTime(2026, 7, 5, 10).millisecondsSinceEpoch,
    );
    // 2026-08: 支出 100 < 收入 1000（正常）
    await insertBill(
      type: BillType.expense,
      amount: 10000,
      time: DateTime(2026, 8, 2, 10).millisecondsSinceEpoch,
    );
    await insertBill(
      type: BillType.income,
      amount: 100000,
      time: DateTime(2026, 8, 4, 10).millisecondsSinceEpoch,
    );
    // 2026-06: 仅收入（expense=0）
    await insertBill(
      type: BillType.income,
      amount: 50000,
      time: DateTime(2026, 6, 10, 10).millisecondsSinceEpoch,
    );
    // 2026-05: 全部为「不计入收支」账单——列表照常展示，条也应计入
    await insertBill(
      type: BillType.expense,
      amount: 7000,
      time: DateTime(2026, 5, 3, 10).millisecondsSinceEpoch,
      extra: '{"excludeFromStats":true}',
    );

    final start = DateTime(2026, 5, 1).millisecondsSinceEpoch;
    final end = DateTime(2026, 8, 16).millisecondsSinceEpoch;
    final rows = await bills.watchMonthlySummaryInRange(start, end).first;

    expect(rows, hasLength(4));
    final byKey = {for (final r in rows) '${r.year}-${r.month}': r};
    expect(byKey['2026-8']!.expense, 10000);
    expect(byKey['2026-8']!.income, 100000);
    expect(byKey['2026-7']!.expense, 30000);
    expect(byKey['2026-7']!.income, 20000);
    expect(byKey['2026-6']!.expense, 0);
    expect(byKey['2026-6']!.income, 50000);
    // 「不计入收支」账单计入月汇总（与明细列表口径一致）
    expect(byKey['2026-5']!.expense, 7000);
    expect(byKey['2026-5']!.income, 0);
  });
}
