import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../state/default_account_provider.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_param_row.dart';
import '../widgets/xp_picker_sheet.dart';
import '../widgets/xp_snack.dart';
import '../tokens/design_tokens.dart';

/// 默认账户设置页：新增明细时自动带出的支出 / 收入账户。
///
/// 未设置（「自动」）或所选账户已不在当前账本时，记账弹窗自行兜底一个账户。
class DefaultAccountPage extends ConsumerStatefulWidget {
  const DefaultAccountPage({super.key});

  @override
  ConsumerState<DefaultAccountPage> createState() =>
      _DefaultAccountPageState();
}

class _DefaultAccountPageState extends ConsumerState<DefaultAccountPage>
    with XpPageScaffold<DefaultAccountPage> {
  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final prefs = ref.watch(defaultAccountProvider);
    final expense = _resolve(accounts, prefs.expenseAccountId);
    final income = _resolve(accounts, prefs.incomeAccountId);

    return buildXpScaffold(
      appBar: AppBar(title: const Text('默认账户')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(XpSpacing.l),
            child: Text(
              '新增明细时自动带出的账户。选择「自动」时由 App 在可用账户中挑一个。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            child: XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  XpParamRow(
                    leadingIcon: Icons.south_west,
                    label: '默认支出账户',
                    value: expense?.name ?? '自动',
                    onTap: () => _pick(expense: true),
                  ),
                  const XpParamDivider(
                    indent: kXpParamDividerIndentWithLeading,
                  ),
                  XpParamRow(
                    leadingIcon: Icons.north_east,
                    label: '默认收入账户',
                    value: income?.name ?? '自动',
                    onTap: () => _pick(expense: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick({required bool expense}) async {
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    if (accounts.isEmpty) {
      showXpSnack(context, '暂无可用账户');
      return;
    }
    final prefs = ref.read(defaultAccountProvider);
    final current = expense ? prefs.expenseAccountId : prefs.incomeAccountId;
    final choice = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      // 偏好里的账户已不在当前账本时视为「自动」。
      selectedId: _resolve(accounts, current)?.id,
      autoLabel: '自动',
      title: expense ? '默认支出账户' : '默认收入账户',
    );
    if (choice == null || !mounted) return;
    final notifier = ref.read(defaultAccountProvider.notifier);
    if (expense) {
      await notifier.setExpense(choice.value);
    } else {
      await notifier.setIncome(choice.value);
    }
  }

  /// 在可用账户中解析偏好 id；未设置或已失效返回 null。
  Account? _resolve(List<Account> accounts, String? id) {
    if (id == null) return null;
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }
}
