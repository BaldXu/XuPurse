import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bill_repository.dart';
import '../../state/providers.dart';
import '../../domain/services/trend_service.dart';
import 'ai_scope.dart';

/// 聊天时自动注入给 AI 的本机统计摘要（仅聚合口径，不含原始账单明细）。
///
/// 摘要包含哪些数据由 [aiScopeProvider]（AI 数据范围设置）控制：
/// 总开关关闭时返回空串；时间范围档位决定统计窗口；资产/收支/分类
/// 开关决定输出哪些章节。多个月的时间范围内，分类/标签/备注按自然月
/// 逐月生成，便于 AI 对比各月差异。
class AiStatsContext {
  AiStatsContext(this._ref);

  /// 支持来自 Notifier 的 [Ref] 或 Widget 的 [WidgetRef]。
  final dynamic _ref;

  /// 生成统计摘要文本（Markdown）。
  ///
  /// [override]：传入临时范围（如设置页未保存的草稿）时，用它代替已保存的
  /// [aiScopeProvider] 生成，用于预览；null 时按已保存配置生成。
  /// 账户/分类名照实输出（均为本地自命名，非敏感卡号）。任何一步失败
  /// 跳过该节，不影响整体生成。总开关关闭时返回空串。
  Future<String> build({AiScope? override}) async {
    final billRepo = _ref.read(billRepoProvider);
    final scope = override ?? _ref.read(aiScopeProvider);
    // 总开关关闭：不给 AI 任何本机数据（纯聊天模式）。
    if (!scope.enabled) return '';

    final accounts = _ref.read(accountsProvider).value ?? const <Account>[];
    final categories =
        _ref.read(categoriesProvider).value ?? const <Category>[];
    final catName = {for (final c in categories) c.id: c.name};
    final tags = _ref.read(tagsProvider).value ?? const <Tag>[];
    final tagName = {for (final t in tags) t.id: t.name};
    final topN = scope.categoryTopN;

    final buf = StringBuffer();
    final now = DateTime.now();
    // 统计窗口 [start, end)：范围档位=最近 N 天；全部=从最早账单起。
    final end = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).millisecondsSinceEpoch;
    int start;
    if (scope.range.days > 0) {
      start = now
          .subtract(Duration(days: scope.range.days))
          .millisecondsSinceEpoch;
    } else {
      start = await billRepo.minBillTime() ?? end - 365 * 24 * 3600 * 1000;
    }
    if (start > end) start = end - 24 * 3600 * 1000;
    buf.writeln(
      '## 本机统计摘要（应用自动附带，截止 ${now.year}/${now.month}/${now.day}，'
      '范围：${scope.range.label}）',
    );

    // 需要逐月拆分的自然月窗口（升序；过长时截断最旧的月份，封顶 24 个月）。
    final months = _monthWindows(start, now);

    // 1) 账户概况（资产开关）
    if (scope.includeAssets) {
      try {
        final assetAccounts = accounts.where((a) => a.enabled).toList();
        if (assetAccounts.isNotEmpty) {
          buf.writeln('\n### 账户余额');
          var total = 0;
          for (final a in assetAccounts) {
            buf.writeln(
              '- ${a.name}（${a.category}）：${_yuan(a.currentBalance)}',
            );
            total += a.currentBalance as int;
          }
          buf.writeln('- 合计余额：${_yuan(total)}');
        }
      } catch (_) {}
    }

    // 2) 收支汇总（收支开关，覆盖所选时间范围的总额）
    if (scope.includeIncomeExpense) {
      try {
        final s = await billRepo.summaryInRangeOnce(start, end);
        buf.writeln('\n### 收支汇总');
        buf.writeln(
          '- 支出 ${_yuan(s.expense)}，收入 ${_yuan(s.income)}，'
          '结余 ${_yuan(s.income - s.expense)}',
        );
      } catch (_) {}
    }

    // 3) 分类 Top N（分类开关，逐月生成）
    if (scope.includeCategories) {
      for (final m in months) {
        try {
          final expenseTop = await billRepo.sumByCategoryInRange(
            m.start,
            m.end,
            BillType.expense,
          );
          final incomeTop = await billRepo.sumByCategoryInRange(
            m.start,
            m.end,
            BillType.income,
          );
          final monthLabel = '（${m.year}/${m.month}）';
          if (expenseTop.isNotEmpty) {
            buf.writeln('\n### 支出分类 Top$topN$monthLabel');
            for (final e in _sortCategoryDesc(expenseTop).take(topN)) {
              buf.writeln(
                '- ${catName[e.categoryId] ?? e.categoryId}：${_yuan(e.amount)}',
              );
            }
          }
          if (incomeTop.isNotEmpty) {
            buf.writeln('\n### 收入分类 Top$topN$monthLabel');
            for (final e in _sortCategoryDesc(incomeTop).take(topN)) {
              buf.writeln(
                '- ${catName[e.categoryId] ?? e.categoryId}：${_yuan(e.amount)}',
              );
            }
          }
        } catch (_) {}
      }
    }

