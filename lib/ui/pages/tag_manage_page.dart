import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/currency_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_snack.dart';

/// 标签管理页（列表 + 新增/编辑/删除）。
class TagManagePage extends ConsumerStatefulWidget {
  const TagManagePage({super.key});

  @override
  ConsumerState<TagManagePage> createState() => _TagManagePageState();
}

class _TagManagePageState extends ConsumerState<TagManagePage>
    with XpPageScaffold<TagManagePage> {
  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(tagsProvider);
    return buildXpScaffold(
      appBar: AppBar(title: const Text('标签管理')),
      body: tagsAsync.when(
        loading: () => const XpSkeletonList(itemCount: 3),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (tags) {
          if (tags.isEmpty) {
            return const Center(child: Text('暂无标签，点击右下角新增'));
          }
          return ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, i) {
              final tag = tags[i];
              final colorHex = tag.color ?? '#4D3C77';
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _parseColor(
                    colorHex,
                  ).withValues(alpha: 0.15),
                  child: AppIcon(
                    icon: Icons.label,
                    size: 16,
                    color: _parseColor(colorHex),
                  ),
                ),
                title: Text(tag.name),
                subtitle: Text(
                  '排序 ${tag.sort}${tag.groupId != null ? ' · 分组' : ''}',
                ),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _showForm(context, ref, tag),
                onLongPress: () => _delete(context, ref, tag),
              );
            },
          );
        },
      ),
      floatingActionButton: XpFab(
        onPressed: () => _showForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('新增标签'),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, Tag? tag) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TagFormSheet(tag: tag),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Tag tag) async {
    final confirmed = await confirmXpDialog(
      context,
      title: '删除标签',
      content: '确定删除「${tag.name}」？关联账单上的标签将同步移除。',
      confirmLabel: '删除',
      danger: true,
    );
    if (confirmed && context.mounted) {
      await ref.read(tagRepoProvider).delete(tag.id);
    }
  }
}

Color _parseColor(String color) {
  final hex = color.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16) ?? 0x4D3C77;
  return Color(0xFF000000 | value);
}

class _TagFormSheet extends ConsumerStatefulWidget {
  const _TagFormSheet({this.tag});

  final Tag? tag;

  @override
  ConsumerState<_TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<_TagFormSheet> {
  late final TextEditingController _nameCtrl;
  String _color = '#4D3C77';
  int _sort = 0;
  String? _preferCurrency;
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
    _nameCtrl = TextEditingController(text: widget.tag?.name ?? '');
    _color = widget.tag?.color ?? '#4D3C77';
    _sort = widget.tag?.sort ?? 0;
    _preferCurrency = widget.tag?.preferCurrency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              widget.tag == null ? '新增标签' : '编辑标签',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '标签名称',
                border: OutlineInputBorder(),
              ),
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: ValueKey(_preferCurrency),
              initialValue: _preferCurrency,
              decoration: const InputDecoration(
                labelText: '记账币种（可选；选中该标签记账时自动切换）',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('（不指定）'),
                ),
                for (final code in CurrencyService.supportedCodes)
                  DropdownMenuItem<String?>(value: code, child: Text(code)),
              ],
              onChanged: (v) => setState(() => _preferCurrency = v),
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
      showXpSnack(context, '标签名称不能为空', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(tagRepoProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      if (widget.tag == null) {
        await repo.insert(
          TagsCompanion.insert(
            id: genId(),
            name: name,
            color: Value(_color),
            groupId: const Value(null),
            preferCurrency: Value(_preferCurrency),
            sort: Value(_sort),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        await repo.update(
          widget.tag!.id,
          TagsCompanion(
            name: Value(name),
            color: Value(_color),
            preferCurrency: Value(_preferCurrency),
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
