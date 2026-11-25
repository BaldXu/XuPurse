import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/repositories/bill_list_repository.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'bill_list_detail_page.dart';

/// 消费清单列表：一次旅行 / 一次装修的消费集合。
class BillListsPage extends ConsumerStatefulWidget {
  const BillListsPage({super.key});

  @override
  ConsumerState<BillListsPage> createState() => _BillListsPageState();
}

class _BillListsPageState extends ConsumerState<BillListsPage>
    with XpPageScaffold<BillListsPage> {
  /// 汇总流只建一次，避免每次 build 重新订阅。
  late final Stream<List<BillListSummary>> _summaries =
      ref.read(billListRepoProvider).watchSummaries();

  Future<void> _create() async {
    final ctrl = TextEditingController();
    final name = await showXpDialog<String>(
      context: context,
      title: '新建消费清单',
      contentWidget: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v),
        decoration: const InputDecoration(
          labelText: '清单名称',
          hintText: '如：11月云南旅游',
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
    if (name == null || !mounted) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      showXpSnack(context, '清单名称不能为空', error: true);
      return;
    }
    final id = await ref
        .read(billListRepoProvider)
        .create(name: trimmed);
    if (!mounted) return;
    await Navigator.of(context).push(
      XpRoute(builder: (_) => BillListDetailPage(listId: id, title: trimmed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('消费清单')),
      floatingActionButton: XpFab(
        tooltip: '新建清单',
        onPressed: _create,
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BillListSummary>>(
        stream: _summaries,
        builder: (context, snap) {
          final items = snap.data ?? const <BillListSummary>[];
          if (snap.hasError) {
            return XpEmptyState(
              icon: Icons.error_outline,
              title: '读取失败',
              message: snap.error.toString(),
            );
          }
          if (items.isEmpty) {
            return const XpEmptyState(
              icon: Icons.receipt_long_outlined,
              title: '还没有消费清单',
              message: '把一次旅行、一次装修的消费归到一起，\n随时看这次事件一共花了多少。',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.s,
              XpSpacing.l,
              96,
            ),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: XpSpacing.s),
            itemBuilder: (context, i) => _ListCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.item});

  final BillListSummary item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      onTap: () => Navigator.of(context).push(
        XpRoute(
          builder: (_) => BillListDetailPage(
            listId: item.list.id,
            title: item.list.name,
          ),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(XpRadius.c),
          ),
          alignment: Alignment.center,
          child: AppIcon(
            icon: Icons.receipt_long_outlined,
            size: 20,
            color: scheme.primary,
          ),
        ),
        title: Text(
          item.list.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(_subtitleOf(item)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¥${formatYuan(item.total)}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: XpSpacing.xs),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

String _subtitleOf(BillListSummary item) {
  if (item.count == 0) return '暂无明细';
  final parts = <String>['${item.count} 笔'];
  final minT = item.minTime;
  final maxT = item.maxTime;
  if (minT != null && maxT != null) {
    final a = DateTime.fromMillisecondsSinceEpoch(minT);
    final b = DateTime.fromMillisecondsSinceEpoch(maxT);
    final sameMonth = a.year == b.year && a.month == b.month;
    final label = sameMonth
        ? '${a.month}/${a.day} - ${b.day}'
        : '${a.year}/${a.month}/${a.day} - ${b.year}/${b.month}/${b.day}';
    parts.add(label);
  }
  return parts.join(' · ');
}