    // 4) 标签 Top N（标签开关，逐月生成）
    if (scope.includeTags) {
      for (final m in months) {
        try {
          final expenseTop = await billRepo.sumByTagInRange(
            m.start,
            m.end,
            BillType.expense,
          );
          final incomeTop = await billRepo.sumByTagInRange(
            m.start,
            m.end,
            BillType.income,
          );
          final monthLabel = '（${m.year}/${m.month}）';
          if (expenseTop.isNotEmpty) {
            buf.writeln('\n### 支出标签 Top$topN$monthLabel');
            for (final e in _sortTagDesc(expenseTop).take(topN)) {
              buf.writeln(
                '- ${tagName[e.tagId] ?? e.tagId}：${_yuan(e.amount)}',
              );
            }
          }
          if (incomeTop.isNotEmpty) {
            buf.writeln('\n### 收入标签 Top$topN$monthLabel');
            for (final e in _sortTagDesc(incomeTop).take(topN)) {
              buf.writeln(
                '- ${tagName[e.tagId] ?? e.tagId}：${_yuan(e.amount)}',
              );
            }
          }
        } catch (_) {}
      }
    }

    // 5) 备注 Top N（备注开关，逐月生成；含你主动开启的备注文本）
    if (scope.includeRemarks) {
      for (final m in months) {
        try {
          final top = await billRepo.sumByCommentInRange(
            m.start,
            m.end,
            limit: topN,
          );
          if (top.isNotEmpty) {
            buf.writeln('\n### 备注 Top$topN（${m.year}/${m.month}）');
            for (final e in top) {
              buf.writeln('- "${e.comment}"：${_yuan(e.amount)}');
            }
          }
        } catch (_) {}
      }
    }

    // 6) 收支按月趋势（收支开关，逐月；复用 months）
    if (scope.includeIncomeExpense) {
      try {
        buf.writeln('\n### 收支趋势（按月）');
        for (final m in months.reversed) {
          final s = await _sumRange(billRepo, m.start, m.end);
          buf.writeln(
            '- ${m.year}/${m.month}：支出 ${_yuan(s.$1)}，收入 ${_yuan(s.$2)}',
          );
        }
      } catch (_) {}
    }

    // 7) 资产趋势（资产开关，覆盖所选时间范围，周粒度）
    if (scope.includeAssets) {
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
        final points = aggregateTrendPoints(
          buildTrendPoints(
            snaps: snaps,
            assetIds: assetIds,
            accounts: accounts,
            start: start,
            end: end,
          ),
          TrendGranularity.week,
        );
        if (points.length >= 2) {
          buf.writeln('\n### 资产趋势（周粒度）');
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
    }

    // 8) 预算执行（本月，收支开关）
    if (scope.includeIncomeExpense) {
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
            final pct = it.amount <= 0
                ? 0
                : (it.spent * 100 / it.amount).round();
            buf.writeln(
              '- ${it.name}：已用 ${_yuan(it.spent)} / ${_yuan(it.amount)}（$pct%）',
            );
          }
        }
      } catch (_) {}
    }

    buf.writeln(
      scope.includeRemarks
          ? '\n（摘要含你主动开启的备注排行；不含账单地点/附件等其余明细；'
                '摘要未涵盖的部分请明确说明不知道。）'
          : '\n（摘要仅含聚合数据，不含账单备注/位置等明细；'
                '摘要未涵盖的部分请明确说明不知道。）',
    );
    return buf.toString();
  }

  /// 覆盖 [start, now] 的自然月窗口（升序；过长时截断最旧的月份，封顶 24 个）。
  List<({int year, int month, int start, int end})> _monthWindows(
    int start,
    DateTime now,
  ) {
    final firstMonth = DateTime.fromMillisecondsSinceEpoch(start);
    final first = DateTime(firstMonth.year, firstMonth.month);
    final last = DateTime(now.year, now.month);
    var totalMonths =
        (last.year - first.year) * 12 + (last.month - first.month) + 1;
    var cur = last;
    const maxRows = 24;
    if (totalMonths > maxRows) {
      cur = DateTime(cur.year, cur.month - (totalMonths - maxRows));
      totalMonths = maxRows;
    }
    return [
      // 从最旧月份到最新月份（升序）：cur 为最新月，依次往前推。
      for (var i = totalMonths - 1; i >= 0; i--)
        DateTime(cur.year, cur.month - i),
    ].map((m) {
      final s = m.millisecondsSinceEpoch;
      return (
        year: m.year,
        month: m.month,
        start: s,
        end: DateTime(m.year, m.month + 1).millisecondsSinceEpoch,
      );
    }).toList();
  }

  /// 按 [amountOf] 降序排序（显式类型，规避 record 元素在 for-in + cascade
  /// 下 sort 比较器推断退化为 dynamic 导致的运行时 TypeError）。
  List<({String categoryId, int amount})> _sortCategoryDesc(
    Iterable<({String categoryId, int amount})> items,
  ) {
    final sorted = items.toList();
    sorted.sort((a, b) => b.amount.compareTo(a.amount));
    return sorted;
  }

  List<({String tagId, int amount})> _sortTagDesc(
    Iterable<({String tagId, int amount})> items,
  ) {
    final sorted = items.toList();
    sorted.sort((a, b) => b.amount.compareTo(a.amount));
    return sorted;
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
