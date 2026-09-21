import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/xp_snack.dart';

/// 业务记录页：借贷 / 报销 / 退款 / 分期 四 tab（只读列表 + 删除）。
///
/// 删除仅移除台账记录本身，不回滚关联账单与余额——确认弹窗中明示。
class LedgerManagePage extends ConsumerStatefulWidget {
  const LedgerManagePage({super.key});

  @override
  ConsumerState<LedgerManagePage> createState() => _LedgerManagePageState();
}

class _LedgerManagePageState extends ConsumerState<LedgerManagePage>
    with XpPageScaffold<LedgerManagePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: buildXpScaffold(
        appBar: AppBar(
          title: const Text('业务记录'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '借贷'),
              Tab(text: '报销'),
              Tab(text: '退款'),
              Tab(text: '分期'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LendList(),
            _ReimbursementList(),
            _RefundList(),
            _InstalmentList(),
          ],
        ),
      ),
    );
  }
}

String _accountName(WidgetRef ref, String id) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
  for (final a in accounts) {
    if (a.id == id) return a.name;
  }
  return '未知账户';
}

/// 统一删除确认：title 带类型，正文说明「仅删除记录，不动账单与余额」。
Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() doDelete, {
  required String title,
  String? detail,
}) async {
  final ok = await confirmXpDialog(
    context,
    title: '删除$title',
    content:
        '将删除这条台账记录。${detail ?? ''}\n\n'
        '注意：仅删除记录本身，关联账单与账户余额不受影响。',
    confirmLabel: '删除',
    danger: true,
  );
  if (ok && context.mounted) {
    await doDelete();
    if (context.mounted) {
      showXpSnack(context, '$title记录已删除');
    }
  }
}

class _LendList extends ConsumerWidget {
  const _LendList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lendsAsync = ref.watch(_lendsProvider);
    return lendsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 4),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (lends) {
        if (lends.isEmpty) {
          return const XpEmptyState(
            icon: Icons.currency_exchange,
            title: '暂无借贷记录',
          );
        }
        return ListView.builder(
          itemCount: lends.length,
          itemBuilder: (context, i) {
            final l = lends[i];
            final isLend = l.type == 'lend';
            final color = isLend
                ? XpSemanticColors.expense
                : XpSemanticColors.income;
            return ListTile(
              leading: AppIcon(
                icon: isLend ? Icons.north_east : Icons.south_west,
                color: color,
              ),
              title: Text(
                '${isLend ? '借出' : '收回'} ${formatYuan(l.amount)}',
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${_accountName(ref, l.accountId)}'
                '${l.interest != 0 ? ' · 利息 ${formatYuan(l.interest)}' : ''}'
                '${l.comment != null ? ' · ${l.comment}' : ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(
                  context,
                  ref,
                  () => ref.read(ledgerRepoProvider).deleteLend(l.id),
                  title: '借贷',
                  detail: '金额 ${formatYuan(l.amount)}。',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReimbursementList extends ConsumerWidget {
  const _ReimbursementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(_reimbursementsProvider);
    return itemsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 4),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) {
          return const XpEmptyState(
            icon: Icons.assignment_return,
            title: '暂无报销记录',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            return ListTile(
              leading: const AppIcon(icon: Icons.assignment_return),
              title: Text('报销 ${formatYuan(r.amount)}'),
              subtitle: Text(
                '${_accountName(ref, r.reimbursementAccountId ?? r.accountId ?? '')}'
                '${r.ended ? ' · 已结束' : ' · 进行中'}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(
                  context,
                  ref,
                  () => ref.read(ledgerRepoProvider).deleteReimbursement(r.id),
                  title: '报销',
                  detail: '金额 ${formatYuan(r.amount)}。',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RefundList extends ConsumerWidget {
  const _RefundList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(_refundsProvider);
    return itemsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 4),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) {
          return const XpEmptyState(icon: Icons.replay, title: '暂无退款记录');
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            return ListTile(
              leading: const Icon(Icons.replay),
              title: Text('退款 ${formatYuan(r.amount)}'),
              subtitle: Text(
                '关联账单 '
                '${r.billId.length > 8 ? r.billId.substring(0, 8) : r.billId}…',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(
                  context,
                  ref,
                  () => ref.read(ledgerRepoProvider).deleteRefund(r.id),
                  title: '退款',
                  detail: '金额 ${formatYuan(r.amount)}，关联账单保留。',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InstalmentList extends ConsumerWidget {
  const _InstalmentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(_instalmentsProvider);
    return itemsAsync.when(
      loading: () => const XpSkeletonList(itemCount: 4),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) {
          return const XpEmptyState(
            icon: Icons.calendar_month,
            title: '暂无分期记录',
          );
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            return ListTile(
              leading: const AppIcon(icon: Icons.calendar_month),
              title: Text(
                '分期 ${formatYuan(r.totalAmount)}'
                '${r.serviceFee != 0 ? ' + 服务费 ${formatYuan(r.serviceFee)}' : ''}',
              ),
              subtitle: Text(
                '${r.periods} 期 · ${_accountName(ref, r.accountId)}'
                '${r.accountMonth != null ? ' · ${r.accountMonth}' : ''}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _confirmDelete(
                  context,
                  ref,
                  () => ref.read(ledgerRepoProvider).deleteInstalment(r.id),
                  title: '分期',
                  detail: '总额 ${formatYuan(r.totalAmount)}，${r.periods} 期。',
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------- 台账 watch 流（autoDispose:离开台账页即释放 drift 监听） ----------

final _lendsProvider = StreamProvider.autoDispose<List<Lend>>(
  (ref) => ref.watch(ledgerRepoProvider).watchLends(),
);
final _reimbursementsProvider = StreamProvider.autoDispose<List<Reimbursement>>(
  (ref) => ref.watch(ledgerRepoProvider).watchReimbursements(),
);
final _refundsProvider = StreamProvider.autoDispose<List<Refund>>(
  (ref) => ref.watch(ledgerRepoProvider).watchRefunds(),
);
final _instalmentsProvider = StreamProvider.autoDispose<List<Instalment>>(
  (ref) => ref.watch(ledgerRepoProvider).watchInstalments(),
);
