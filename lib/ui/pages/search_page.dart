import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/bill_extra.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_param_row.dart';
import '../widgets/xp_picker_sheet.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/xp_sliding_segmented.dart';
import 'bookkeeping_sheet.dart';

/// 搜索页：关键词（备注/分类/标签）+ 底部筛选面板（类型/账户/分类/时间/金额）。
///
/// 交互模型：
/// - 进入页面默认为空态，不加载任何账单数据；
/// - 输入关键词（或设置筛选条件）后点击「搜索」才执行查询并展示结果；
/// - 已搜索后修改筛选条件会自动按新条件重新过滤（关键词需再次点「搜索」）。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

/// 时间范围选项。
enum _TimeRange { all, thisMonth, lastMonth, last3Months, custom }

extension on _TimeRange {
  String get label => switch (this) {
    _TimeRange.all => '全部',
    _TimeRange.thisMonth => '本月',
    _TimeRange.lastMonth => '上月',
    _TimeRange.last3Months => '近3月',
    _TimeRange.custom => '自定义',
  };
}

/// 搜索筛选条件（不可变；由底部筛选面板一次性产出/整体替换）。
class _SearchFilters {
  const _SearchFilters({
    this.type,
    this.range = _TimeRange.all,
    this.customRange,
    this.accountId,
    this.categoryId,
    this.minAmount,
    this.maxAmount,
  });

  final BillType? type;
  final _TimeRange range;
  final DateTimeRange? customRange;
  final String? accountId;
  final String? categoryId;

  /// 金额下限/上限（万分之元）。
  final int? minAmount;
  final int? maxAmount;

  bool get isEmpty =>
      type == null &&
      range == _TimeRange.all &&
      customRange == null &&
      accountId == null &&
      categoryId == null &&
      minAmount == null &&
      maxAmount == null;

