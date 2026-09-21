import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_snack.dart';
import '../../state/providers.dart';

/// 分类管理页（两级树；支出/收入/转账 三 tab）。
class CategoryManagePage extends ConsumerStatefulWidget {
  const CategoryManagePage({super.key});

  @override
  ConsumerState<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage>
    with XpPageScaffold<CategoryManagePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: buildXpScaffold(
        appBar: AppBar(
          title: const Text('分类管理'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '支出'),
              Tab(text: '收入'),
              Tab(text: '转账'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final type in BillType.values) _CategoryList(type: type),
          ],
        ),
        floatingActionButton: XpFab(
          onPressed: () => showXpSheet<void>(
            context: context,
            builder: (_) => const CategoryFormSheet(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('新增分类'),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  const _CategoryList({required this.type});

  final BillType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(categoriesProvider).valueOrNull ?? [];
    final typed = all.where((c) => c.type == type.name).toList();
    if (typed.isEmpty) {
      return const Center(child: Text('暂无分类，点击右下角新增'));
    }
    final parents = typed.where((c) => c.parentId == null).toList();
    final childrenByParent = <String, List<Category>>{};
    for (final c in typed) {
      if (c.parentId != null) {
        (childrenByParent[c.parentId!] ??= []).add(c);
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final parent in parents) ...[
          _CategoryTile(
            category: parent,
            childCount: childrenByParent[parent.id]?.length ?? 0,
            onTap: () => _edit(context, ref, parent),
            onLongPress: () => _delete(context, ref, parent, typed),
          ),
          for (final child in childrenByParent[parent.id] ?? [])
            _CategoryTile(
              category: child,
              indent: true,
              onTap: () => _edit(context, ref, child),
              onLongPress: () => _delete(context, ref, child, typed),
            ),
          if (parent != parents.last) const Divider(height: 1),
        ],
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Category c) {
    return showXpSheet<void>(
      context: context,
      builder: (_) => CategoryFormSheet(category: c),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Category c,
    List<Category> all,
  ) async {
    final childrenCount = c.parentId == null
        ? await ref.read(categoryRepoProvider).countChildren(c.id)
        : 0;
    if (childrenCount > 0) {
      if (context.mounted) {
        showXpSnack(context, '请先删除该分类下的子分类', error: true);
      }
      return;
    }
    final billCount = await ref.read(billRepoProvider).countByCategoryId(c.id);
    if (!context.mounted) return;
    final confirmed = await confirmXpDialog(
      context,
      title: '删除分类',
      content: billCount > 0
          ? '该分类下还有 $billCount 笔账单，删除后账单将失去分类归属，确定删除？'
          : '确定删除「${c.name}」？',
      confirmLabel: '删除',
      danger: true,
    );
    if (confirmed && context.mounted) {
      await ref.read(categoryRepoProvider).delete(c.id);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    this.indent = false,
    this.childCount = 0,
    required this.onTap,
    required this.onLongPress,
  });

  final Category category;
  final bool indent;
  final int childCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorHex = category.color ?? '#4D3C77';
    final color = _parseColor(colorHex);
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: EdgeInsets.only(left: indent ? 40 : 16, right: 16),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.15),
        child: AppIcon(icon: Icons.bookmark, size: 16, color: color),
      ),
      title: Text(category.name),
      subtitle: category.parentId == null
          ? Text('$childCount 个子分类 · 排序 ${category.sort}')
          : Text('子分类 · 排序 ${category.sort}'),
      trailing: const Icon(Icons.edit_outlined, size: 18),
    );
  }
}

Color _parseColor(String color) {
  final hex = color.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16) ?? 0x4D3C77;
  return Color(0xFF000000 | value);
}

/// 分类表单（新增/编辑）。
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  BillType _type = BillType.expense;
  String? _parentId;
  String _color = '#4D3C77';
  int _sort = 0;
  bool _saving = false;

  static const _palette = [
    '#5470C6',
    '#91CC75',
    '#FAC858',
    '#EE6666',
    '#73C0DE',
    '#3BA272',
    '#EA7CCC',
    '#9A60B4',
    '#FC8452',
    '#F472B6',
    '#4D3C77',
    '#FF0000',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _type = EnumDbName.fromDbName(BillType.values, c?.type, BillType.expense);
    _parentId = c?.parentId;
    _color = c?.color ?? '#4D3C77';
    _sort = c?.sort ?? 0;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parents = (ref.watch(categoriesProvider).valueOrNull ?? [])
        .where((c) => c.type == _type.name && c.parentId == null)
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
              widget.category == null ? '新增分类' : '编辑分类',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<BillType>(
              segments: const [
                ButtonSegment(value: BillType.expense, label: Text('支出')),
                ButtonSegment(value: BillType.income, label: Text('收入')),
                ButtonSegment(value: BillType.transfer, label: Text('转账')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _parentId = null;
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '分类名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _parentId,
              decoration: const InputDecoration(
                labelText: '父分类（可选）',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('（无，作为一级分类）'),
                ),
                for (final p in parents)
                  DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '排序（数字越小越靠前）',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _sort = int.tryParse(v) ?? 0,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final hex in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: _parseColor(hex),
                      child: _color == hex
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showXpSnack(context, '分类名称不能为空', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(categoryRepoProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      if (widget.category == null) {
        await repo.insert(
          CategoriesCompanion.insert(
            id: genId(),
            type: _type.name,
            name: name,
            icon: const Value(null),
            color: Value(_color),
            parentId: Value(_parentId),
            customName: Value(true),
            defaultSelect: const Value(false),
            sort: Value(_sort),
            seedKey: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await repo.update(
          widget.category!.id,
          CategoriesCompanion(
            type: Value(_type.name),
            name: Value(name),
            color: Value(_color),
            parentId: Value(_parentId),
            customName: Value(true),
            sort: Value(_sort),
            updatedAt: Value(now),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showXpSnack(context, '保存失败：$e', error: true);
    }
  }
}
