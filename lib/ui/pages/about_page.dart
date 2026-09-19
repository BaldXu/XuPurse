import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';

/// 应用信息页：名称、版本、简介。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with XpPageScaffold<AboutPage> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('应用信息')),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(32),
          children: [
            Icon(Icons.account_balance_wallet, size: 64, color: scheme.primary),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'XuPurse',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'v0.1.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '本地优先的记账应用：适配一木 / 昼虎 / 钱迹第三方数据库导入，'
              '支持多币种、多账本、资产趋势与统计。数据完全保存在本地。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
