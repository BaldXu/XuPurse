import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/domain/services/trend_service.dart';

/// 本地时区某天 0 点毫秒
int day(int y, int m, int d) => DateTime(y, m, d).millisecondsSinceEpoch;

Account _account({
  required String id,
  required String category,
  int currentBalance = 0,
  bool includeInAssets = true,
}) => Account(
  id: id,
  name: id,
  category: category,
  type: 'alipay',
  initialBalance: 0,
  currentBalance: currentBalance,
  currency: 'CNY',
  includeInAssets: includeInAssets,
  enabled: true,
  createdAt: 1,
  updatedAt: 1,
);

BalanceSnapshot _snap({
  required String accountId,
  required int balance,
  required int timestamp,
}) => BalanceSnapshot(
  id: 's_${accountId}_$timestamp',
  accountId: accountId,
  balance: balance,
  timestamp: timestamp,
  isValid: true,
  type: SnapshotType.historical,
);

void main() {
  group('buildTrendPoints（算法五）', () {
    test('期初锚点：窗口外最近一条快照作为近 30 天起点（不被丢弃）', () {
      // 账户唯一快照在 start 前（40 天前），近 30 天窗口内无新快照
      final start = day(2026, 8, 1);
      final snap = _snap(
        accountId: 'a1',
        balance: 700000000, // 7 万元
        timestamp: day(2026, 6, 22),
      );
      final points = buildTrendPoints(
        snaps: [snap],
        assetIds: {'a1'},
        accounts: [_account(id: 'a1', category: 'fund')],
        start: start,
        end: day(2026, 8, 30),
      );

      expect(points, isNotEmpty);
      expect(points.first.day, day(2026, 8, 1));
      expect(
        points.first.value,
        700000000,
        reason: '期初应为 start 之前最近一条快照余额，而非 0/缺失',
      );
      expect(points.last.value, 700000000);
    });

    test('多账户求和：窗口内每天取最后快照 + 无快照账户用当前余额平直', () {
      // a1：3 条快照（d1 在窗口前，d15/d20 在窗口内）
      // a2：无快照 → 用当前余额 20 万元平直
      final a1 = _account(id: 'a1', category: 'fund');
      final a2 = _account(
        id: 'a2',
        category: 'fund',
        currentBalance: 2000000000, // 20 万元
      );
      final start = day(2026, 8, 10);
      final points = buildTrendPoints(
        snaps: [
          _snap(
            accountId: 'a1',
            balance: 700000000,
            timestamp: day(2026, 8, 1),
          ),
          _snap(
            accountId: 'a1',
            balance: 800000000,
            timestamp: day(2026, 8, 15),
          ),
          _snap(
            accountId: 'a1',
            balance: 900000000,
            timestamp: day(2026, 8, 20),
          ),
        ],
        assetIds: {'a1', 'a2'},
        accounts: [a1, a2],
        start: start,
        end: day(2026, 8, 25),
      );

      // d10（期初）：a1 用 8/1 快照 7 万 + a2 20 万 = 27 万元
      expect(points.first.day, day(2026, 8, 10));
      expect(points.first.value, 2700000000);
      // d15：a1 8 万 + a2 20 万 = 28 万元
      final d15 = points.firstWhere((p) => p.day == day(2026, 8, 15));
      expect(d15.value, 2800000000);
      // d20：a1 9 万 + a2 20 万 = 29 万元
      final d20 = points.firstWhere((p) => p.day == day(2026, 8, 20));
      expect(d20.value, 2900000000);
      // d25（end 天）：延续最后快照值 29 万元
      expect(points.last.day, day(2026, 8, 25));
      expect(points.last.value, 2900000000);
    });

    test('全部视图：从最早快照天开始，end 天沿用最后值', () {
      final points = buildTrendPoints(
        snaps: [
          _snap(
            accountId: 'a1',
            balance: 500000000,
            timestamp: day(2026, 1, 1),
          ),
          _snap(
            accountId: 'a1',
            balance: 600000000,
            timestamp: day(2026, 1, 5),
          ),
        ],
        assetIds: {'a1'},
        accounts: [_account(id: 'a1', category: 'fund')],
        start: null,
        end: day(2026, 1, 10),
      );

      expect(points.first.day, day(2026, 1, 1));
      expect(points.first.value, 500000000);
      expect(points.last.day, day(2026, 1, 10));
      expect(points.last.value, 600000000, reason: 'end 天沿用最后一条快照余额');
    });

    test('非资产账户（debt 未纳入）不计入总资产', () {
      final a1 = _account(
        id: 'a1',
        category: 'fund',
        currentBalance: 100000000,
      );
      // a2 快照存在，但 assetIds 不含（includeInAssets=false）
      final points = buildTrendPoints(
        snaps: [
          _snap(
            accountId: 'a2',
            balance: 999999999,
            timestamp: day(2026, 8, 1),
          ),
        ],
        assetIds: {'a1'},
        accounts: [
          a1,
          _account(
            id: 'a2',
            category: 'debt',
            currentBalance: 999999999,
            includeInAssets: false,
          ),
        ],
        start: day(2026, 8, 1),
        end: day(2026, 8, 2),
      );

      expect(points, isNotEmpty);
      expect(points.first.value, 100000000, reason: '仅含 a1 当前余额');
    });

    test('窗口内无任何数据且无兜底账户 → 返回空', () {
      final points = buildTrendPoints(
        snaps: const [],
        assetIds: {'a1'},
        accounts: const [],
        start: day(2026, 8, 1),
        end: day(2026, 8, 30),
      );
      expect(points, isEmpty);
    });
  });
}
