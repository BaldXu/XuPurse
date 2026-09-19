import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import 'about_page.dart';
import 'ai_settings_page.dart';
import 'book_manage_page.dart';
import 'data_manage_page.dart';
import 'settings_page.dart';
import 'theme_settings_page.dart';

/// 我的页：设置 / 账本管理 / 数据管理 / 主题外观 / 应用信息。
class MinePage extends ConsumerStatefulWidget {
  const MinePage({super.key});

  @override
  ConsumerState<MinePage> createState() => _MinePageState();
}

class _MinePageState extends ConsumerState<MinePage>
    with XpPageScaffold<MinePage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('我的')),
      // 宽屏限宽居中，窄屏铺满（手机版式不变）
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SizedBox(height: 8),
          _GroupCard(
            children: [
              _Entry(
                icon: Icons.settings_outlined,
                title: '设置',
                subtitle: '分类、标签、预算、业务记录、汇率',
                onTap: () => _push(context, const SettingsPage()),
              ),
              _Entry(
                icon: Icons.account_balance_outlined,
                title: '账本管理',
                subtitle: '新建、切换、删除账本',
                onTap: () => _push(context, const BookManagePage()),
              ),
              _Entry(
                icon: Icons.folder_open_outlined,
                title: '数据管理',
                subtitle: '第三方数据导入、备份导出',
                onTap: () => _push(context, const DataManagePage()),
              ),
              _Entry(
                icon: Icons.smart_toy_outlined,
                title: 'AI 设置',
                subtitle: '接入 AI 助手分析财务数据',
                onTap: () => _push(context, const AiSettingsPage()),
              ),
              _Entry(
                icon: Icons.palette_outlined,
                title: '主题外观',
                subtitle: '主题颜色切换',
                onTap: () => _push(context, const ThemeSettingsPage()),
              ),
              _Entry(
                icon: Icons.info_outline,
                title: '应用信息',
                subtitle: '版本与关于',
                onTap: () => _push(context, const AboutPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

/// 分组卡片容器。
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// 入口行。
class _Entry extends StatelessWidget {
  const _Entry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
