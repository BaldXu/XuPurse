import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/bill_list_repository.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/app_icon.dart';

/// 清单内分类管理：改名 / 删除 / 新增。
///
/// 这些分类只属于当前消费清单，与记账的全局分类无关。
class BillListSectionsPage extends ConsumerStatefulWidget {
  const BillListSectionsPage({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<BillListSectionsPage> createState() =>
      _BillListSectionsPageState();
}

class _BillListSectionsPageState extends ConsumerState<BillListSectionsPage>
    with XpPageScaffold<BillListSectionsPage> {
  late final Stream<List<BillListSection>> _sections =
      ref.read(billListRepoProvider).watchSections(widget.listId);
  late final Stream<List<BillListItemView>> _items =
      ref.read(billListRepoProvider).watchItems(widget.listId);

  Future<String?> _askName({String? initial}) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final name = await showXpDialog<String>(
      context: context,
      title: initial == null ? '新建分类' : '重命名分类',
      contentWidget: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 12,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v),
        decoration: const InputDecoration(
          labelText: '分类名称',
          hintText: '如：前期准备、交通',
          counterText: '',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(ctrl.text),
          child: const Text('保存'),
        ),
      ],
    );
    ctrl.dispose();
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> _create() async {
    final name = await _askName();
    if (name == null || !mounted) return;
    await ref
        .read(billListRepoProvider)
        .createSection(widget.listId, name);
  }

  Future<void> _rename(BillListSection section) async {
    final name = await _askName(initial: section.name);
    if (name == null || !mounted) return;
    await ref.read(billListRepoProvider).renameSection(section.id, name);
  }

  Future<void> _delete(BillListSection section) async {
    final ok = await confirmXpDialog(
      context,
      title: '删除分类「${section.name}」？',
      content: '这个分类下的明细会回到「未分类」，账单本身不受影响。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok || !mounted) return;
    await ref
        .read(billListRepoProvider)
        .deleteSection(widget.listId, section.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('清单分类设置')),
      floatingActionButton: XpFab(
        tooltip: '新建分类',
        onPressed: _create,
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BillListSection>>(
        stream: _sections,
        builder: (context, secSnap) {
          final sections = secSnap.data ?? const <BillListSection>[];
          return StreamBuilder<List<BillListItemView>>(
            stream: _items,
            builder: (context, itemSnap) {
              final items = itemSnap.data ?? const <BillListItemView>[];
              final countBySection = <String?, int>{};
              for (final item in items) {
                countBySection.update(
                  item.sectionId,
                  (v) => v + 1,
                  ifAbsent: () => 1,
                );
              }
              final uncategorized = countBySection[null] ?? 0;
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  XpSpacing.l,
                  XpSpacing.s,
                  XpSpacing.l,
                  96,
                ),
                children: [
                  Text(
                    '这些分类只用于当前消费清单，和记账时的分类互不影响。'
                    '删除分类后，里面的明细会回到「未分类」。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: XpSpacing.m),
                  if (sections.isEmpty)
                    const XpEmptyState(
                      icon: Icons.category_outlined,
                      title: '还没有分类',
                      message: '点右下角新建一个，比如「前期准备」「交通」。',
                    )
                  else
                    for (final section in sections)
                      Card(
                        margin: const EdgeInsets.only(bottom: XpSpacing.s),
                        child: ListTile(
                          leading: AppIcon(
                            icon: Icons.label_outline,
                            color: scheme.primary,
                          ),
                          title: Text(section.name),
                          subtitle: Text(
                            '${countBySection[section.id] ?? 0} 笔',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: '重命名',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _rename(section),
                              ),
                              IconButton(
                                tooltip: '删除',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                onPressed: () => _delete(section),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (uncategorized > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: XpSpacing.s),
                      child: Text(
                        '未分类：$uncategorized 笔（在清单详情里逐笔设置，或用「自动分类」）',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