  _SearchFilters copyWith({
    BillType? type,
    bool clearType = false,
    _TimeRange? range,
    DateTimeRange? customRange,
    bool clearCustomRange = false,
    String? accountId,
    bool clearAccountId = false,
    String? categoryId,
    bool clearCategoryId = false,
    int? minAmount,
    bool clearMinAmount = false,
    int? maxAmount,
    bool clearMaxAmount = false,
  }) {
    return _SearchFilters(
      type: clearType ? null : (type ?? this.type),
      range: range ?? this.range,
      customRange: clearCustomRange ? null : (customRange ?? this.customRange),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

class _SearchPageState extends ConsumerState<SearchPage>
    with XpPageScaffold<SearchPage> {
  final TextEditingController _keywordCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  _SearchFilters _filters = const _SearchFilters();

  /// 最近一次「搜索」时执行的关键词快照：编辑关键词不会影响已展示结果，
  /// 必须再次点「搜索」才更新（点击搜索契约）。
  String _lastKeyword = '';
  bool _searched = false;
  bool _showAnalysis = false;

  @override
  void dispose() {
    _keywordCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// 执行搜索。筛选条件变化后的自动重查走 [keepKeyword]（沿用上次关键词）。
  void _runSearch({bool keepKeyword = false}) {
    if (!keepKeyword) _lastKeyword = _keywordCtrl.text.trim();
    _searchFocus.unfocus();
    setState(() => _searched = true);
  }

  /// 应用筛选面板结果；已搜索过则自动重新过滤。
  void _applyFilters(_SearchFilters next) {
    setState(() => _filters = next);
    if (_searched) _runSearch(keepKeyword: true);
  }

  Future<void> _openFilterSheet() async {
    final accounts =
        ref.read(accountsProvider).value ?? const <Account>[];
    final categories =
        ref.read(categoriesProvider).value ?? const <Category>[];
    final result = await showXpSheet<_SearchFilters>(
      context: context,
      heightFactor: 0.8,
      builder: (_) => _FilterSheet(
        initial: _filters,
        accounts: accounts,
        categories: categories,
      ),
    );
    if (result != null && mounted) _applyFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: const Text('搜索账单'));
    // 筛选 chips 需展示账户/分类名，watch 提供（轻量，进入页面即渲染）。
    final accounts =
        ref.watch(accountsProvider).valueOrNull ?? const <Account>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return buildXpScaffold(
      appBar: appBar,
      buildBody: (_) => Column(
        children: [
          _buildSearchBar(),
          _buildFilterBar(accounts, categories),
          const Divider(height: 1),
          Expanded(child: _buildResults(categories)),
        ],
      ),
    );
  }

  // ── 顶部搜索栏 ──────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.s,
        XpSpacing.l,
        XpSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _keywordCtrl,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: '搜索备注 / 分类 / 标签',
                prefixIcon: const AppIcon(icon: Icons.search, size: 20),
                suffixIcon: _keywordCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const AppIcon(icon: Icons.clear, size: 20),
                        onPressed: () {
                          _keywordCtrl.clear();
                          setState(() {});
                        },
                      ),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(XpRadius.s),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => _runSearch(),
              child: const Text('搜索'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 筛选入口 + 已选条件 chips ───────────────────────────────

  Widget _buildFilterBar(List<Account> accounts, List<Category> categories) {
    final chips = _activeFilterChips(accounts, categories);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // vertical 6 让 chips/按钮在 44 高内垂直居中（内容区 32）
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: 6,
        ),
        children: [
          ActionChip(
            avatar: AppIcon(icon: Icons.filter_alt_outlined, size: 16),
            label: Text(chips.isEmpty ? '筛选' : '筛选 · ${chips.length}'),
            onPressed: _openFilterSheet,
          ),
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(left: XpSpacing.s),
              child: FilterChip(
                label: Text(c.label),
                selected: true,
                // 点击已选条件同样视为移除（onSelected 为必填）
                onSelected: (_) => c.onDelete(),
                onDeleted: c.onDelete,
              ),
            ),
          if (chips.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: XpSpacing.s),
              child: TextButton(
                onPressed: () => _applyFilters(const _SearchFilters()),
                child: const Text('清除'),
              ),
            ),
        ],
      ),
    );
  }

  List<({String label, VoidCallback onDelete})> _activeFilterChips(
    List<Account> accounts,
    List<Category> categories,
  ) {
    final f = _filters;
    final chips = <({String label, VoidCallback onDelete})>[];
    if (f.type != null) {
      chips.add((
        label: _typeLabel(f.type!),
        onDelete: () => _applyFilters(f.copyWith(clearType: true)),
      ));
    }
    final rangeLabel = _rangeLabel(f);
    if (rangeLabel != null) {
      chips.add((
        label: rangeLabel,
        onDelete: () => _applyFilters(
          f.copyWith(range: _TimeRange.all, clearCustomRange: true),
        ),
      ));
    }
    if (f.accountId != null) {
      chips.add((
        label: _nameById(accounts.map((a) => (a.id, a.name)), f.accountId,
            '账户'),
        onDelete: () => _applyFilters(f.copyWith(clearAccountId: true)),
      ));
    }
    if (f.categoryId != null) {
      chips.add((
        label: _nameById(
            categories.map((c) => (c.id, c.name)), f.categoryId, '分类'),
        onDelete: () => _applyFilters(f.copyWith(clearCategoryId: true)),
      ));
    }
    final amountLabel = _amountLabel(f);
    if (amountLabel != null) {
      chips.add((
        label: amountLabel,
        onDelete: () => _applyFilters(
          f.copyWith(clearMinAmount: true, clearMaxAmount: true),
        ),
      ));
    }
    return chips;
  }

  // ── 结果区 ──────────────────────────────────────────────────

  Widget _buildResults(List<Category> categories) {
    // 未搜索：默认空态，不加载账单数据。
    if (!_searched) {
      return const XpEmptyState(
        icon: Icons.manage_search,
        title: '搜索全部账单',
        message: '输入备注、分类或标签关键词，\n或点「筛选」组合条件后搜索',
      );
    }
    final hasQuery = _lastKeyword.isNotEmpty || !_filters.isEmpty;
    if (!hasQuery) {
      return const XpEmptyState(
        icon: Icons.search_off,
        title: '请输入搜索内容',
        message: '输入关键词或设置筛选条件后再点「搜索」',
      );
    }

    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final billTagsAsync = ref.watch(_allBillTagsProvider);
    return billTagsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 8),
      error: (e, _) => XpErrorState(
        title: '标签数据加载失败',
        message: '$e',
        actionLabel: '重试',
        onAction: () => ref.invalidate(_allBillTagsProvider),
      ),
      data: (billTags) {
        final tagNameById = {for (final t in tags) t.id: t.name};
        final billTagIds = <String, Set<String>>{};
        for (final rel in billTags) {
          billTagIds.putIfAbsent(rel.billId, () => <String>{}).add(rel.tagId);
        }
        final allAsync = ref.watch(_allBillsProvider);
        return allAsync.when(
          loading: () => const XpSkeletonList(itemCount: 8),
          error: (e, _) => XpErrorState(
            title: '账单加载失败',
            message: '$e',
            actionLabel: '重试',
            onAction: () => ref.invalidate(_allBillsProvider),
          ),
          data: (all) {
            final filtered = _filter(
              all,
              categories,
              tagNameById: tagNameById,
              billTagIds: billTagIds,
            );
            if (filtered.isEmpty) {
              return XpEmptyState(
                icon: Icons.search_off,
                title: '没有符合条件的账单',
                message: '试试更换关键词或放宽筛选条件',
                actionLabel: '清除筛选',
                onAction: () => setState(() {
                  _keywordCtrl.clear();
                  _lastKeyword = '';
                  _filters = const _SearchFilters();
                }),
              );
            }
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
                _ResultSummary(
                  count: filtered.length,
                  expense: expense,
                  income: income,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 200,
                      child: XpSlidingSegmented<bool>(
                        items: const [
                          XpSegmentedItem(value: false, label: '列表'),
                          XpSegmentedItem(value: true, label: '分析'),
                        ],
                        selected: _showAnalysis,
                        onChanged: (v) => setState(() => _showAnalysis = v),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _showAnalysis
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
    // 按日分组（时间倒序，新→旧），每组一张卡片。
    final sorted = [...filtered]..sort((a, b) => b.time.compareTo(a.time));
    final groups = <_DayGroup>[];
    for (final bill in sorted) {
      final dt = DateTime.fromMillisecondsSinceEpoch(bill.time);
      final dayStart = DateTime(
        dt.year,
        dt.month,
        dt.day,
      ).millisecondsSinceEpoch;
      if (groups.isEmpty || groups.last.dayStart != dayStart) {
        groups.add(
          _DayGroup(
            dayStart: dayStart,
            day: DateTime(dt.year, dt.month, dt.day),
            bills: [bill],
          ),
        );
      } else {
        groups.last.bills.add(bill);
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.xl,
      ),
      itemCount: groups.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: XpSpacing.m),
        child: _DayGroupCard(
          group: groups[i],
          onTapBill: (bill) => BookkeepingSheet.show(context, bill: bill),
          onLongPressBill: (bill) => _delete(context, bill),
        ),
      ),
    );
  }

  /// 内存过滤：关键词（备注/分类/父分类/标签）+ 类型/账户/分类/时间/金额。
  List<Bill> _filter(
    List<Bill> all,
    List<Category> categories, {
    required Map<String, String> tagNameById,
    required Map<String, Set<String>> billTagIds,
  }) {
    final (start, end) = _timeBounds();
    final minAmount = _filters.minAmount;
    final maxAmount = _filters.maxAmount;
    final keyword = _lastKeyword.toLowerCase();
    // 分类名 + 父分类名：二级分类下搜父类名也能命中
    final catNameById = {for (final c in categories) c.id: c.name};
    final parentNameById = <String, String>{
      for (final c in categories)
        if (c.parentId != null) c.id: catNameById[c.parentId] ?? '',
    };

    return all.where((b) {
      if (b.time < start || b.time >= end) return false;
      if (_filters.type != null && b.type != _filters.type!.name) return false;
      if (_filters.accountId != null &&
          b.accountId != _filters.accountId &&
          b.incomeAccountId != _filters.accountId) {
        return false;
      }
      if (_filters.categoryId != null &&
          b.categoryId != _filters.categoryId) {
        return false;
      }
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

  (int, int) _timeBounds() {
    final now = DateTime.now();
    switch (_filters.range) {
      case _TimeRange.all:
        return (0, 1 << 62);
      case _TimeRange.thisMonth:
        return (
          DateTime(now.year, now.month).millisecondsSinceEpoch,
          DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
        );
      case _TimeRange.lastMonth:
        return (
          DateTime(now.year, now.month - 1).millisecondsSinceEpoch,
          DateTime(now.year, now.month).millisecondsSinceEpoch,
        );
      case _TimeRange.last3Months:
        return (
          DateTime(now.year, now.month - 2).millisecondsSinceEpoch,
          DateTime(now.year, now.month + 1).millisecondsSinceEpoch,
        );
      case _TimeRange.custom:
        final r = _filters.customRange;
        if (r == null) return (0, 1 << 62);
        return (
          r.start.millisecondsSinceEpoch,
          r.end.add(const Duration(days: 1)).millisecondsSinceEpoch,
        );
    }
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

/// 按 id 取名称（账户/分类 chips 展示用），找不到返回兜底名。
String _nameById(Iterable<(String, String)> pairs, String? id, String fallback) {
  if (id == null) return fallback;
  for (final (pid, name) in pairs) {
    if (pid == id) return name;
  }
  return fallback;
}

String _typeLabel(BillType t) => switch (t) {
  BillType.expense => '支出',
  BillType.income => '收入',
  BillType.transfer => '转账',
};

String? _rangeLabel(_SearchFilters f) => switch (f.range) {
  _TimeRange.all => null,
  _TimeRange.thisMonth => '本月',
  _TimeRange.lastMonth => '上月',
  _TimeRange.last3Months => '近3月',
  _TimeRange.custom => _fmtCustomRange(f.customRange),
};

String _fmtCustomRange(DateTimeRange? r) {
  if (r == null) return '自定义';
  String f(DateTime d) => '${d.month}/${d.day}';
  return '${f(r.start)}~${f(r.end)}';
}

String? _amountLabel(_SearchFilters f) {
  final min = f.minAmount;
  final max = f.maxAmount;
  if (min == null && max == null) return null;
  String y(int? v) => v == null ? '' : formatYuan(v);
  if (min != null && max != null) return '¥${y(min)}~${y(max)}';
  if (min != null) return '≥¥${y(min)}';
  return '≤¥${y(max)}';
}

/// "12345.60" → "12,345.60"（整数部分千分位，仅展示用）。
String _grouped(String raw) {
  final parts = raw.split('.');
  final digits = parts[0];
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    buf.write(digits[i]);
    final remain = digits.length - 1 - i;
    if (remain > 0 && remain % 3 == 0) buf.write(',');
  }
  return parts.length > 1 ? '${buf.toString()}.${parts[1]}' : buf.toString();
}

// ── 底部筛选面板 ──────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.initial,
    required this.accounts,
    required this.categories,
  });

  final _SearchFilters initial;
  final List<Account> accounts;
  final List<Category> categories;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late BillType? _type;
  late _TimeRange _range;
  DateTimeRange? _customRange;
  late String? _accountId;
  late String? _categoryId;
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _maxCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final f = widget.initial;
    _type = f.type;
    _range = f.range;
    _customRange = f.customRange;
    _accountId = f.accountId;
    _categoryId = f.categoryId;
    if (f.minAmount != null) _minCtrl.text = formatYuan(f.minAmount!);
    if (f.maxAmount != null) _maxCtrl.text = formatYuan(f.maxAmount!);
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  _SearchFilters get _draft => _SearchFilters(
    type: _type,
    range: _range,
    customRange: _customRange,
    accountId: _accountId,
    categoryId: _categoryId,
    minAmount: parseYuanInput(_minCtrl.text),
    maxAmount: parseYuanInput(_maxCtrl.text),
  );

  void _reset() {
    setState(() {
      _type = null;
      _range = _TimeRange.all;
      _customRange = null;
      _accountId = null;
      _categoryId = null;
      _minCtrl.clear();
      _maxCtrl.clear();
    });
  }

  Future<void> _pickAccount() async {
    final r = await showAccountPickerSheet(
      context: context,
      accounts: widget.accounts,
      selectedId: _accountId,
      title: '选择账户',
      autoLabel: '全部账户',
    );
    if (r != null) setState(() => _accountId = r.value);
  }

  Future<void> _pickCategory() async {
    final r = await _showCategoryPickerSheet(
      context: context,
      categories: widget.categories,
      selectedId: _categoryId,
    );
    if (r != null) setState(() => _categoryId = r.value);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showXpDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      initialDateRangeStart: _customRange?.start,
      initialDateRangeEnd: _customRange?.end,
      helpText: '选择搜索日期范围',
      saveText: '确定',
    );
    if (picked != null) {
      setState(() {
        _range = _TimeRange.custom;
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accById = {for (final a in widget.accounts) a.id: a.name};
    final catById = {for (final c in widget.categories) c.id: c.name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.s,
            XpSpacing.l,
            XpSpacing.s,
          ),
          child: Text(
            '筛选',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: XpSpacing.l),
            children: [
              _SectionLabel('类型'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
                child: XpSlidingSegmented<BillType?>(
                  items: const [
                    XpSegmentedItem<BillType?>(value: null, label: '全部'),
                    XpSegmentedItem<BillType?>(value: BillType.expense, label: '支出'),
                    XpSegmentedItem<BillType?>(value: BillType.income, label: '收入'),
                    XpSegmentedItem<BillType?>(value: BillType.transfer, label: '转账'),
                  ],
                  selected: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
              ),
              _SectionLabel('时间范围'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
                child: Wrap(
                  spacing: XpSpacing.s,
                  runSpacing: XpSpacing.s,
                  children: [
                    for (final r in _TimeRange.values)
                      ChoiceChip(
                        label: Text(
                          r == _TimeRange.custom
                              ? _fmtCustomRange(_customRange)
                              : r.label,
                        ),
                        selected: _range == r,
                        onSelected: (_) {
                          if (r == _TimeRange.custom) {
                            _pickCustomRange();
                          } else {
                            setState(() => _range = r);
                          }
                        },
                      ),
                  ],
                ),
              ),
              _SectionLabel('账户与分类'),
              XpParamRow(
                label: '账户',
                value: _accountId == null ? '全部账户' : (accById[_accountId] ?? '账户'),
                leadingIcon: Icons.account_balance_wallet_outlined,
                onTap: _pickAccount,
              ),
              XpParamDivider(indent: kXpParamDividerIndentWithLeading),
              XpParamRow(
                label: '分类',
                value: _categoryId == null ? '全部分类' : (catById[_categoryId] ?? '分类'),
                leadingIcon: Icons.category_outlined,
                onTap: _pickCategory,
              ),
              _SectionLabel('金额区间'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '最小金额',
                          isDense: true,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(XpRadius.s)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: XpSpacing.s),
                      child: Text('—'),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '最大金额',
                          isDense: true,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(XpRadius.s)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.s,
            XpSpacing.l,
            XpSpacing.l,
          ),
          child: Row(
            children: [
              TextButton(onPressed: _reset, child: const Text('重置')),
              const SizedBox(width: XpSpacing.s),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, _draft),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('完成'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.xs,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 分类单选面板（排除转账分类）：点选项即收起并回传所选分类。
/// 关闭返回 null，调用方视为「未更改」；「全部分类」回传 PickerChoice(null)。
Future<PickerChoice?> _showCategoryPickerSheet({
  required BuildContext context,
  required List<Category> categories,
  required String? selectedId,
}) {
  final cats = categories
      .where((c) => c.type != BillType.transfer.name)
      .toList();
  final expenseCats =
      cats.where((c) => c.type == BillType.expense.name).toList();
  final incomeCats =
      cats.where((c) => c.type == BillType.income.name).toList();
  final rows =
      1 +
      (expenseCats.isEmpty ? 0 : 1 + expenseCats.length) +
      (incomeCats.isEmpty ? 0 : 1 + incomeCats.length);
  final screenH = MediaQuery.sizeOf(context).height;
  final heightFactor = ((rows * 56 + 100) / screenH).clamp(0.3, 0.85);

  return showXpSheet<PickerChoice>(
    context: context,
    heightFactor: heightFactor,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.s,
              XpSpacing.l,
              XpSpacing.s,
            ),
            child: Text(
              '选择分类',
              style: Theme.of(
                sheetContext,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.only(bottom: XpSpacing.l),
              children: [
                _CatOption(
                  icon: Icons.all_inclusive,
                  color: colorScheme.primary,
                  title: '全部分类',
                  selected: selectedId == null,
                  onTap: () =>
                      Navigator.pop(sheetContext, const PickerChoice(null)),
                ),
                if (expenseCats.isNotEmpty) ...[
                  const _CatGroupTitle('支出'),
                  for (final c in expenseCats) ...[
                    _CatOption(
                      category: c,
                      title: c.name,
                      selected: selectedId == c.id,
                      onTap: () =>
                          Navigator.pop(sheetContext, PickerChoice(c.id)),
                    ),
                  ],
                ],
                if (incomeCats.isNotEmpty) ...[
                  const _CatGroupTitle('收入'),
                  for (final c in incomeCats) ...[
                    _CatOption(
                      category: c,
                      title: c.name,
                      selected: selectedId == c.id,
                      onTap: () =>
                          Navigator.pop(sheetContext, PickerChoice(c.id)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _CatGroupTitle extends StatelessWidget {
  const _CatGroupTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.xs,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _CatOption extends StatelessWidget {
  const _CatOption({
    this.category,
    this.icon,
    this.color = XpBrandColors.primary,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final Category? category;
  final IconData? icon;
  final Color color;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = category == null ? color : hexToColor(category!.color);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: XpSpacing.m,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accent.withValues(alpha: 0.15),
              foregroundColor: accent,
              child: AppIcon(name: category?.icon, icon: icon, size: 20),
            ),
            const SizedBox(width: XpSpacing.m),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const SizedBox(width: XpSpacing.s),
            SizedBox(
              width: 20,
              height: 20,
              child: selected
                  ? Icon(Icons.check, size: 20, color: colorScheme.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── 结果摘要与按日分组列表 ───────────────────────────────────

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.count,
    required this.expense,
    required this.income,
  });

  final int count;
  final int expense;
  final int income;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final base = textTheme.labelMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('共 $count 笔', style: base),
          const Spacer(),
          Text.rich(
            TextSpan(
              style: base,
              children: [
                const TextSpan(text: '支出 '),
                TextSpan(
                  text: _grouped(formatYuan(expense)),
                  style: base?.copyWith(
                    color: XpSemanticColors.expense,
                    fontWeight: FontWeight.w600,
                  ).tabular,
                ),
                const TextSpan(text: ' · 收入 '),
                TextSpan(
                  text: _grouped(formatYuan(income)),
                  style: base?.copyWith(
                    color: XpSemanticColors.income,
                    fontWeight: FontWeight.w600,
                  ).tabular,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGroup {
  _DayGroup({required this.dayStart, required this.day, required this.bills});

  final int dayStart;
  final DateTime day;
  final List<Bill> bills;

  int get expense => bills
      .where((b) => b.type == BillType.expense.name)
      .fold(0, (s, b) => s + b.amount);

  int get income => bills
      .where((b) => b.type == BillType.income.name)
      .fold(0, (s, b) => s + b.amount);
}

/// 单日账单分组卡：组头（日期 + 当日小计）+ 当日账单行。
class _DayGroupCard extends StatelessWidget {
  const _DayGroupCard({
    required this.group,
    required this.onTapBill,
    required this.onLongPressBill,
  });

  final _DayGroup group;
  final void Function(Bill bill) onTapBill;
  final void Function(Bill bill) onLongPressBill;

  static const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final d = group.day;
    final isToday =
        now.year == d.year && now.month == d.month && now.day == d.day;
    final label =
        '${d.month}月${d.day}日 ${_weekdays[d.weekday - 1]}${isToday ? ' · 今天' : ''}';

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final parts = <String>[
      if (group.expense > 0) '支 ${_grouped(formatYuan(group.expense))}',
      if (group.income > 0) '收 ${_grouped(formatYuan(group.income))}',
    ];

    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.m,
              XpSpacing.l,
              XpSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (parts.isNotEmpty)
                  Text(
                    parts.join(' · '),
                    style: textTheme.bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)
                        .tabular,
                  ),
              ],
            ),
          ),
          for (var i = 0; i < group.bills.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: XpSpacing.l,
                endIndent: XpSpacing.l,
              ),
            BillTile(
              bill: group.bills[i],
              onTap: () => onTapBill(group.bills[i]),
              onLongPress: () => onLongPressBill(group.bills[i]),
            ),
          ],
        ],
      ),
    );
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

// ── 搜索结果分析视图（趋势 + 分类占比 + 标签词云） ─────────────

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

  @override
  Widget build(BuildContext context) {
    final billTagsAsync = ref.watch(_allBillTagsProvider);
    return billTagsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 4),
      error: (e, _) => XpErrorState(
        title: '标签数据加载失败',
        message: '$e',
        actionLabel: '重试',
        onAction: () => ref.invalidate(_allBillTagsProvider),
      ),
      data: (billTags) {
        final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
        final tagCounts = _tagCounts(widget.bills, billTags);
        final series = _trendSeries(widget.bills, _focus, _byMonth);
        final cats = _categorySums(widget.bills, _focus);
        final textTheme = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.all(XpSpacing.l),
          children: [
            SizedBox(
              width: 280,
              child: XpSlidingSegmented<_FocusType>(
                items: const [
                  XpSegmentedItem(value: _FocusType.expense, label: '支出'),
                  XpSegmentedItem(value: _FocusType.income, label: '收入'),
                  XpSegmentedItem(value: _FocusType.balance, label: '结余'),
                ],
                selected: _focus,
                onChanged: (v) => setState(() => _focus = v),
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            SizedBox(
              width: 160,
              child: XpSlidingSegmented<bool>(
                items: const [
                  XpSegmentedItem(value: false, label: '按天'),
                  XpSegmentedItem(value: true, label: '按月'),
                ],
                selected: _byMonth,
                onChanged: (v) => setState(() => _byMonth = v),
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            Text('趋势', style: textTheme.titleSmall),
            const SizedBox(height: XpSpacing.s),
            SizedBox(
              height: 180,
              child: series.isEmpty
                  ? const XpEmptyState(icon: Icons.show_chart, title: '暂无趋势数据')
                  : _TrendLine(
                      points: series,
                      byMonth: _byMonth,
                      color: _focusColor(),
                    ),
            ),
            if (_focus != _FocusType.balance) ...[
              const SizedBox(height: XpSpacing.l),
              Text('分类占比', style: textTheme.titleSmall),
              const SizedBox(height: XpSpacing.s),
              SizedBox(
                height: 140,
                child: _FocusPie(sums: cats, categories: widget.categories),
              ),
            ],
            const SizedBox(height: XpSpacing.l),
            Text('标签词云', style: textTheme.titleSmall),
            const SizedBox(height: XpSpacing.s),
            _TagCloud(counts: tagCounts, tags: tags),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  Color _focusColor() => switch (_focus) {
    _FocusType.expense => XpSemanticColors.expense,
    _FocusType.income => XpSemanticColors.income,
    _FocusType.balance => Theme.of(context).colorScheme.primary,
  };

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
  const _TrendLine({
    required this.points,
    required this.byMonth,
    required this.color,
  });

  final List<({int time, int value})> points;
  final bool byMonth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                style: textTheme.labelSmall,
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
                  padding: const EdgeInsets.only(top: XpSpacing.xs),
                  child: Text(
                    _xLabel(points[i].time, byMonth),
                    style: textTheme.labelSmall,
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
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
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
    // 图表内嵌小空态（140 高受限），标准 XpEmptyState 含 32 padding 会溢出，保留轻量 Text。
    if (total == 0) {
      return Center(
        child: Text(
          '暂无数据',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }
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
        const SizedBox(width: XpSpacing.l),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < top5.length; i++)
                _legend(
                  context,
                  _palette[i % _palette.length],
                  name(top5[i].categoryId),
                  formatYuan(top5[i].amount),
                ),
              if (other > 0)
                _legend(context, _palette[5], '其他', formatYuan(other)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String name, String value) {
    final textTheme = Theme.of(context).textTheme;
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
              style: textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
      spacing: XpSpacing.s,
      runSpacing: XpSpacing.s,
      children: [
        for (final e in entries)
          Chip(
            label: Text(
              '${tagName[e.key] ?? e.key}（${e.value}）',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10 + (e.value / maxCount * 8).clamp(0, 8),
              ),
            ),
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
