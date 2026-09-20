import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/bill_extra.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/bill_tile.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_skeleton.dart';
import 'bookkeeping_sheet.dart';

/// 搜索页：关键词（备注/分类/标签）+ 类型/账户/分类/时间段/金额 多条件筛选。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with XpPageScaffold<SearchPage> {
  final TextEditingController _keywordCtrl = TextEditingController();
  BillType? _type;
  String? _accountId;
  String? _categoryId;
  int _range = 0; // 0 全部 / 1 本月 / 2 上月
  String? _minAmountText;
  String? _maxAmountText;
  bool _showAnalysis = false; // false 列表 / true 分析

  @override
  void dispose() {
    _keywordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return buildXpScaffold(
      appBar: AppBar(title: const Text('搜索账单')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _keywordCtrl,
              decoration: InputDecoration(
                hintText: '搜索备注 / 分类 / 标签',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keywordCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _keywordCtrl.clear();
                          setState(() {});
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _filterChip(
                  '全部',
                  _type == null,
                  () => setState(() => _type = null),
                ),
                for (final t in BillType.values)
                  _filterChip(
                    _typeLabel(t),
                    _type == t,
                    () => setState(() => _type = t),
                  ),
                _filterChip(
                  '本月',
                  _range == 1,
                  () => setState(() => _range = 1),
                ),
                _filterChip(
                  '上月',
                  _range == 2,
                  () => setState(() => _range = 2),
                ),
                _filterChip(
                  '全部时间',
                  _range == 0,
                  () => setState(() => _range = 0),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                DropdownButton<String?>(
                  value: _accountId,
                  hint: const Text('全部账户'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部账户')),
                    for (final a in accounts)
                      DropdownMenuItem(value: a.id, child: Text(a.name)),
                  ],
                  onChanged: (v) => setState(() => _accountId = v),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _categoryId,
                  hint: const Text('全部分类'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('全部分类')),
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最小金额',
                      isDense: true,
                    ),
                    onChanged: (v) => _minAmountText = v,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('—'),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最大金额',
                      isDense: true,
                    ),
                    onChanged: (v) => _maxAmountText = v,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildResults(categories)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  String _typeLabel(BillType t) => switch (t) {
    BillType.expense => '支出',
    BillType.income => '收入',
    BillType.transfer => '转账',
  };

  Widget _buildResults(List<Category> categories) {
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final billTagsAsync = ref.watch(_allBillTagsProvider);
    final allAsync = ref.watch(_allBillsProvider);
    return billTagsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 8),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (billTags) {
        final tagNameById = {for (final t in tags) t.id: t.name};
        final billTagIds = <String, Set<String>>{};
        for (final rel in billTags) {
          billTagIds.putIfAbsent(rel.billId, () => <String>{}).add(rel.tagId);
        }
        return allAsync.when(
          loading: () => const XpSkeletonList(itemCount: 8),
          error: (e, _) => Center(child: Text('加载失败：$e')),
          data: (all) {
            final filtered = _filter(
              all,
              categories,
              tagNameById: tagNameById,
              billTagIds: billTagIds,
            );
            // 「不计入收支」账单仍展示在列表，但不计入收支合计与分析
            final statBills = [
              for (final b in filtered)
                if (!BillExtra.fromJson(b.extra).excludeFromStats) b,
            ];
            var expense = 0, income = 0;
            for (final b in statBills) {
              if (b.type == BillType.expense.name) expense += b.amount;
              if (b.type == BillType.income.name) income += b.amount;
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '共 ${filtered.length} 笔',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      Text(
                        '支出 ${formatYuan(expense)} · 收入 ${formatYuan(income)}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(value: false, label: Text('列表')),
                        ButtonSegment(value: true, label: Text('分析')),
                      ],
                      selected: {_showAnalysis},
                      onSelectionChanged: (s) =>
                          setState(() => _showAnalysis = s.first),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filtered.isEmpty
                      ? const XpEmptyState(
                          icon: Icons.search_off,
                          title: '没有符合条件的账单',
                          message: '试试放宽筛选条件或更换关键词',
                        )
                      : _showAnalysis
                      ? _AnalysisView(bills: statBills, categories: categories)
                      : _buildBillList(filtered),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBillList(List<Bill> filtered) {
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final bill = filtered[i];
        return BillTile(
          bill: bill,
          onTap: () => BookkeepingSheet.show(context, bill: bill),
          onLongPress: () => _delete(context, bill),
        );
      },
    );
  }

  List<Bill> _filter(
    List<Bill> all,
    List<Category> categories, {
    required Map<String, String> tagNameById,
    required Map<String, Set<String>> billTagIds,
  }) {
    final now = DateTime.now();
    final (start, end) = switch (_range) {
      1 => (
        DateTime(now.year, now.month).millisecondsSinceEpoch,
        DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
      ),
      2 => (
        DateTime(now.year, now.month - 1).millisecondsSinceEpoch,
        DateTime(now.year, now.month).millisecondsSinceEpoch,
      ),
      _ => (0, 1 << 62),
    };
    final minAmount = parseYuanInput(_minAmountText ?? '');
    final maxAmount = parseYuanInput(_maxAmountText ?? '');
    final keyword = _keywordCtrl.text.trim().toLowerCase();
    // 分类名 + 父分类名：二级分类下搜父类名也能命中
    final catNameById = {for (final c in categories) c.id: c.name};
    final parentNameById = <String, String>{
      for (final c in categories)
        if (c.parentId != null) c.id: catNameById[c.parentId] ?? '',
    };

    return all.where((b) {
      if (b.time < start || b.time >= end) return false;
      if (_type != null && b.type != _type!.name) return false;
      if (_accountId != null &&
          b.accountId != _accountId &&
          b.incomeAccountId != _accountId) {
        return false;
      }
      if (_categoryId != null && b.categoryId != _categoryId) return false;
      if (minAmount != null && b.amount < minAmount) return false;
      if (maxAmount != null && b.amount > maxAmount) return false;
      if (keyword.isNotEmpty) {
        final commentMatch =
            b.comment?.toLowerCase().contains(keyword) ?? false;
        final catMatch =
            catNameById[b.categoryId]?.toLowerCase().contains(keyword) ?? false;
        final parentMatch =
            parentNameById[b.categoryId]?.toLowerCase().contains(keyword) ??
            false;
        var tagMatch = false;
        for (final tid in billTagIds[b.id] ?? const <String>{}) {
          if (tagNameById[tid]?.toLowerCase().contains(keyword) ?? false) {
            tagMatch = true;
            break;
          }
        }
        if (!commentMatch && !catMatch && !parentMatch && !tagMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> _delete(BuildContext context, Bill bill) async {
    final ok = await confirmXpDialog(
      context,
      title: '删除账单',
      content: '删除后余额与快照将同步回滚，确定删除？',
      confirmLabel: '删除',
      danger: true,
    );
    if (ok == true && context.mounted) {
      await ref.read(billServiceProvider).deleteBill(bill.id);
      // drift watch 流会自动刷新列表,无需手动 bump revision
    }
  }
}

/// 全量账单（时间升序；搜索在内存过滤）。
/// 账单数据变更时通过 drift watch 流自动触发重查(记账/导入/删除均实时刷新)。

final _allBillsProvider = StreamProvider<List<Bill>>(
  (ref) => ref.watch(billRepoProvider).watchAll(),
);

/// 全部账单-标签关联（搜索需按标签名过滤时一次性取数）。
final _allBillTagsProvider =
    StreamProvider<List<({String billId, String tagId})>>((ref) {
      final tagRepo = ref.watch(billRepoProvider);
      // 依赖账单流:账单删除时 drift 会重发关联查询(简单起见跟随 bills 表事件)
      return tagRepo.watchAll().asyncMap((_) => tagRepo.allBillTags());
    });

// ---------- 搜索结果分析视图 ----------

enum _FocusType { expense, income, balance }

/// 搜索结果分析：趋势（收入/支出/结余）+ 分类占比 + 标签词云。
class _AnalysisView extends ConsumerStatefulWidget {
  const _AnalysisView({required this.bills, required this.categories});

  final List<Bill> bills;
  final List<Category> categories;

  @override
  ConsumerState<_AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends ConsumerState<_AnalysisView> {
  _FocusType _focus = _FocusType.expense;
  bool _byMonth = false;
  late Future<List<({String billId, String tagId})>> _billTagsFuture;

  @override
  void initState() {
    super.initState();
    _billTagsFuture = ref.read(billRepoProvider).allBillTags();
  }

  @override
  void didUpdateWidget(covariant _AnalysisView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // bills 引用变化(父级重新过滤)时重取标签关联
    if (!identical(oldWidget.bills, widget.bills)) {
      _billTagsFuture = ref.read(billRepoProvider).allBillTags();
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = _trendSeries(widget.bills, _focus, _byMonth);
    final cats = _categorySums(widget.bills, _focus);
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    return FutureBuilder<List<({String billId, String tagId})>>(
      future: _billTagsFuture,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final billTags = snap.data ?? const <({String billId, String tagId})>[];
        final tagCounts = _tagCounts(widget.bills, billTags);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<_FocusType>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _FocusType.expense, label: Text('支出')),
                ButtonSegment(value: _FocusType.income, label: Text('收入')),
                ButtonSegment(value: _FocusType.balance, label: Text('结余')),
              ],
              selected: {_focus},
              onSelectionChanged: (s) => setState(() => _focus = s.first),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: false, label: Text('按天')),
                  ButtonSegment(value: true, label: Text('按月')),
                ],
                selected: {_byMonth},
                onSelectionChanged: (s) => setState(() => _byMonth = s.first),
              ),
            ),
            const SizedBox(height: 12),
            Text('趋势', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: series.isEmpty
                  ? const Center(child: Text('暂无趋势数据'))
                  : _TrendLine(points: series, byMonth: _byMonth),
            ),
            if (_focus != _FocusType.balance) ...[
              const SizedBox(height: 16),
              Text('分类占比', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SizedBox(
                height: 140,
                child: _FocusPie(sums: cats, categories: widget.categories),
              ),
            ],
            const SizedBox(height: 16),
            Text('标签词云', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _TagCloud(counts: tagCounts, tags: tags),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  /// 按天/按月聚合趋势序列（时间升序）。
  List<({int time, int value})> _trendSeries(
    List<Bill> bills,
    _FocusType focus,
    bool byMonth,
  ) {
    final map = <int, int>{};
    for (final b in bills) {
      final isExpense = b.type == BillType.expense.name;
      final isIncome = b.type == BillType.income.name;
      if (!isExpense && !isIncome) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(b.time);
      final key = byMonth
          ? DateTime(dt.year, dt.month).millisecondsSinceEpoch
          : DateTime(dt.year, dt.month, dt.day).millisecondsSinceEpoch;
      final delta = switch (focus) {
        _FocusType.expense => isExpense ? b.amount : 0,
        _FocusType.income => isIncome ? b.amount : 0,
        _FocusType.balance =>
          (isIncome ? b.amount : 0) - (isExpense ? b.amount : 0),
      };
      map[key] = (map[key] ?? 0) + delta;
    }
    final keys = map.keys.toList()..sort();
    return [for (final k in keys) (time: k, value: map[k]!)];
  }

  List<({String categoryId, int amount})> _categorySums(
    List<Bill> bills,
    _FocusType focus,
  ) {
    if (focus == _FocusType.balance) return const [];
    final target = focus == _FocusType.expense
        ? BillType.expense.name
        : BillType.income.name;
    final map = <String, int>{};
    for (final b in bills) {
      if (b.type != target) continue;
      map[b.categoryId] = (map[b.categoryId] ?? 0) + b.amount;
    }
    return [for (final e in map.entries) (categoryId: e.key, amount: e.value)];
  }

  /// 过滤后账单中每个标签出现的次数。
  Map<String, int> _tagCounts(
    List<Bill> bills,
    List<({String billId, String tagId})> billTags,
  ) {
    final billIds = bills.map((b) => b.id).toSet();
    final counts = <String, int>{};
    for (final rel in billTags) {
      if (!billIds.contains(rel.billId)) continue;
      counts[rel.tagId] = (counts[rel.tagId] ?? 0) + 1;
    }
    return counts;
  }
}

/// 趋势折线（fl_chart）。
class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.points, required this.byMonth});

  final List<({int time, int value})> points;
  final bool byMonth;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value / 10000),
    ];
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble().clamp(1, double.infinity),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(
                _compact(v),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: points.length > 6
                  ? (points.length / 5).ceilToDouble()
                  : 1,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _xLabel(points[i].time, byMonth),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  static String _compact(double v) {
    if (v.abs() >= 10000) return '${(v / 10000).toStringAsFixed(1)}w';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  static String _xLabel(int ms, bool byMonth) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    if (byMonth) return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    return '${dt.month}/${dt.day}';
  }
}

/// 分类占比饼图。
class _FocusPie extends StatelessWidget {
  const _FocusPie({required this.sums, required this.categories});

  final List<({String categoryId, int amount})> sums;
  final List<Category> categories;

  static const _palette = [
    Color(0xFF5470C6),
    Color(0xFF91CC75),
    Color(0xFFFAC858),
    Color(0xFFEE6666),
    Color(0xFF73C0DE),
    Color(0xFF3BA272),
    Color(0xFFEA7CCC),
    Color(0xFF9A60B4),
    Color(0xFFFC8452),
    Color(0xFFF472B6),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = [...sums]..sort((a, b) => b.amount.compareTo(a.amount));
    final total = sorted.fold<int>(0, (s, e) => s + e.amount);
    if (total == 0) return const Center(child: Text('暂无数据'));
    final top5 = sorted.take(5).toList();
    final other = total - top5.fold<int>(0, (s, e) => s + e.amount);
    String name(String id) {
      for (final c in categories) {
        if (c.id == id) return c.name;
      }
      return '未知分类';
    }

    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 26,
              sections: [
                for (var i = 0; i < top5.length; i++)
                  PieChartSectionData(
                    value: top5[i].amount.toDouble(),
                    color: _palette[i % _palette.length],
                    radius: 44,
                    title:
                        '${(top5[i].amount / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                    ),
                  ),
                if (other > 0)
                  PieChartSectionData(
                    value: other.toDouble(),
                    color: _palette[5],
                    radius: 44,
                    title: '${(other / total * 100).toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(
                      fontSize: 9,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < top5.length; i++)
                _legend(
                  _palette[i % _palette.length],
                  name(top5[i].categoryId),
                  formatYuan(top5[i].amount),
                ),
              if (other > 0) _legend(_palette[5], '其他', formatYuan(other)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(Color color, String name, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// 标签词云：出现次数越多字号越大。
class _TagCloud extends StatelessWidget {
  const _TagCloud({required this.counts, required this.tags});

  final Map<String, int> counts;
  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    final tagName = {for (final t in tags) t.id: t.name};
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return Text(
        '筛选结果中没有带标签的账单',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final maxCount = entries.first.value;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in entries)
          Chip(
            label: Text(
              '${tagName[e.key] ?? e.key}（${e.value}）',
              style: TextStyle(
                fontSize: 10 + (e.value / maxCount * 8).clamp(0, 8),
              ),
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
