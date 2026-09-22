import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bill_repository.dart';
import '../../state/providers.dart';
import '../../domain/services/trend_service.dart';

/// 聊天时自动注入给 AI 的本机统计摘要（仅聚合口径，不含原始账单明细）。
class AiStatsContext {
  AiStatsContext(this._ref);

  /// 支持来自 Notifier 的 [Ref] 或 Widget 的 [WidgetRef]。
  final dynamic _ref;

  /// 生成统计摘要文本（Markdown，约 1-2K tokens）。
  ///
  /// [rangeDays] 控制月趋势回看的月数；账户/分类名照实输出（均为本地
  /// 自命名，非敏感卡号）。任何一步失败跳过该节，不影响整体生成。
  Future<String> build({int trendMonths = 6}) async {
    final billRepo = _ref.read(billRepoProvider);
    final accounts = _ref.read(accountsProvider).value ?? const <Account>[];
    final categories =
        _ref.read(categoriesProvider).value ?? const <Category>[];
    final catName = {for (final c in categories) c.id: c.name};

    final buf = StringBuffer();
    final now = DateTime.now();
    buf.writeln('## 本机统计摘要（应用自动附带，截止 ${now.year}/${now.month}/${now.day}）');

    // 1) 账户概况
    try {
      final assetAccounts = accounts.where((a) => a.enabled).toList();
      if (assetAccounts.isNotEmpty) {
        buf.writeln('\n### 账户余额');
        var total = 0;
        for (final a in assetAccounts) {
          buf.writeln('- ${a.name}（${a.category}）：${_yuan(a.currentBalance)}');
          total += a.currentBalance as int;
        }
        buf.writeln('- 合计余额：${_yuan(total)}');
      }
    } catch (_) {}

    // 2) 本月 / 上月收支
    try {
      final thisMonth = _monthRange(now, 0);
      final lastMonth = _monthRange(now, -1);
      final cur = await billRepo.summaryInRangeOnce(thisMonth.$1, thisMonth.$2);
      final prev = await billRepo.summaryInRangeOnce(
        lastMonth.$1,
        lastMonth.$2,
      );
      buf.writeln('\n### 月度收支');
      buf.writeln(
        '- 本月：支出 ${_yuan(cur.expense)}，收入 ${_yuan(cur.income)}，'
        '结余 ${_yuan(cur.income - cur.expense)}',
      );
      buf.writeln(
        '- 上月：支出 ${_yuan(prev.expense)}，收入 ${_yuan(prev.income)}，'
        '结余 ${_yuan(prev.income - prev.expense)}',
      );
    } catch (_) {}

    // 3) 本月分类 Top10
    try {
      final range = _monthRange(now, 0);
      final expenseTop = await billRepo.sumByCategoryInRange(
        range.$1,
        range.$2,
        BillType.expense,
      );
      final incomeTop = await billRepo.sumByCategoryInRange(
        range.$1,
        range.$2,
        BillType.income,
      );
      if (expenseTop.isNotEmpty) {
        buf.writeln('\n### 本月支出分类 Top10');
        for (final e
            in (expenseTop.toList()
                  ..sort((a, b) => b.amount.compareTo(a.amount)))
                .take(10)) {
          buf.writeln(
            '- ${catName[e.categoryId] ?? e.categoryId}：${_yuan(e.amount)}',
          );
        }
      }
      if (incomeTop.isNotEmpty) {
        buf.writeln('\n### 本月收入分类 Top10');
        for (final e
            in (incomeTop.toList()
                  ..sort((a, b) => b.amount.compareTo(a.amount)))
                .take(10)) {
          buf.writeln(
            '- ${catName[e.categoryId] ?? e.categoryId}：${_yuan(e.amount)}',
          );
        }
      }
    } catch (_) {}

    // 4) 近 N 个月趋势
    try {
      buf.writeln('\n### 近 $trendMonths 个月趋势');
      for (var i = trendMonths - 1; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i);
        final start = m.millisecondsSinceEpoch;
        final end = DateTime(m.year, m.month + 1).millisecondsSinceEpoch;
        final s = await _sumRange(billRepo, start, end);
        buf.writeln(
          '- ${m.year}/${m.month}：支出 ${_yuan(s.$1)}，收入 ${_yuan(s.$2)}',
        );
      }
    } catch (_) {}

