import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';

/// 业务记录页：借贷 / 报销 / 退款 / 分期 四 tab（只读列表 + 删除）。
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
        body: const TabBarView(
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

String _accountName(WidgetRef ref, String? id) {
  if (id == null) return '—';
  final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
  for (final a in accounts) {
    if (a.id == id) return a.name;
  }
  return '未知账户';
}

class _LendList extends ConsumerWidget {
  const _LendList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lendsAsync = ref.watch(_lendsProvider);
    return lendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (lends) {
        if (lends.isEmpty) return const Center(child: Text('暂无借贷记录'));
        return ListView.builder(
          itemCount: lends.length,
          itemBuilder: (context, i) {
            final l = lends[i];
            final isLend = l.type == 'lend';
            final color = isLend
                ? XpSemanticColors.expense
                : XpSemanticColors.income;
            return ListTile(
              leading: Icon(
                isLend ? Icons.north_east : Icons.south_west,
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
                onPressed: () => _delete(ref, _db(ref).lends, l.id),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('暂无报销记录'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            return ListTile(
              leading: const Icon(Icons.assignment_return, color: Colors.blue),
              title: Text('报销 ${formatYuan(r.amount)}'),
              subtitle: Text(
                '${_accountName(ref, r.reimbursementAccountId ?? r.accountId)}'
                '${r.ended ? ' · 已结束' : ' · 进行中'}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _delete(ref, _db(ref).reimbursements, r.id),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('暂无退款记录'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            return ListTile(
              leading: const Icon(Icons.replay, color: Colors.orange),
              title: Text('退款 ${formatYuan(r.amount)}'),
              subtitle: Text('关联账单 ${r.billId.substring(0, 8)}…'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _delete(ref, _db(ref).refunds, r.id),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (items) {
        if (items.isEmpty) return const Center(child: Text('暂无分期记录'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final r = items[i];
            return ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.purple),
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
                onPressed: () => _delete(ref, _db(ref).instalments, r.id),
              ),
            );
          },
        );
      },
    );
  }
}

AppDatabase _db(WidgetRef ref) => ref.read(dbProvider);

/// 删除指定表的记录（全部业务表都有 id 主键，用 dynamic 统一处理）。
Future<void> _delete(WidgetRef ref, dynamic table, String id) async {
  final db = ref.read(dbProvider);
  await (db.delete(table)..where((t) => (t as dynamic).id.equals(id))).go();
}

final _lendsProvider = StreamProvider<List<Lend>>(
  (ref) =>
      (ref.watch(dbProvider).select(ref.watch(dbProvider).lends)
            ..orderBy([(t) => OrderingTerm.desc(t.time)]))
          .watch(),
);
final _reimbursementsProvider = StreamProvider<List<Reimbursement>>(
  (ref) =>
      (ref.watch(dbProvider).select(ref.watch(dbProvider).reimbursements)
            ..orderBy([(t) => OrderingTerm.desc(t.time)]))
          .watch(),
);
final _refundsProvider = StreamProvider<List<Refund>>(
  (ref) =>
      (ref.watch(dbProvider).select(ref.watch(dbProvider).refunds)
            ..orderBy([(t) => OrderingTerm.desc(t.time)]))
          .watch(),
);
final _instalmentsProvider = StreamProvider<List<Instalment>>(
  (ref) =>
      (ref.watch(dbProvider).select(ref.watch(dbProvider).instalments)
            ..orderBy([(t) => OrderingTerm.desc(t.time)]))
          .watch(),
);
