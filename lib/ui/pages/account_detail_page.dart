import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/adjust_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart';
import '../widgets/historical_snapshot_sheet.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/xp_snack.dart';
import 'account_form_sheet.dart';
import 'bookkeeping_sheet.dart';

/// 账户详情：顶部账户 Hero（余额大金额 tabular）→ 调账/快照入口 →
/// 流水（watchPage 按账户过滤，drift watch 响应式）→ 历史快照。
class AccountDetailPage extends ConsumerStatefulWidget {
  const AccountDetailPage({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends ConsumerState<AccountDetailPage>
    with XpPageScaffold<AccountDetailPage> {
  @override
  Widget build(BuildContext context) {
    // 响应式取最新账户状态（调账后自动刷新）
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final current =
        accounts.where((a) => a.id == widget.account.id).firstOrNull ??
        widget.account;
    final snapshots = ref.watch(snapshotsProvider).value ?? const [];
    final accountSnaps = snapshots
        .where((s) => s.accountId == current.id)
        .toList();
    // 该账户流水（时间倒序；含转账双账户侧；watch 响应式）
    final billsAsync = ref.watch(accountBillsProvider(current.id));
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final color = hexToColor(current.color);

    return buildXpScaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: [
          IconButton(
            tooltip: '编辑',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => AccountFormSheet.show(context, account: current),
          ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.xs,
          XpSpacing.l,
          32,
        ),
        children: [
          // ── 账户 Hero 卡 ──
          XpCard(
            padding: const EdgeInsets.all(XpSpacing.xl),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withValues(alpha: 0.15),
                  foregroundColor: color,
                  child: AppIcon(name: current.icon, size: 26),
                ),
                const SizedBox(width: XpSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.name, style: textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '初始 ${formatYuan(current.initialBalance)}'
                        ' · ${_categoryLabel(current.category)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '¥${formatYuan(current.currentBalance)}',
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700)
                      .tabular,
                ),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          // ── 操作入口 ──
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => AdjustSheet.show(context, current),
                  icon: const Icon(Icons.tune),
                  label: const Text('调账'),
                ),
              ),
              const SizedBox(width: XpSpacing.s),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      HistoricalSnapshotSheet.show(context, current),
                  icon: const AppIcon(icon: Icons.history, size: 18),
                  label: const Text('添加历史快照'),
                ),
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.l),
          // ── 流水 ──
          Text(
            '流水',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: XpSpacing.xs),
          billsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: XpSpacing.s),
              child: XpSkeletonList(itemCount: 3),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: XpSpacing.l),
              child: XpErrorState(
                title: '流水加载失败',
                message: '$e',
                actionLabel: '重试',
                onAction: () =>
                    ref.invalidate(accountBillsProvider(current.id)),
              ),
            ),
            data: (bills) {
              if (bills.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: XpSpacing.l),
                  child: XpEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: '该账户还没有流水',
                    message: '记一笔并选择此账户后，这里会展示账单明细',
                  ),
                );
              }
              return XpCard(
                padding: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < bills.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 60,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      BillTile(
                        bill: bills[i],
                        onTap: () => _editBill(bills[i]),
                        onLongPress: () => _deleteBill(bills[i]),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: XpSpacing.l),
          // ── 历史快照 ──
          Text(
            '历史快照（${accountSnaps.length}）',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: XpSpacing.xs),
          if (accountSnaps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: XpSpacing.m),
              child: XpEmptyState(
                icon: Icons.bookmark_outline,
                title: '暂无快照',
                message: '记账或调账后，这里会记录余额变动轨迹',
              ),
            )
          else
            XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < accountSnaps.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 52,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    _SnapTile(snap: accountSnaps[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _editBill(Bill bill) => BookkeepingSheet.show(context, bill: bill);

  Future<void> _deleteBill(Bill bill) async {
    final ok = await confirmXpDialog(
      context,
      title: '删除账单',
      content: '删除后余额与快照将同步回滚，确定删除？',
      confirmLabel: '删除',
      danger: true,
    );
    if (ok && mounted) {
      await ref.read(billServiceProvider).deleteBill(bill.id);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await confirmXpDialog(
      context,
      title: '删除账户',
      content: '确定删除「${widget.account.name}」？有账单关联的账户将被拒绝删除。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok) return;
    try {
      await ref.read(accountServiceProvider).deleteAccount(widget.account.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        showXpSnack(
          context,
          '$e'.replaceFirst('ValidationException: ', ''),
          error: true,
        );
      }
    }
  }

  static String _categoryLabel(String category) => switch (category) {
    'fund' => '资金',
    'record' => '记录',
    'debt' => '债务',
    _ => category,
  };
}

/// 快照行：类型图标 + 备注/类型 + 时间 + 余额。
class _SnapTile extends StatelessWidget {
  const _SnapTile({required this.snap});

  final BalanceSnapshot snap;

  static String _snapLabel(int type) => switch (type) {
    SnapshotType.expense => '支出',
    SnapshotType.income => '收入',
    SnapshotType.transferOut => '转出',
    SnapshotType.transferIn => '转入',
    SnapshotType.manual => '手动调账',
    SnapshotType.historical => '历史快照',
    _ => '快照',
  };

  static IconData _snapIcon(int type) => switch (type) {
    SnapshotType.expense => Icons.south_west,
    SnapshotType.income => Icons.north_east,
    SnapshotType.transferOut => Icons.call_made,
    SnapshotType.transferIn => Icons.call_received,
    SnapshotType.manual => Icons.tune,
    SnapshotType.historical => Icons.history,
    _ => Icons.bookmark_outline,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final dt = DateTime.fromMillisecondsSinceEpoch(snap.timestamp);
    return ListTile(
      dense: true,
      leading: AppIcon(
        icon: _snapIcon(snap.type),
        size: 20,
        color: colorScheme.onSurfaceVariant,
      ),
      title: Text(
        '${snap.note?.isEmpty == false ? '${snap.note} · ' : ''}'
        '${_snapLabel(snap.type)}',
        style: textTheme.bodyMedium,
      ),
      subtitle: Text(
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
        style: textTheme.labelSmall,
      ),
      trailing: Text(
        formatYuan(snap.balance),
        style: textTheme.bodyMedium
            ?.copyWith(fontWeight: FontWeight.w600)
            .tabular,
      ),
    );
  }
}
