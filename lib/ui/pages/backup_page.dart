import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_service.dart';
import '../../data/backup/encryption_service.dart';
import '../../data/backup/saver.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_param_row.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'encryption_help_page.dart';

/// 备份页：选择备份内容（数据库必选 + 应用设置可选）→ 可选加密 →
/// 右上角「备份」→ 系统「保存文件」窗口选择位置（Android/iOS 走 SAF，
/// 无需存储权限，兼容 Android 11+ scoped storage）。
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends ConsumerState<BackupPage>
    with XpPageScaffold<BackupPage> {
  /// 数据库文件：始终包含，不可取消勾选。
  static const bool _includeDatabase = true;

  /// 应用设置（主题/磨砂/默认账户/汇率/AI 配置等）：可选，默认勾选。
  bool _includeSettings = true;

  /// 是否加密备份。
  bool _encrypted = false;

  /// 备份执行中（按钮转加载态）。
  bool _backingUp = false;

  bool get _canBackup => !_backingUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('备份'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: XpSpacing.l),
            child: Center(
              child: _backingUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _canBackup ? _onBackupPressed : null,
                      child: const Text('备份'),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          Text(
            '备份文件包含所选内容，建议定期备份并妥善保存。'
            '恢复时从同一文件导入即可。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: XpSpacing.xl),
          const _SectionLabel('备份内容'),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                CheckboxListTile(
                  value: _includeDatabase,
                  // 数据库文件百分百被勾选且不允许取消勾选
                  onChanged: null,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: XpSpacing.l,
                  ),
                  title: const Text('数据库文件'),
                  subtitle: const Text('全部账本的账单、账户、分类、预算等数据'),
                ),
                const XpParamDivider(indent: XpSpacing.l),
                CheckboxListTile(
                  value: _includeSettings,
                  onChanged: (v) =>
                      setState(() => _includeSettings = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: XpSpacing.l,
                  ),
                  title: const Text('应用设置'),
                  subtitle: const Text('主题、磨砂、默认账户、汇率、AI 配置等偏好'),
                ),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          const _SectionLabel('加密'),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: XpParamRow(
              leadingIcon: Icons.lock_outline,
              label: '加密备份',
              subtitle: _encrypted ? '已开启：备份将使用密码加密' : '为备份设置密码，防止文件泄露',
              showChevron: false,
              onTap: () => _onEncryptToggle(!_encrypted),
              valueWidget: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                    tooltip: '加密介绍',
                    onPressed: _openEncryptionHelp,
                  ),
                  Switch(value: _encrypted, onChanged: _onEncryptToggle),
                ],
              ),
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          const _SectionLabel('保存位置'),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: XpParamRow(
              leadingIcon: Icons.folder_outlined,
              label: '保存方式',
              subtitle: kIsWeb
                  ? '点击「备份」后备份内容复制到剪贴板，请自行粘贴保存'
                  : '点击「备份」后由系统弹出保存窗口，选择位置保存',
              showChevron: false,
              onTap: null,
            ),
          ),
        ],
      ),
    );
  }

  void _openEncryptionHelp() {
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => const EncryptionHelpPage()));
  }

  /// 加密开关：开启时先弹窗告知速度与丢密码风险，确认后才真正开启。
  Future<void> _onEncryptToggle(bool value) async {
    if (!value) {
      setState(() => _encrypted = false);
      return;
    }
    final ok = await confirmXpDialog(
      context,
      title: '开启加密备份？',
      content:
          '加密后备份和恢复会比平时慢一些；'
          '密码不会保存在任何地方，忘记密码将无法找回备份数据。',
      confirmLabel: '开启加密',
    );
    if (ok && mounted) setState(() => _encrypted = true);
  }

  /// 右上角「备份」：先确认，再（若加密）输入密码两次，然后执行。
  Future<void> _onBackupPressed() async {
    final scope = _includeDatabase
        ? '数据库文件${_includeSettings ? '、应用设置' : ''}'
        : '应用设置';
    final ok = await confirmXpDialog(
      context,
      title: '开始备份？',
      content: kIsWeb
          ? '将备份「$scope」${_encrypted ? '（已加密）' : ''}。'
                '确认后将复制到剪贴板，请自行粘贴保存。'
          : '将备份「$scope」${_encrypted ? '（已加密）' : ''}。'
                '确认后系统会弹出保存窗口，由你选择保存位置。',
      confirmLabel: '开始备份',
    );
    if (!ok || !mounted) return;

    String? password;
    if (_encrypted) {
      password = await _askPassword();
      if (password == null || !mounted) return;
    }

    setState(() => _backingUp = true);
    try {
      final mgr = ref.read(databaseManagerProvider);
      final json = await BackupService(mgr).exportAll(password: password);
      final name =
          'xupurse_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final saved = await saveBackupTo(name, json);
      if (!mounted) return;
      if (saved == null) return; // IO 平台：用户在系统保存窗口点了取消
      showXpSnack(context, '备份完成：$saved');
    } catch (e) {
      if (!mounted) return;
      showXpSnack(context, '备份失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  /// 加密密码输入弹窗：输入两次以确认，返回确认后的密码；取消返回 null。
  Future<String?> _askPassword() {
    final password = TextEditingController();
    final confirm = TextEditingController();
    final error = ValueNotifier<String?>(null);

    void submit() {
      final err =
          BackupEncryption.validatePassword(password.text) ??
          (password.text != confirm.text ? '两次输入的密码不一致' : null);
      if (err != null) {
        error.value = err;
        return;
      }
      Navigator.pop(context, password.text);
    }

    final result = showXpDialog<String>(
      context: context,
      title: '设置备份密码',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '加密备份需要设置密码，恢复时用同一密码解密。'
            '密码无法找回，请务必牢记。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          TextField(
            controller: password,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '密码',
              hintText: '至少 8 位',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          ValueListenableBuilder<String?>(
            valueListenable: error,
            builder: (_, e, __) => TextField(
              controller: confirm,
              obscureText: true,
              onSubmitted: (_) => submit(),
              decoration: InputDecoration(
                labelText: '确认密码',
                errorText: e,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: submit, child: const Text('开始备份')),
      ],
    );
    return result.whenComplete(() {
      password.dispose();
      confirm.dispose();
      error.dispose();
    });
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
