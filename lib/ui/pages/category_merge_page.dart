import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/icons.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_snack.dart';

/// 分类合并页（分类管理页 - 标题栏「分类合并」进入）。
///
/// 两步：① 多选同类型分类（选中父分类会连同其全部子分类一并合并）；
/// ② 输入/选择合并后分类名称与图标，确认后合并为一个分类。
class CategoryMergePage extends ConsumerStatefulWidget {
  const CategoryMergePage({super.key});

  @override
  ConsumerState<CategoryMergePage> createState() => _CategoryMergePageState();
}

class _CategoryMergePageState extends ConsumerState<CategoryMergePage>
    with XpPageScaffold<CategoryMergePage> {
  /// 当前合并的类型（同类型才能合并）
  BillType _type = BillType.expense;

  /// 已勾选的分类 id
  final Set<String> _selected = {};

  /// 第二步：合并后名称（预填首个所选分类名，可改/可输入新名）
  final TextEditingController _nameCtrl = TextEditingController();
  String _icon = 'bookmark';
  bool _step2 = false;
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(
        title: Text(_step2 ? '选择合并后分类' : '分类合并'),
        leading: _step2
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '返回选择分类',
                onPressed: _busy ? null : () => setState(() => _step2 = false),
              )
            : null,
      ),
      body: _step2 ? _buildTargetStep() : _buildSelectStep(scheme),
    );
  }

  // ---------- 第一步：多选分类 ----------

  Widget _buildSelectStep(ColorScheme scheme) {
    final all = ref.watch(categoriesProvider).valueOrNull ?? [];
    final typed = all.where((c) => c.type == _type.name).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.s,
            XpSpacing.l,
            XpSpacing.xs,
          ),
          child: Text(
            '勾选 2 个及以上同类型分类合并；选中父分类会连同其全部子分类一并合并。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
          child: SegmentedButton<BillType>(
            segments: const [
              ButtonSegment(value: BillType.expense, label: Text('支出')),
              ButtonSegment(value: BillType.income, label: Text('收入')),
              ButtonSegment(value: BillType.transfer, label: Text('转账')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              _selected.clear();
            }),
          ),
        ),
        Expanded(
          child: typed.isEmpty
              ? const XpEmptyState(
                  icon: Icons.category_outlined,
                  title: '暂无分类',
                  message: '该类型下还没有分类',
                )
              : _buildCategoryList(typed),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(XpSpacing.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selected.length >= 2 ? _goStep2 : null,
                child: Text('下一步（已选 ${_selected.length} 个）'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(List<Category> typed) {
    final parents = typed.where((c) => c.parentId == null).toList();
    final childrenByParent = <String, List<Category>>{};
    for (final c in typed) {
      if (c.parentId != null) {
        (childrenByParent[c.parentId!] ??= []).add(c);
      }
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        for (final parent in parents) ...[
          _CategoryCheckTile(
            category: parent,
            checked: _selected.contains(parent.id),
            subtitle:
                '${childrenByParent[parent.id]?.length ?? 0} 个子分类'
                '（合并时一并合并）',
            onChanged: (v) => _toggle(parent.id, v),
          ),
          for (final child in childrenByParent[parent.id] ?? [])
            _CategoryCheckTile(
              category: child,
              indent: true,
              checked: _selected.contains(child.id),
              subtitle: '子分类',
              onChanged: (v) => _toggle(child.id, v),
            ),
        ],
      ],
    );
  }

  void _toggle(String id, bool value) {
    setState(() {
      if (value) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  // ---------- 第二步：名称 + 图标 ----------

  void _goStep2() {
    final all = ref.read(categoriesProvider).valueOrNull ?? [];
    final first = all
        .where((c) => _selected.contains(c.id))
        .toList()
        .firstOrNull;
    _nameCtrl.text = first?.name ?? '';
    _icon = first?.icon ?? 'bookmark';
    setState(() => _step2 = true);
  }

  Widget _buildTargetStep() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.m,
              XpSpacing.l,
              XpSpacing.l,
            ),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '合并后分类名称',
                  hintText: '可保留所选分类名，或输入新名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: XpSpacing.l),
              Text('图标', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: XpSpacing.s),
              Wrap(
                spacing: XpSpacing.s,
                runSpacing: XpSpacing.s,
                children: [
                  for (final name in iconRegistry.keys.toList()..sort())
                    GestureDetector(
                      onTap: _busy ? null : () => setState(() => _icon = name),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _icon == name
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surfaceContainerHighest,
                          border: Border.all(
                            color: _icon == name
                                ? scheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(name: name, size: 22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: XpSpacing.l),
              Text(
                '合并后，所选分类及其全部子分类的账单都会归到该分类下。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(XpSpacing.m),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _merge,
                child: Text(_busy ? '合并中…' : '完成合并'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _merge() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showXpSnack(context, '请输入合并后分类名称', error: true);
      return;
    }
    final all = ref.read(categoriesProvider).valueOrNull ?? [];
    final typedSelected = all.where((c) => _selected.contains(c.id)).toList();
    // 名称命中某个所选分类 → 保留它；否则新建同名分类
    String? targetId;
    for (final c in typedSelected) {
      if (c.name == name) {
        targetId = c.id;
        break;
      }
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(categoryServiceProvider)
          .mergeCategories(
            type: _type,
            selectedIds: _selected.toList(),
            targetId: targetId,
            name: name,
            icon: _icon,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showXpSnack(context, '合并失败：$e', error: true);
    }
  }
}

/// 分类勾选行：复选框 + 图标 + 名称/副标题（子分类缩进）。
class _CategoryCheckTile extends StatelessWidget {
  const _CategoryCheckTile({
    required this.category,
    required this.checked,
    required this.onChanged,
    this.indent = false,
    this.subtitle,
  });

  final Category category;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final bool indent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorHex = category.color ?? '#4D3C77';
    final color = _parseColor(colorHex);
    return CheckboxListTile(
      value: checked,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.only(left: indent ? 40 : 16, right: 16),
      title: Text(category.name),
      subtitle: subtitle == null ? null : Text(subtitle!),
      secondary: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.15),
        child: AppIcon(name: category.icon, size: 16, color: color),
      ),
    );
  }
}

Color _parseColor(String color) {
  final hex = color.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16) ?? 0x4D3C77;
  return Color(0xFF000000 | value);
}
