import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/icons.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/adjust_sheet.dart';
import '../widgets/historical_snapshot_sheet.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'account_form_sheet.dart';

/// 账户详情：余额概览 + 调账/编辑/删除 + 历史快照。
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
    final colorScheme = Theme.of(context).colorScheme;

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
        padding: const EdgeInsets.all(16),
        children: [
          // 余额概览卡
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: hexToColor(
                      current.color,
                    ).withValues(alpha: 0.15),
                    foregroundColor: hexToColor(current.color),
                    child: Icon(resolveIcon(current.icon), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '初始 ${formatYuan(current.initialBalance)}'
                          ' · ${_categoryLabel(current.category)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '¥ ${formatYuan(current.currentBalance)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => AdjustSheet.show(context, current),
                  icon: const Icon(Icons.tune),
                  label: const Text('调账'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      HistoricalSnapshotSheet.show(context, current),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('添加历史快照'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '历史快照（${accountSnaps.length}）',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          if (accountSnaps.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '暂无快照',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...accountSnaps.reversed.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _snapIcon(s.type),
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                title: Text(
                  '${s.note?.isEmpty == false ? '${s.note} · ' : ''}'
                  '${_snapLabel(s.type)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  _formatTime(s.timestamp),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                trailing: Text(
                  formatYuan(s.balance),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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

  static String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
