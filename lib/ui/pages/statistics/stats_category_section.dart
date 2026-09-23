import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/amount.dart';
import '../../../data/database/app_database.dart';
import '../../../state/providers.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_sheet.dart';
import '../../widgets/xp_skeleton.dart';
import 'stats_shared.dart';

/// 分类分区：支出/收入饼图 + 一级分类金额排行。
class StatsCategorySection extends ConsumerStatefulWidget {
  const StatsCategorySection({
    super.key,
    required this.start,
    required this.end,
    this.onReady,
  });

  final int start;
  final int end;

  /// 数据加载完成（成功或失败）后的回调；统计页用它切换分区可见性。
  final VoidCallback? onReady;

  @override
  ConsumerState<StatsCategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends ConsumerState<StatsCategorySection>
    with StatsSectionRefresh {
  late Future<_CategoryData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant StatsCategorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _reload();
    }
  }

  @override
  void onDataVersionChanged() {
    _reload();
  }

  /// 触发查询并在完成（成功或失败）后通知 onReady。
  void _reload() {
    _future = _load();
    _future.then(
      (_) => widget.onReady?.call(),
      onError: (_) => widget.onReady?.call(),
    );
  }

  Future<_CategoryData> _load() async {
    final repo = ref.read(billRepoProvider);
    final expenseSum = await repo.sumByCategoryInRange(
      widget.start,
      widget.end,
      BillType.expense,
    );
    final incomeSum = await repo.sumByCategoryInRange(
      widget.start,
      widget.end,
      BillType.income,
    );
    final categories = await ref.read(categoryRepoProvider).getAll();
    return _CategoryData(
      expenseSum: expenseSum,
      incomeSum: incomeSum,
      categories: categories,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CategoryData>(
      future: _future,
      builder: (context, snap) => xpFadeGate(snap, () {
        if (snap.connectionState != ConnectionState.done) {
          return const XpSkeletonList();
        }
        if (snap.hasError) {
          return XpErrorState(
            message: '${snap.error}',
            actionLabel: '重试',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final d = snap.data!;
        return ListView(
          // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
          padding: EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.l,
            XpSpacing.l,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _CategoryPieCard(
              title: '支出分类占比',
              emptyHint: '本时段暂无支出',
              categorySum: d.expenseSum,
              categories: d.categories,
            ),
            const SizedBox(height: XpSpacing.l),
            _CategoryPieCard(
              title: '收入分类占比',
              emptyHint: '本时段暂无收入',
              categorySum: d.incomeSum,
              categories: d.categories,
            ),
            const SizedBox(height: XpSpacing.l),
            _CategoryRankCard(start: widget.start, end: widget.end, data: d),
          ],
        );
      }),
    );
  }
}

/// 分类金额排行卡：支出/收入切换 + 按一级分类聚合排序 + 点击看明细。
class _CategoryRankCard extends ConsumerStatefulWidget {
  const _CategoryRankCard({
    required this.start,
    required this.end,
    required this.data,
  });

  final int start;
  final int end;
  final _CategoryData data;

  @override
  ConsumerState<_CategoryRankCard> createState() => _CategoryRankCardState();
}

class _CategoryRankCardState extends ConsumerState<_CategoryRankCard> {
  BillType _type = BillType.expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leafSum = _type == BillType.expense
        ? widget.data.expenseSum
        : widget.data.incomeSum;
    final ranked = widget.data.topLevelSum(leafSum);
    final total = ranked.fold<int>(0, (s, e) => s + e.amount);

    return XpCard(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '分类金额排行',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SegmentedButton<BillType>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: BillType.expense, label: Text('支出')),
                  ButtonSegment(value: BillType.income, label: Text('收入')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.xs),
          Text(
            '按一级分类合计金额排序，点击查看明细',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.s),
          if (ranked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  _type == BillType.expense ? '本时段暂无支出' : '本时段暂无收入',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            )
          else
            for (var i = 0; i < ranked.length; i++)
              _RankTile(
                rank: i + 1,
                name: _catName(widget.data.categories, ranked[i].categoryId),
                amount: ranked[i].amount,
                percent: total <= 0 ? 0 : ranked[i].amount / total,
                color: piePalette[i % piePalette.length],
                onTap: () => _showDetail(ranked[i].categoryId),
              ),
        ],
      ),
    );
  }

  /// 明细弹窗：该一级分类（含其子分类）在时间范围内的账单列表。
  void _showDetail(String topCategoryId) {
    final name = _catName(widget.data.categories, topCategoryId);
    showXpSheet<void>(
      context: context,
      builder: (sheetCtx) => _CategoryDetailSheet(
        start: widget.start,
        end: widget.end,
        type: _type,
        topCategoryId: topCategoryId,
        title: name,
        data: widget.data,
      ),
    );
  }
}

