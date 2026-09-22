import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import 'about_page.dart';
import 'ai_settings_page.dart';
import 'book_manage_page.dart';
import 'data_manage_page.dart';
import 'settings_page.dart';
import 'theme_settings_page.dart';

/// 我的页：用户卡（当前账本 + 本位币 + 总资产）→ 分组设置列表。
///
/// 分组用 XpCard + 图标色块（primary 低透明度底 + primary 前景），
/// 行间 Divider 从文字处缩进（对齐系统设置样式）。
class MinePage extends ConsumerStatefulWidget {
  const MinePage({super.key});

  @override
  ConsumerState<MinePage> createState() => _MinePageState();
}

class _MinePageState extends ConsumerState<MinePage>
    with XpPageScaffold<MinePage> {
  @override
  Widget build(BuildContext context) {
    final total = ref.watch(totalAssetsProvider).value ?? 0;
    final baseCurrency = ref.watch(baseCurrencyProvider).value ?? 'CNY';
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return buildXpScaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
        padding: EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.xs,
          XpSpacing.l,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // ── 用户卡：账本身份 + 总资产概览 ──
          _UserCard(bookName: 'XuPurse', currency: baseCurrency, total: total),
          const SizedBox(height: XpSpacing.m),

          // ── 分组：通用 ──
          _SectionLabel('通用'),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Entry(
                  icon: Icons.account_balance_outlined,
                  title: '账本管理',
                  subtitle: '新建、切换、删除账本',
                  onTap: () => _push(context, const BookManagePage()),
                ),
                _EntryDivider(),
                _Entry(
                  icon: Icons.folder_open_outlined,
                  title: '数据管理',
                  subtitle: '第三方数据导入、备份导出',
                  onTap: () => _push(context, const DataManagePage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.l),

          // ── 分组：偏好 ──
          _SectionLabel('偏好'),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Entry(
                  icon: Icons.palette_outlined,
                  title: '主题外观',
                  subtitle: '克莱因蓝主题与自定义外观',
                  onTap: () => _push(context, const ThemeSettingsPage()),
                ),
                _EntryDivider(),
                _Entry(
                  icon: Icons.settings_outlined,
                  title: '设置',
                  subtitle: '分类、标签、预算、业务记录、汇率',
                  onTap: () => _push(context, const SettingsPage()),
                ),
                _EntryDivider(),
                _Entry(
                  icon: Icons.smart_toy_outlined,
                  title: 'AI 设置',
                  subtitle: '接入 AI 助手分析财务数据',
                  onTap: () => _push(context, const AiSettingsPage()),
                ),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.l),

          // ── 分组：关于 ──
          _SectionLabel('关于'),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: _Entry(
              icon: Icons.info_outline,
              title: '应用信息',
              subtitle: '版本与关于',
              onTap: () => _push(context, const AboutPage()),
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          // 版本脚注
          Center(
            child: Text(
              'XuPurse · 一本干净的账',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(XpRoute(builder: (_) => page));
  }
}

/// 用户卡：左侧账本名 + 本位币徽标，右侧总资产（tabular 大金额）。
class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.bookName,
    required this.currency,
    required this.total,
  });

  final String bookName;
  final String currency;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return XpCard(
      padding: const EdgeInsets.all(XpSpacing.xl),
      child: Row(
        children: [
          // 头像位：首字母色块
          CircleAvatar(
            radius: 24,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: colorScheme.primary,
            child: Text(
              bookName.characters.first.toUpperCase(),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: XpSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookName, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '本位币 $currency',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '总资产',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '¥${formatYuan(total)}',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)
                    .tabular,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 分组小标题。
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.xs,
        0,
        XpSpacing.xs,
        XpSpacing.s,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 行间分隔线（从图标文字处缩进）。
class _EntryDivider extends StatelessWidget {
  const _EntryDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 60,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

/// 设置入口行:图标色块 + 标题/副标题 + chevron。
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: XpSpacing.m + 2,
        ),
        child: Row(
          children: [
            // 图标色块:primary 低透明度圆角方块
            Container(
              width: 36,
              height: 36,
              decoration: ShapeDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: XpShape.smooth(
                  borderRadius: BorderRadius.circular(XpRadius.s),
                ),
              ),
              child: AppIcon(icon: icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: XpSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
