import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/long_press_delete_button.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'backup_page.dart';
import 'import_page.dart';
import 'restore_page.dart';

/// 数据管理页：第三方数据导入 + 备份 + 清空所有数据（开发用）。
class DataManagePage extends ConsumerStatefulWidget {
  const DataManagePage({super.key});

  @override
  ConsumerState<DataManagePage> createState() => _DataManagePageState();
}

class _DataManagePageState extends ConsumerState<DataManagePage>
    with XpPageScaffold<DataManagePage> {
  /// 清空当前账本全部业务数据并重新写入种子（分类/账户）。
  ///
  /// 直接删表而非重建库：drift 的 watch 流会自动刷新，页面即时回到
  /// 全新状态，无需重启。导入映射一并清除，重导时重新幂等映射。
  Future<void> _clearAllData() async {
    final db = ref.read(dbProvider);
    // 用 SQL 清空全部业务表（避免 drift 泛型繁琐；表名来自 schema，无注入风险）
    await db.customStatement('DELETE FROM bills');
    await db.customStatement('DELETE FROM bill_tags');
    await db.customStatement('DELETE FROM tags');
    await db.customStatement('DELETE FROM tag_groups');
    await db.customStatement('DELETE FROM transfers');
    await db.customStatement('DELETE FROM lends');
    await db.customStatement('DELETE FROM refunds');
    await db.customStatement('DELETE FROM reimbursements');
    await db.customStatement('DELETE FROM instalments');
    await db.customStatement('DELETE FROM budgets');
    await db.customStatement('DELETE FROM balance_snapshots');
    await db.customStatement('DELETE FROM categories');
    await db.customStatement('DELETE FROM accounts');
    await db.customStatement('DELETE FROM import_mappings');
    // 重置为默认分类/账户种子
    await ref.read(databaseManagerProvider).seedBook(db);
    // 失效时间下界缓存：清空后最早账单时间变化，首页日期选择器/趋势页
    // 自定义范围下界需重新计算（FutureProvider 只 watch repo 身份不 watch 数据）。
    ref.invalidate(minBillTimeProvider);
    ref.invalidate(minDataTimeProvider);
  }

  void _showClearConfirm() {
    showXpDialog<void>(
      context: context,
      title: '清空所有数据',
      contentWidget: const Text(
        '将删除当前账本的全部账单、账户、分类、预算、导入记录等数据，'
        '并重置为默认分类与默认账户。\n\n此操作不可恢复，'
        '如需保留请先「备份」。\n\n'
        '确认需长按按钮 3 秒（松开即取消）。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        LongPressDeleteButton(
          seconds: 3,
          onConfirmed: () async {
            Navigator.pop(context);
            await _clearAllData();
            if (!mounted) return;
            showXpSnack(context, '已清空全部数据，并重置为默认分类/账户');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('数据管理')),
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
                ListTile(
                  leading: const _TintedIcon(Icons.file_download_outlined),
                  title: const Text('数据导入'),
                  subtitle: const Text('导入一木 / 昼虎 / 钱迹备份 .db 文件'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    XpRoute(builder: (_) => const ImportPage()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const _TintedIcon(Icons.backup_outlined),
                  title: const Text('备份'),
                  subtitle: const Text('全量备份数据库与设置，可加密'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    XpRoute(builder: (_) => const BackupPage()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const _TintedIcon(Icons.restore),
                  title: const Text('恢复备份'),
                  subtitle: const Text('从备份文件恢复数据，可解密加密备份'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    XpRoute(builder: (_) => const RestorePage()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          // 危险操作提示条（errorContainer 语义色），非常规卡片表面，保留裸 Card。
          Card(
            clipBehavior: Clip.antiAlias,
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.4),
            child: ListTile(
              leading: Icon(
                Icons.delete_forever_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '清空所有数据',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              subtitle: const Text('删除当前账本全部数据并重置（开发阶段使用，不可恢复）'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: _showClearConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

/// primary 色块图标（数据管理分组行用）。
class _TintedIcon extends StatelessWidget {
  const _TintedIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 36,
      height: 36,
      decoration: ShapeDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        shape: XpShape.smooth(borderRadius: BorderRadius.circular(XpRadius.s)),
      ),
      child: AppIcon(icon: icon, size: 20, color: colorScheme.primary),
    );
  }
}
