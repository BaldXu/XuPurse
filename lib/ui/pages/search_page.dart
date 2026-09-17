import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../widgets/bill_tile.dart';
import 'bookkeeping_sheet.dart';

/// 搜索页：关键词（备注/分类/标签）+ 类型/账户/分类/时间段/金额 多条件筛选。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _keywordCtrl = TextEditingController();
  BillType? _type;
  String? _accountId;
  String? _categoryId;
  int _range = 0; // 0 全部 / 1 本月 / 2 上月
  String? _minAmountText;
  String? _maxAmountText;

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

    return Scaffold(
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
    final allAsync = ref.watch(_allBillsProvider);
    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (all) {
        final filtered = _filter(all, categories);
        var expense = 0, income = 0;
        for (final b in filtered) {
          if (b.type == BillType.expense.name) expense += b.amount;
          if (b.type == BillType.income.name) income += b.amount;
        }
        if (filtered.isEmpty) {
          return const Center(child: Text('没有符合条件的账单'));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '共 ${filtered.length} 笔',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  Text(
                    '支出 ${formatYuan(expense)} · 收入 ${formatYuan(income)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final bill = filtered[i];
                  return BillTile(
                    bill: bill,
                    onTap: () => BookkeepingSheet.show(context, bill: bill),
                    onLongPress: () => _delete(context, bill),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<Bill> _filter(List<Bill> all, List<Category> categories) {
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
    final catNameById = {for (final c in categories) c.id: c.name};

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
        if (!commentMatch && !catMatch) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _delete(BuildContext context, Bill bill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账单'),
        content: const Text('删除后余额与快照将同步回滚，确定删除？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(billServiceProvider).deleteBill(bill.id);
      ref.read(_revisionProvider.notifier).state++;
    }
  }
}

/// 全量账单（时间升序；搜索在内存过滤）。
/// 账单数据变更时通过 [_revisionProvider] 触发重查。
final _revisionProvider = StateProvider<int>((ref) => 0);

final _allBillsProvider = FutureProvider<List<Bill>>((ref) {
  ref.watch(_revisionProvider);
  return ref.watch(billRepoProvider).getAll();
});
