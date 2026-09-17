import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/icons.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../widgets/adjust_sheet.dart';
import 'account_detail_page.dart';
import 'account_form_sheet.dart';

/// 资产页：总资产卡 + 三类账户分组列表。
class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final total = ref.watch(totalAssetsProvider).value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('资产'),
        actions: [
          IconButton(
            tooltip: '新建账户',
            icon: const Icon(Icons.add),
            onPressed: () => AccountFormSheet.show(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          // 总资产卡
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '总资产',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥ ${formatYuan(total)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          accountsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('加载失败：$e'),
            ),
            data: (accounts) {
              if (accounts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('还没有账户，点击右上角 + 创建')),
                );
              }
              final groups = <AccountCategory, List<Account>>{};
              for (final a in accounts) {
                groups
                    .putIfAbsent(
                      AccountCategory.values.byName(a.category),
                      () => [],
                    )
                    .add(a);
              }
              return Column(
                children: [
                  for (final cat in AccountCategory.values)
                    if (groups.containsKey(cat)) ...[
                      _GroupHeader(label: _categoryTitle(cat)),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final a in groups[cat]!)
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: hexToColor(
                                    a.color,
                                  ).withValues(alpha: 0.15),
                                  foregroundColor: hexToColor(a.color),
                                  child: Icon(resolveIcon(a.icon), size: 20),
                                ),
                                title: Text(a.name),
                                subtitle:
                                    (a.remark == null || a.remark!.isEmpty)
                                    ? null
                                    : Text(
                                        a.remark!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                trailing: Text(
                                  formatYuan(a.currentBalance),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AccountDetailPage(account: a),
                                  ),
                                ),
                                onLongPress: () => AdjustSheet.show(context, a),
                              ),
                          ],
                        ),
                      ),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _categoryTitle(AccountCategory cat) => switch (cat) {
    AccountCategory.fund => '资金账户',
    AccountCategory.record => '记录账户',
    AccountCategory.debt => '债务账户',
  };
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }
}
