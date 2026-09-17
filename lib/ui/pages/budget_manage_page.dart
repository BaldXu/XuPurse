import 'package:drift/drift.dart' show Value, Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';

/// 预算管理页（卡片 + 进度 + 表单 + 删除）。
class BudgetManagePage extends ConsumerWidget {
  const BudgetManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(_budgetsWithUsageProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('预算管理')),
      body: budgetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('暂无预算，点击右下角新增'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            itemBuilder: (context, i) => _BudgetCard(item: items[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => const BudgetFormSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('新增预算'),
      ),
    );
  }
}

/// 预算 + 当前周期内支出（用于进度条）。
class _BudgetWithUsage {
  const _BudgetWithUsage({required this.budget, required this.spent});

  final Budget budget;
  final int spent;
}

final _budgetsWithUsageProvider = StreamProvider<List<_BudgetWithUsage>>((
  ref,
) async* {
  final db = ref.watch(dbProvider);
  await for (final budgets in ref.watch(budgetRepoProvider).watchAll()) {
    final items = <_BudgetWithUsage>[];
    for (final b in budgets) {
      var spent = 0;
      if (b.type == BillType.expense.name && b.startTime != null) {
        final end =
            b.endTime ??
            DateTime(
              DateTime.fromMillisecondsSinceEpoch(b.startTime!).year,
              DateTime.fromMillisecondsSinceEpoch(b.startTime!).month + 1,
            ).millisecondsSinceEpoch;
        final rows = await db
            .customSelect(
              'SELECT COALESCE(SUM(amount), 0) AS s FROM bills '
              'WHERE type = ? AND time >= ? AND time < ? '
              '${b.categoryId != null ? 'AND category_id = ?' : ''}',
              variables: [
                Variable(BillType.expense.name),
                Variable(b.startTime!),
                Variable(end),
                if (b.categoryId != null) Variable(b.categoryId),
              ],
            )
            .get();
        spent = rows.first.data['s'] as int? ?? 0;
      }
      items.add(_BudgetWithUsage(budget: b, spent: spent));
    }
    yield items;
  }
});

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.item});

  final _BudgetWithUsage item;

  @override
  Widget build(BuildContext context) {
    final b = item.budget;
    final textTheme = Theme.of(context).textTheme;
    final progress = b.amount <= 0
        ? 0.0
        : (item.spent / b.amount).clamp(0.0, 1.0);
    final over = item.spent > b.amount;
    final periodLabel = switch (b.periodType) {
      'month' => '月度',
      'year' => '年度',
      _ => '自定义',
    };
    final start = b.startTime == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(b.startTime!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    b.name.isEmpty ? '未命名预算' : b.name,
                    style: textTheme.titleMedium,
                  ),
                ),
                Text(
                  b.type == BillType.income.name ? '收入预算' : '支出预算',
                  style: textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '¥${formatYuan(b.amount)} / $periodLabel',
                  style: textTheme.bodyMedium,
                ),
                if (start != null)
                  Text(
                    ' · ${start.month}月起',
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: over
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '已用 ${formatYuan(item.spent)}'
              '${b.amount > 0 ? ' / ${(progress * 100).toStringAsFixed(0)}%' : ''}'
              '${over ? ' · 已超支' : ''}',
              style: textTheme.bodySmall?.copyWith(
                color: over
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 预算表单（新增/编辑）。
class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({super.key, this.budget});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  BillType _type = BillType.expense;
  BudgetPeriodType _period = BudgetPeriodType.month;
  String? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.budget;
    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _amountCtrl = TextEditingController(
      text: b == null ? '' : formatYuan(b.amount),
    );
    _type = EnumDbName.fromDbName(BillType.values, b?.type, BillType.expense);
    _period = EnumDbName.fromDbName(
      BudgetPeriodType.values,
      b?.periodType,
      BudgetPeriodType.month,
    );
    _categoryId = b?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = (ref.watch(categoriesProvider).valueOrNull ?? [])
        .where((c) => c.type == BillType.expense.name)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.budget == null ? '新增预算' : '编辑预算',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '预算名称（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '预算金额（元）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<BillType>(
              segments: const [
                ButtonSegment(value: BillType.expense, label: Text('支出')),
                ButtonSegment(value: BillType.income, label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: 12),
            SegmentedButton<BudgetPeriodType>(
              segments: const [
                ButtonSegment(value: BudgetPeriodType.month, label: Text('月度')),
                ButtonSegment(value: BudgetPeriodType.year, label: Text('年度')),
              ],
              selected: {_period},
              onSelectionChanged: (s) => setState(() => _period = s.first),
            ),
            if (_type == BillType.expense) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey(_categoryId),
                initialValue: _categoryId,
                decoration: const InputDecoration(
                  labelText: '限定分类（可选，空为全部支出）',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('（全部支出）'),
                  ),
                  for (final c in expenseCategories)
                    DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amountYuan = double.tryParse(_amountCtrl.text.trim());
    if (amountYuan == null || amountYuan <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的预算金额')));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(budgetRepoProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final nowDate = DateTime.now();
    final start = switch (_period) {
      BudgetPeriodType.month => DateTime(
        nowDate.year,
        nowDate.month,
      ).millisecondsSinceEpoch,
      BudgetPeriodType.year => DateTime(nowDate.year).millisecondsSinceEpoch,
      _ => nowDate.millisecondsSinceEpoch,
    };
    final end = switch (_period) {
      BudgetPeriodType.month => DateTime(
        nowDate.year,
        nowDate.month + 1,
      ).millisecondsSinceEpoch,
      BudgetPeriodType.year => DateTime(
        nowDate.year + 1,
      ).millisecondsSinceEpoch,
      _ => null,
    };
    try {
      if (widget.budget == null) {
        await repo.insert(
          BudgetsCompanion.insert(
            id: genId(),
            name: _nameCtrl.text.trim(),
            categoryId: Value(_categoryId),
            type: _type.name,
            periodType: _period.name,
            amount: yuanToAmount(amountYuan),
            startTime: Value(start),
            endTime: Value(end),
            enabled: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await repo.update(
          widget.budget!.id,
          BudgetsCompanion(
            name: Value(_nameCtrl.text.trim()),
            categoryId: Value(_categoryId),
            type: Value(_type.name),
            periodType: Value(_period.name),
            amount: Value(yuanToAmount(amountYuan)),
            startTime: Value(start),
            endTime: Value(end),
            updatedAt: Value(now),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$e')));
    }
  }
}
