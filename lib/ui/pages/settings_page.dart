import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import 'budget_manage_page.dart';
import 'category_manage_page.dart';
import 'currency_settings_page.dart';
import 'ledger_manage_page.dart';
import 'tag_manage_page.dart';
import '../tokens/design_tokens.dart';

/// 设置页：基础数据与偏好入口（分类/标签/预算/业务记录/汇率）。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with XpPageScaffold<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _entry(
                  context,
                  Icons.category_outlined,
                  '分类管理',
                  onTap: () => _push(context, const CategoryManagePage()),
                ),
                _entry(
                  context,
                  Icons.label_outline,
                  '标签管理',
                  onTap: () => _push(context, const TagManagePage()),
                ),
                _entry(
                  context,
                  Icons.savings_outlined,
                  '预算管理',
                  onTap: () => _push(context, const BudgetManagePage()),
                ),
                _entry(
                  context,
                  Icons.handshake_outlined,
                  '业务记录',
                  subtitle: '借贷 / 报销 / 退款 / 分期',
                  onTap: () => _push(context, const LedgerManagePage()),
                ),
                _entry(
                  context,
                  Icons.currency_exchange,
                  '汇率设置',
                  subtitle: '本位币与汇率覆盖',
                  onTap: () => _push(context, const CurrencySettingsPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: AppIcon(icon: icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(XpRoute(builder: (_) => page));
  }
}