    // 5) 资产趋势（近 90 天，周粒度）
    try {
      final snaps =
          _ref.read(snapshotsProvider).value ?? const <BalanceSnapshot>[];
      final assetIds = accounts
          .where(
            (a) =>
                a.enabled &&
                (a.category == 'fund' ||
                    ((a.category == 'debt' || a.category == 'record') &&
                        a.includeInAssets)),
          )
          .map((a) => a.id)
          .toSet();
      final start = now
          .subtract(const Duration(days: 90))
          .millisecondsSinceEpoch;
      final points = aggregateTrendPoints(
        buildTrendPoints(
          snaps: snaps,
          assetIds: assetIds,
          accounts: accounts,
          start: start,
          end: now.millisecondsSinceEpoch,
        ),
        TrendGranularity.week,
      );
      if (points.length >= 2) {
        buf.writeln('\n### 资产趋势（近 90 天，周粒度）');
        final first = points.first.value;
        final last = points.last.value;
        final change = last - first;
        buf.writeln(
          '- 期初 ${_yuan(first)} → 当前 ${_yuan(last)}'
          '（${change >= 0 ? '增长' : '下降'} ${_yuan(change.abs())}）',
        );
        // 峰值/谷值
        var maxP = points.first;
        var minP = points.first;
        for (final p in points) {
          if (p.value > maxP.value) maxP = p;
          if (p.value < minP.value) minP = p;
        }
        buf.writeln('- 期间最高 ${_yuan(maxP.value)}，最低 ${_yuan(minP.value)}');
      }
    } catch (_) {}

    // 6) 预算执行（本月）
    try {
      final db = _ref.read(dbProvider);
      final budgets = await _ref.read(budgetRepoProvider).getAll();
      final range = _monthRange(now, 0);
      final items = <({String name, int amount, int spent})>[];
      for (final b in budgets) {
        if (!b.enabled || b.type != BillType.expense.name) continue;
        final bStart = b.startTime;
        if (bStart == null) continue;
        final bEnd = b.endTime ?? bStart + 32 * 24 * 3600 * 1000;
        if (!(bStart < range.$2 && bEnd > range.$1)) continue;
        final winStart = bStart > range.$1 ? bStart : range.$1;
        final winEnd = bEnd < range.$2 ? bEnd : range.$2;
        final rows = await db
            .customSelect(
              'SELECT COALESCE(SUM(amount), 0) AS s FROM bills '
              'WHERE type = ? AND time >= ? AND time < ?'
              " AND (extra IS NULL OR (extra NOT LIKE '%\\\"excludeFromStats\\\":true%'"
              " AND extra NOT LIKE '%\\\"notInTotal\\\":true%'))"
              "${b.categoryId != null ? ' AND category_id = ?' : ''}",
              variables: [
                Variable(BillType.expense.name),
                Variable(winStart),
                Variable(winEnd),
                if (b.categoryId != null) Variable(b.categoryId),
              ],
            )
            .get();
        final spent = rows.first.data['s'] as int? ?? 0;
        items.add((name: b.name, amount: b.amount, spent: spent));
      }
      if (items.isNotEmpty) {
        buf.writeln('\n### 预算执行（本月）');
        for (final it in items) {
          final pct = it.amount <= 0 ? 0 : (it.spent * 100 / it.amount).round();
          buf.writeln(
            '- ${it.name}：已用 ${_yuan(it.spent)} / ${_yuan(it.amount)}（$pct%）',
          );
        }
      }
    } catch (_) {}

    buf.writeln(
      '\n（摘要仅含聚合数据，不含账单备注/位置等明细；'
      '摘要未涵盖的部分请明确说明不知道。）',
    );
    return buf.toString();
  }

  Future<(int, int)> _sumRange(BillRepository repo, int start, int end) async {
    final s = await repo.summaryInRangeOnce(start, end);
    return (s.expense, s.income);
  }

  /// 某月 [offsetMonths]（0=本月）的 [start, end) 毫秒区间。
  (int, int) _monthRange(DateTime now, int offsetMonths) {
    final m = DateTime(now.year, now.month + offsetMonths);
    return (
      m.millisecondsSinceEpoch,
      DateTime(m.year, m.month + 1).millisecondsSinceEpoch,
    );
  }

  static String _yuan(int fen4) {
    final v = fen4 / 10000;
    if (v.abs() >= 10000) {
      return '${(v / 10000).toStringAsFixed(2)} 万';
    }
    return v.toStringAsFixed(2);
  }
}