class _CategoryDetailSheet extends ConsumerStatefulWidget {
  const _CategoryDetailSheet({
    required this.start,
    required this.end,
    required this.type,
    required this.topCategoryId,
    required this.title,
    required this.data,
  });

  final int start;
  final int end;
  final BillType type;
  final String topCategoryId;
  final String title;
  final _CategoryData data;

  @override
  ConsumerState<_CategoryDetailSheet> createState() =>
      _CategoryDetailSheetState();
}

class _CategoryDetailSheetState extends ConsumerState<_CategoryDetailSheet> {
  Future<List<Bill>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Bill>> _load() async {
    final repo = ref.read(billRepoProvider);
    final bills = await repo.listByRange(widget.start, widget.end);
    // 该一级分类（含其所有子分类）的账单
    final wanted = <String>{widget.topCategoryId};
    // 收集所有子分类 id（多级）
    var changed = true;
    while (changed) {
      changed = false;
      for (final c in widget.data.categories) {
        if (c.parentId != null && wanted.contains(c.parentId)) {
          if (wanted.add(c.id)) changed = true;
        }
      }
    }
    return [
      for (final b in bills)
        if (b.type == widget.type.name && wanted.contains(b.categoryId)) b,
    ]..sort((a, b) => b.time.compareTo(a.time));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                XpSpacing.l,
                14,
                XpSpacing.s,
                XpSpacing.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<Bill>>(
                future: _future,
                builder: (context, snap) => xpFadeGate(snap, () {
                  if (snap.connectionState != ConnectionState.done) {
                    return const XpSkeletonList();
                  }
                  if (snap.hasError) {
                    return XpErrorState(
                      message: '${snap.error}',
                      actionLabel: '重试',
                      onAction: () => setState(() => _future = _load()),
                    );
                  }
                  final bills = snap.data!;
                  if (bills.isEmpty) {
                    return const XpEmptyState(
                      icon: Icons.receipt_long,
                      title: '该时间范围内暂无明细',
                    );
                  }
                  var total = 0;
                  for (final b in bills) {
                    total += b.amount;
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      XpSpacing.l,
                      XpSpacing.s,
                      XpSpacing.l,
                      XpSpacing.xl,
                    ),
                    itemCount: bills.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: XpSpacing.s),
                          child: Text(
                            '共 ${bills.length} 笔，合计 ${formatYuan(total)}',
                            style: theme.textTheme.labelMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                                .tabular,
                          ),
                        );
                      }
                      final b = bills[i - 1];
                      return _DetailRow(
                        bill: b,
                        categories: widget.data.categories,
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.bill, required this.categories});

  final Bill bill;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = DateTime.fromMillisecondsSinceEpoch(bill.time);
    final childName = _catName(categories, bill.categoryId);
    final isExpense = bill.type == BillType.expense.name;
    final comment = (bill.comment ?? '').trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  childName,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (comment.isNotEmpty)
                  Text(
                    comment,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${formatYuan(bill.amount)}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isExpense
                      ? theme.colorScheme.onSurface
                      : XpSemanticColors.income,
                )
                .tabular,
          ),
        ],
      ),
    );
  }
}

