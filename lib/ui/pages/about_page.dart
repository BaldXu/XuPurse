import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';

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
            // 固定展示 App 品牌图标（assets/icon/icon.png），不走 AppIcon，
            // 不随图标包（简约/Twitter 表情）切换而变化。
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icon/icon.png',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            Center(
              child: Text(
                'XuPurse',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: XpSpacing.xs),
            Center(
              child: Text(
                'v0.1.0',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: XpSpacing.xl),
            Text(
              '本地优先的记账应用：适配一木 / 昼虎 / 钱迹第三方数据库导入，'
              '支持多币种、多账本、资产趋势与统计。数据完全保存在本地。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
