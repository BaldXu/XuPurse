import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';

/// 应用信息页：名称、版本、简介。
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> with XpPageScaffold<AboutPage> {
  /// 应用版本号（读 pubspec 的 version）；获取失败时回退「--」。
  String _version = '--';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('应用信息')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          // ListView 的 cross-axis 是 tight 约束，会把图标宽度强制拉满
          // （高度正常、宽度占满导致变扁）；Column 不强制子项宽度。
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 固定展示 App 品牌图标（assets/icon/icon.png），不走 AppIcon，
              // 不随图标包（简约/Twitter 表情）切换而变化。
              // 显式 width/height + BoxFit.contain：1:1 源图在 1:1 框中
              // 完整显示，不被裁剪放大；SizedBox 再锁一层防外层拉伸。
              Center(
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                  ),
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
                  'v$_version',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: XpSpacing.xl),
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
      ),
    );
  }
}