/// 排行单行。
class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.name,
    required this.amount,
    required this.percent,
    required this.color,
    required this.onTap,
  });

  final int rank;
  final String name;
  final int amount;
  final double percent;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: XpSpacing.s),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: XpSpacing.s),
            Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
            Text(
              formatYuan(amount),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)
                  .tabular,
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 46,
              child: Text(
                '${(percent * 100).toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                    .tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData({
    required this.expenseSum,
    required this.incomeSum,
    required this.categories,
  });

  final List<({String categoryId, int amount})> expenseSum;
  final List<({String categoryId, int amount})> incomeSum;
  final List<Category> categories;

  /// id → 分类
  Map<String, Category> get byId {
    final m = <String, Category>{};
    for (final c in categories) {
      m[c.id] = c;
    }
    return m;
  }

  /// 沿 parentId 上溯到一级分类 id（自身即一级时返回自身）。
  String topParentId(String categoryId) {
    final byIdMap = byId;
    var cur = categoryId;
    final seen = <String>{};
    while (true) {
      final c = byIdMap[cur];
      if (c == null || c.parentId == null || !seen.add(cur)) return cur;
      cur = c.parentId!;
    }
  }

  /// 把叶子级金额聚合（[sumByCategoryInRange]）归并到一级分类，返回
  /// 排序后的列表（金额降序）。结果不含未用到的分类。
  List<({String categoryId, int amount, int count})> topLevelSum(
    List<({String categoryId, int amount})> leafSum,
  ) {
    final agg = <String, int>{};
    for (final e in leafSum) {
      final top = topParentId(e.categoryId);
      agg[top] = (agg[top] ?? 0) + e.amount;
    }
    final list = <({String categoryId, int amount, int count})>[
      for (final e in agg.entries)
        (
          categoryId: e.key,
          amount: e.value,
          count: leafSum
              .where((s) => topParentId(s.categoryId) == e.key)
              .length,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }
}

String _catName(List<Category> categories, String id) {
  for (final c in categories) {
    if (c.id == id) return c.name;
  }
  return '未知分类';
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({
    required this.title,
    required this.emptyHint,
    required this.categorySum,
    required this.categories,
  });

  final String title;
  final String emptyHint;
  final List<({String categoryId, int amount})> categorySum;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categorySum.isEmpty) {
      return XpCard(
        padding: EdgeInsets.zero,
        child: XpEmptyState(icon: Icons.pie_chart_outline, title: emptyHint),
      );
    }
    final sorted = [...categorySum]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final total = sorted.fold<int>(0, (s, e) => s + e.amount);
    final top5 = sorted.take(5).toList();
    final otherAmount = total - top5.fold<int>(0, (s, e) => s + e.amount);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < top5.length; i++)
        PieChartSectionData(
          value: top5[i].amount.toDouble(),
          title: '${(top5[i].amount / total * 100).toStringAsFixed(0)}%',
          color: piePalette[i % piePalette.length],
          radius: 52,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      if (otherAmount > 0)
        PieChartSectionData(
          value: otherAmount.toDouble(),
          title: '${(otherAmount / total * 100).toStringAsFixed(0)}%',
          color: piePalette[5],
          radius: 52,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
    ];

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: XpSpacing.m),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                  ),
                ),
              ),
              const SizedBox(width: XpSpacing.l),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < top5.length; i++)
                      _legend(
                        context,
                        piePalette[i % piePalette.length],
                        _catName(categories, top5[i].categoryId),
                        '${formatYuan(top5[i].amount)}'
                        '（${(top5[i].amount / total * 100).toStringAsFixed(0)}%）',
                      ),
                    if (otherAmount > 0)
                      _legend(
                        context,
                        piePalette[5],
                        '其他',
                        '${formatYuan(otherAmount)}'
                            '（${(otherAmount / total * 100).toStringAsFixed(0)}%）',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color color, String name, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: XpSpacing.s),
          Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                .tabular,
          ),
        ],
      ),
    );
  }
}
