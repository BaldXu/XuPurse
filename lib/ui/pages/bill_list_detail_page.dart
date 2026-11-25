import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bill_list_repository.dart';
import '../../domain/ai/ai_config.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart';
import '../widgets/xp_button.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'bill_list_picker_page.dart';
import 'bill_list_sections_page.dart';
import 'ai_list_chat_page.dart';
import 'bookkeeping_page.dart';

/// 消费清单详情：按清单内分类分组显示明细，支持自动分类与手动调整。
class BillListDetailPage extends ConsumerStatefulWidget {
  const BillListDetailPage({
    super.key,
    required this.listId,
    required this.title,
  });

  final String listId;
  final String title;

  @override
  ConsumerState<BillListDetailPage> createState() => _BillListDetailPageState();
}

class _BillListDetailPageState extends ConsumerState<BillListDetailPage>
    with XpPageScaffold<BillListDetailPage> {
  late final Stream<List<BillListItemView>> _items =
      ref.read(billListRepoProvider).watchItems(widget.listId);
  late final Stream<List<BillListSection>> _sections =
      ref.read(billListRepoProvider).watchSections(widget.listId);

  BillListRepository get _repo => ref.read(billListRepoProvider);

  Future<void> _addExisting() async {
    await Navigator.of(context).push(
      XpRoute(builder: (_) => BillListPickerPage(listId: widget.listId)),
    );
  }

  Future<void> _addNew() async {
    await BookkeepingPage.push(context, listId: widget.listId);
  }

  Future<void> _deleteList() async {
    final ok = await confirmXpDialog(
      context,
      title: '删除清单？',
      content: '只删除这个清单和它的归类关系，清单里的账单本身不受影响。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok || !mounted) return;
    await _repo.delete(widget.listId);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openSections() async {
    await Navigator.of(context).push(
      XpRoute(builder: (_) => BillListSectionsPage(listId: widget.listId)),
    );
  }

  /// 把整份清单交给 AI 分析（逐笔，含清单内分类）。
  Future<void> _openAi() async {
    if (!ref.read(aiConfigProvider).isConfigured) {
      showXpSnack(context, '请先在「我的 → AI 设置」里配置接口', error: true);
      return;
    }
    final repo = ref.read(billListRepoProvider);
    final items = await repo.watchItems(widget.listId).first;
    if (!mounted) return;
    if (items.isEmpty) {
      showXpSnack(context, '清单还没有明细');
      return;
    }
    // 首次使用告知一次：点了就代表整份清单会发给 AI。
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (!(prefs.getBool('ai_list_privacy_acked') ?? false)) {
      final ok = await confirmXpDialog(
        context,
        title: '把这份清单发给 AI？',
        content:
            '将发送清单内每一笔消费：时间、金额、记账分类、清单内分类、账户、备注。'
            '数据只发给你自己配置的服务商。',
        confirmLabel: '我已知晓',
      );
      if (!ok || !mounted) return;
      await prefs.setBool('ai_list_privacy_acked', true);
    }
    final sections = await repo.sectionsOf(widget.listId);
    if (!mounted) return;
    await Navigator.of(context).push(
      XpRoute(
        builder: (_) => AiListChatPage(
          listName: widget.title,
          items: items,
          sections: sections,
        ),
      ),
    );
  }

  Future<void> _autoClassify() async {
    final ok = await confirmXpDialog(
      context,
      title: '自动分类',
      content:
          '按账单备注和记账分类做关键词匹配，只处理「未分类」的明细，'
          '不会覆盖你已经手动设置过的分类。\n\n'
          '识别不准的可以再逐笔调整。',
      confirmLabel: '开始',
    );
    if (!ok || !mounted) return;
    final (done, left) = await _repo.autoClassify(widget.listId);
    if (!mounted) return;
    showXpSnack(
      context,
      left > 0 ? '已自动分类 $done 笔，还有 $left 笔未识别' : '已自动分类 $done 笔',
    );
  }

  Future<void> _showBillActions(BillListItemView item) async {
    final action = await showXpSheet<String>(
      context: context,
      wrapContent: true,
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const AppIcon(icon: Icons.label_outline),
            title: const Text('修改分类'),
            onTap: () => Navigator.of(sheetCtx).pop('section'),
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.edit_outlined),
            title: const Text('编辑原账单'),
            subtitle: const Text('修改会同步到普通明细与统计'),
            onTap: () => Navigator.of(sheetCtx).pop('edit'),
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.playlist_remove),
            title: const Text('从清单移除'),
            onTap: () => Navigator.of(sheetCtx).pop('remove'),
          ),
          const SizedBox(height: XpSpacing.s),
        ],
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'section') {
      await _pickSection(item);
    } else if (action == 'edit') {
      await BookkeepingPage.push(context, bill: item.bill);
    } else if (action == 'remove') {
      await _remove(item.bill);
    }
  }

  Future<void> _pickSection(BillListItemView item) async {
    final sections = await _repo.sectionsOf(widget.listId);
    if (!mounted) return;
    final picked = await showXpSheet<String>(
      context: context,
      wrapContent: true,
      builder: (sheetCtx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.m,
              XpSpacing.l,
              XpSpacing.s,
            ),
            child: Text(
              '这笔归到哪个分类？',
              style: Theme.of(
                sheetCtx,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          for (final section in sections)
            ListTile(
              title: Text(section.name),
              trailing: item.sectionId == section.id
                  ? Icon(
                      Icons.check,
                      color: Theme.of(sheetCtx).colorScheme.primary,
                    )
                  : null,
              onTap: () => Navigator.of(sheetCtx).pop(section.id),
            ),
          ListTile(
            title: const Text('未分类'),
            trailing: item.sectionId == null
                ? Icon(
                    Icons.check,
                    color: Theme.of(sheetCtx).colorScheme.primary,
                  )
                : null,
            onTap: () => Navigator.of(sheetCtx).pop('__none__'),
          ),
          ListTile(
            leading: const AppIcon(icon: Icons.add),
            title: const Text('新建分类…'),
            onTap: () => Navigator.of(sheetCtx).pop('__new__'),
          ),
          const SizedBox(height: XpSpacing.s),
        ],
      ),
    );
    if (picked == null || !mounted) return;

    if (picked == '__none__') {
      await _repo.setSection(widget.listId, item.bill.id, null);
      return;
    }
    if (picked == '__new__') {
      final name = await _askSectionName();
      if (name == null || !mounted) return;
      final id = await _repo.createSection(widget.listId, name);
      await _repo.setSection(widget.listId, item.bill.id, id);
      return;
    }
    await _repo.setSection(widget.listId, item.bill.id, picked);
  }

  Future<String?> _askSectionName() async {
    final ctrl = TextEditingController();
    final name = await showXpDialog<String>(
      context: context,
      title: '新建分类',
      contentWidget: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 12,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v),
        decoration: const InputDecoration(
          labelText: '分类名称',
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
          child: const Text('创建'),
        ),
      ],
    );
    ctrl.dispose();
    final trimmed = name?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  Future<void> _remove(Bill bill) async {
    final ok = await confirmXpDialog(
      context,
      title: '从清单移除？',
      content: '只把这笔从清单里移出，账单本身和总账统计都不受影响。',
      confirmLabel: '移除',
      danger: true,
    );
    if (!ok) return;
    await _repo.removeBill(widget.listId, bill.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return buildXpScaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'AI 分析这份清单',
            icon: const AppIcon(icon: Icons.smart_toy_outlined, size: 22),
            onPressed: _openAi,
          ),
          PopupMenuButton<String>(
            tooltip: '更多',
            onSelected: (v) {
              if (v == 'sections') {
                _openSections();
              } else if (v == 'auto') {
                _autoClassify();
              } else if (v == 'delete') {
                _deleteList();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'sections', child: Text('分类设置')),
              PopupMenuItem(value: 'auto', child: Text('自动分类')),
              PopupMenuItem(value: 'delete', child: Text('删除清单')),
            ],
          ),
          const SizedBox(width: XpSpacing.xs),
        ],
      ),
      body: StreamBuilder<List<BillListSection>>(
        stream: _sections,
        builder: (context, secSnap) {
          final sections = secSnap.data ?? const <BillListSection>[];
          return StreamBuilder<List<BillListItemView>>(
            stream: _items,
            builder: (context, itemSnap) {
              final items = itemSnap.data ?? const <BillListItemView>[];
              final groups = _groupOf(sections, items);
              final total = _totalOf(items);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        XpSpacing.l,
                        XpSpacing.s,
                        XpSpacing.l,
                        XpSpacing.m,
                      ),
                      children: [
                        _SummaryCard(total: total, items: items),
                        const SizedBox(height: XpSpacing.m),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: XpSpacing.xl),
                            child: XpEmptyState(
                              icon: Icons.playlist_add,
                              title: '清单还是空的',
                              message: '可以挑已有的账单加进来，\n也可以直接在这个清单里记一笔。',
                            ),
                          )
                        else
                          for (final group in groups) ...[
                            _SectionHeader(
                              title: group.section?.name ?? '未分类',
                              count: group.items.length,
                              total: _totalOf(group.items),
                            ),
                            const SizedBox(height: XpSpacing.s),
                            // 同一分类下的明细合并进一张卡片，行间用分隔线，
                            // 与设置页的分组卡列表保持同一套设计。
                            XpCard(
                              padding: EdgeInsets.zero,
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (var i = 0; i < group.items.length; i++) ...[
                                    if (i > 0)
                                      Divider(
                                        height: 1,
                                        indent: 72,
                                        color: scheme.outlineVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    BillTile(
                                      bill: group.items[i].bill,
                                      onTap: () =>
                                          _showBillActions(group.items[i]),
                                      onLongPress: () =>
                                          _remove(group.items[i].bill),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: XpSpacing.m),
                          ],
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(
                        XpSpacing.l,
                        XpSpacing.s,
                        XpSpacing.l,
                        XpSpacing.m,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: XpButton(
                              onPressed: _addExisting,
                              expand: true,
                              child: const Text('添加已有明细'),
                            ),
                          ),
                          const SizedBox(width: XpSpacing.s),
                          Expanded(
                            child: XpButton(
                              onPressed: _addNew,
                              expand: true,
                              child: const Text('记一笔'),
                            ),
                          ),
                        ],
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

class _Group {
  const _Group({required this.section, required this.items});

  final BillListSection? section;
  final List<BillListItemView> items;
}

/// 按清单内分类分组：按分类 sort 顺序，未分类放最后。
List<_Group> _groupOf(
  List<BillListSection> sections,
  List<BillListItemView> items,
) {
  final bySection = <String?, List<BillListItemView>>{};
  for (final item in items) {
    bySection.putIfAbsent(item.sectionId, () => []).add(item);
  }
  final groups = <_Group>[];
  for (final section in sections) {
    final list = bySection[section.id];
    if (list != null && list.isNotEmpty) {
      groups.add(_Group(section: section, items: list));
    }
  }
  final uncategorized = bySection[null];
  if (uncategorized != null && uncategorized.isNotEmpty) {
    groups.add(_Group(section: null, items: uncategorized));
  }
  return groups;
}

int _totalOf(List<BillListItemView> items) {
  var total = 0;
  for (final item in items) {
    if (item.bill.type == 'transfer') continue;
    total += item.bill.amount;
  }
  return total;
}

/// 分类分组标题：名称 + 笔数 + 小计。
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.total,
  });

  final String title;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, XpSpacing.s, 4, 0),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          Text(
            '$count 笔',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            '¥${formatYuan(total)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.total, required this.items});

  final int total;
  final List<BillListItemView> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    var count = 0;
    int? minT;
    int? maxT;
    for (final item in items) {
      final bill = item.bill;
      if (bill.type == 'transfer') continue;
      count++;
      if (minT == null || bill.time < minT) minT = bill.time;
      if (maxT == null || bill.time > maxT) maxT = bill.time;
    }
    return XpCard(
      padding: const EdgeInsets.all(XpSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '合计',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                formatYuan(total),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.s),
          Text(
            _captionOf(count, minT, maxT),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _captionOf(int count, int? minT, int? maxT) {
  if (count == 0) return '还没有明细';
  final parts = <String>['$count 笔'];
  if (minT != null && maxT != null) {
    final a = DateTime.fromMillisecondsSinceEpoch(minT);
    final b = DateTime.fromMillisecondsSinceEpoch(maxT);
    parts.add(
      a.year == b.year && a.month == b.month
          ? '${a.month}/${a.day} - ${b.day}'
          : '${a.year}/${a.month}/${a.day} - ${b.year}/${b.month}/${b.day}',
    );
  }
  return parts.join(' · ');
}
