import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/backup/auto_backup_service.dart';
import '../../data/backup/backup_service.dart';
import '../../data/backup/encryption_service.dart';
import '../../data/backup/restore_service.dart';
import '../../data/backup/saver.dart';
import '../../domain/ai/ai_config.dart';
import '../../domain/ai/ai_scope.dart';
import '../../domain/ai/ai_service.dart';
import '../../state/auto_backup_provider.dart';
import '../../state/default_account_provider.dart';
import '../../state/icon_pack_provider.dart';
import '../../state/providers.dart';
import '../../state/theme_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/long_press_delete_button.dart';
import '../widgets/restore_dialogs.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_param_row.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_sliding_segmented.dart';
import '../widgets/xp_snack.dart';
import 'encryption_help_page.dart';

/// 备份页：左上角「手动备份 / 定时备份」二选一。
///
/// - 手动备份：选择备份内容 → 可选加密 → 右上角「备份」→ 系统保存窗口
///   （Android/iOS 走 SAF，无需存储权限，兼容 Android 11+ scoped storage）。
/// - 定时备份：选择备份内容 / 加密 / 固定保存位置 + 机制说明；
///   切到该模式即启用，切回手动则停用。
class BackupPage extends ConsumerStatefulWidget {
  const BackupPage({super.key});

  @override
  ConsumerState<BackupPage> createState() => _BackupPageState();
}

/// 备份方式二选一。
enum _BackupMode { manual, auto }

class _BackupPageState extends ConsumerState<BackupPage>
    with XpPageScaffold<BackupPage> {
  /// 数据库文件：始终包含，不可取消勾选。
  static const bool _includeDatabase = true;

  /// 应用设置（主题/磨砂/默认账户/汇率/AI 配置等）：可选，默认勾选。
  bool _includeSettings = true;

  /// 手动备份：本次是否加密。
  bool _encrypted = false;

  /// 备份执行中（按钮转加载态）。
  bool _backingUp = false;

  /// 定时备份执行中（立即备份按钮转加载态）。
  bool _autoBacking = false;

  /// 当前模式。初始跟随定时备份开关状态（重进页面回到上次的模式）。
  late _BackupMode _mode = ref.read(autoBackupProvider).enabled
      ? _BackupMode.auto
      : _BackupMode.manual;

  bool get _canBackup => !_backingUp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auto = ref.watch(autoBackupProvider);
    return buildXpScaffold(
      appBar: AppBar(
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: XpSlidingSegmented<_BackupMode>(
            items: const [
              XpSegmentedItem(
                value: _BackupMode.manual,
                label: '手动备份',
                icon: Icons.person_outline,
              ),
              XpSegmentedItem(
                value: _BackupMode.auto,
                label: '定时备份',
                icon: Icons.schedule,
              ),
            ],
            selected: _mode,
            onChanged: _onModeChanged,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: XpSpacing.l),
            child: Center(
              child: _mode == _BackupMode.manual
                  ? _backingUp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton(
                            onPressed: _canBackup ? _onBackupPressed : null,
                            child: const Text('备份'),
                          )
                  : _autoBacking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _onAutoSaveTask,
                      child: const Text('保存定时备份任务'),
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
        children: _mode == _BackupMode.manual
            ? _buildManualBody(scheme)
            : _buildAutoBody(scheme, auto),
      ),
    );
  }

  // ---------- 手动备份视图 ----------

  List<Widget> _buildManualBody(ColorScheme scheme) {
    return [
      Text(
        '备份文件包含所选内容，建议定期备份并妥善保存。'
        '恢复时从同一文件导入即可。',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      const SizedBox(height: XpSpacing.xl),
      const _SectionLabel('备份内容'),
      _buildContentCard(),
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
              ? '点击「备份」后由浏览器弹出保存窗口，选择位置保存'
              : '点击「备份」后由系统弹出保存窗口，选择位置保存',
          showChevron: false,
          onTap: null,
        ),
      ),
    ];
  }

  // ---------- 定时备份视图 ----------

  List<Widget> _buildAutoBody(ColorScheme scheme, AutoBackupState auto) {
    return [
      Text(
        '保存定时备份任务后生效：每次打开 App 会自动检查，距上次自动备份 '
        '超过 24 小时就自动备份一份。',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      if (auto.enabled) ...[
        const SizedBox(height: XpSpacing.xl),
        const _SectionLabel('当前定时任务'),
        XpCard(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.s,
              XpSpacing.l,
              XpSpacing.s,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: '下次自动备份',
                  value: auto.lastAt == null
                      ? '首次启动后自动检查'
                      : _fmtTime(
                          auto.lastAt! +
                              AutoBackupService.interval.inMilliseconds,
                        ),
                ),
                _InfoRow(
                  label: '上次自动备份',
                  value: auto.lastAt == null ? '尚未备份' : _fmtTime(auto.lastAt!),
                ),
                _InfoRow(
                  label: '加密',
                  value: auto.hasPassword ? '已加密（密码保存在本机）' : '明文（未加密）',
                ),
                _InfoRow(
                  label: '保存位置',
                  value: auto.dir ?? (kIsWeb ? '浏览器私有文件系统（OPFS）' : '应用文档目录'),
                ),
                _InfoRow(
                  label: '备份内容',
                  value: auto.includeSettings ? '数据库 + 应用设置' : '仅数据库',
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _onDeleteAutoTask,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: scheme.error,
                    ),
                    label: Text(
                      '删除定时任务',
                      style: TextStyle(color: scheme.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: XpSpacing.xl),
      const _SectionLabel('备份内容'),
      _buildContentCard(),
      const SizedBox(height: XpSpacing.xl),
      const _SectionLabel('加密'),
      XpCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: XpParamRow(
          leadingIcon: Icons.lock_outline,
          label: '加密备份',
          subtitle: auto.hasPassword
              ? '已加密：每次自动备份都用本机保存的密码加密'
              : '定时备份将用密码加密，密码保存在本机',
          showChevron: false,
          onTap: () => _onAutoEncryptToggle(!auto.hasPassword),
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
              Switch(
                value: auto.hasPassword,
                onChanged: (v) => _onAutoEncryptToggle(v),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: XpSpacing.xl),
      const _SectionLabel('保存位置'),
      XpCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            XpParamRow(
              leadingIcon: Icons.folder_outlined,
              label: '保存方式',
              subtitle: auto.dir != null
                  ? '已配置：${auto.dir}'
                  : kIsWeb
                  ? '默认：浏览器私有文件系统（OPFS）'
                  : '默认：应用文档目录（xupurse_auto_backup.json）',
              showChevron: false,
              onTap: _onChooseAutoBackupDir,
            ),
            const XpParamDivider(indent: XpSpacing.l),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                XpSpacing.l,
                XpSpacing.xs,
                XpSpacing.s,
                XpSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      auto.dir != null
                          ? '点按上方可修改目录，自动备份都会写入该目录'
                          : '点按上方选择保存目录（配置一次，自动备份都写这里）',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (auto.dir != null)
                    TextButton(
                      onPressed: _onResetAutoBackupDir,
                      child: const Text('恢复默认'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: XpSpacing.xl),
      const _SectionLabel('定时备份说明'),
      XpCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(XpSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: scheme.primary),
                  const SizedBox(width: XpSpacing.s),
                  Text(
                    '定时备份是怎么运作的？',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: XpSpacing.s),
              _Bullet(text: '每次打开 App 自动检查一次：距上次自动备份超过 24 小时就自动备份'),
              _Bullet(
                text: auto.dir != null
                    ? '文件自动保存到已配置的目录，只覆盖上一次定时备份文件'
                    : kIsWeb
                    ? '文件默认保存到浏览器私有文件系统，只覆盖上一次定时备份文件'
                    : '文件默认保存到应用文档目录，只覆盖上一次定时备份文件',
              ),
              _Bullet(text: '不影响你手动保存的备份文件'),
              _Bullet(text: '备份内容默认明文保存，可开启上方「加密备份」防止泄露'),
              const SizedBox(height: XpSpacing.s),
              Text(
                '上次自动备份：${auto.lastAt == null ? '尚未备份' : DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(auto.lastAt!))}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: XpSpacing.m),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _autoBacking ? null : _restoreFromAutoBackup,
                  icon: const Icon(Icons.settings_backup_restore),
                  label: const Text('从定时备份恢复'),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  /// 备份内容卡（手动 / 定时共用）。
  Widget _buildContentCard() {
    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          CheckboxListTile(
            value: _includeDatabase,
            // 数据库文件百分百被勾选且不允许取消勾选
            onChanged: null,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            title: const Text('数据库文件'),
            subtitle: const Text('全部账本的账单、账户、分类、预算等数据'),
          ),
          const XpParamDivider(indent: XpSpacing.l),
          CheckboxListTile(
            value: _includeSettings,
            onChanged: (v) => setState(() => _includeSettings = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            title: const Text('应用设置'),
            subtitle: const Text('主题、磨砂、默认账户、汇率、AI 配置等偏好'),
          ),
        ],
      ),
    );
  }

  // ---------- 模式切换 ----------

  /// 切换手动 / 定时视图。定时任务的创建 / 删除由
  /// 「保存定时备份任务」和「删除定时任务」按钮控制，切 tab 不影响任务。
  void _onModeChanged(_BackupMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
  }

  // ---------- 定时备份动作 ----------

  /// 选择 / 修改定时备份保存目录（配置一次，之后自动备份都写该目录）。
  Future<void> _onChooseAutoBackupDir() async {
    final action = await showXpDialog<String>(
      context: context,
      title: '定时备份保存位置',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '定时备份是自动运行的，无法每次弹窗选择位置。'
            '这里配置一次保存目录，之后每次自动备份都会写入该目录。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(height: XpSpacing.s),
            Text(
              '提示：Android 受系统限制暂不支持自定义目录，请使用默认位置。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'choose'),
          child: const Text('选择目录'),
        ),
      ],
    );
    if (action != 'choose' || !mounted) return;
    try {
      final mgr = ref.read(databaseManagerProvider);
      final picked = await AutoBackupService(mgr).configureDir();
      if (picked == null || !mounted) return; // 用户取消
      await ref.read(autoBackupProvider.notifier).setDir(picked);
      if (mounted) showXpSnack(context, '定时备份将保存到：$picked');
    } on UnsupportedError catch (e) {
      if (!mounted) return;
      showXpSnack(context, e.message ?? '当前平台不支持选择目录', error: true);
    } catch (e) {
      if (!mounted) return;
      showXpSnack(context, '选择目录失败：$e', error: true);
    }
  }

  /// 恢复默认保存位置（清除已配置目录）。
  Future<void> _onResetAutoBackupDir() async {
    final mgr = ref.read(databaseManagerProvider);
    await AutoBackupService(mgr).clearDir();
    await ref.read(autoBackupProvider.notifier).setDir(null);
    if (mounted) showXpSnack(context, '已恢复默认保存位置');
  }

  /// 定时备份加密开关：开启先设密码（≥4 位，密码存本机）；关闭需确认。
  Future<void> _onAutoEncryptToggle(bool value) async {
    if (value) {
      final password = await _askPassword();
      if (password == null || !mounted) return;
      await ref.read(autoBackupProvider.notifier).setPassword(password);
      if (mounted) showXpSnack(context, '已开启定时备份加密，密码保存在本机');
      return;
    }
    final ok = await confirmXpDialog(
      context,
      title: '关闭加密定时备份？',
      content:
          '关闭后，后续定时备份将不再加密，改为明文保存。'
          '已加密的历史定时备份文件不受影响，仍可用原密码恢复。',
      confirmLabel: '关闭加密',
    );
    if (ok && mounted) {
      await ref.read(autoBackupProvider.notifier).setPassword('');
      if (mounted) showXpSnack(context, '已关闭定时备份加密');
    }
  }

  /// 保存定时备份任务（右上角按钮）：无任务 → 创建（首次解释）；
  /// 已有任务 → 提示覆盖，确认后覆盖（任务保持唯一）。
  Future<void> _onAutoSaveTask() async {
    final auto = ref.read(autoBackupProvider);
    if (auto.enabled) {
      final ok = await confirmXpDialog(
        context,
        title: '覆盖定时备份任务？',
        content:
            '已有一个正在执行的定时备份任务，保存新设置将覆盖它'
            '（定时备份任务始终只有一个）。\n\n'
            '任务生效后，每次打开 App 会自动检查：距上次自动备份超过 '
            '24 小时就自动备份一份。',
        confirmLabel: '覆盖保存',
      );
      if (!ok || !mounted) return;
    } else {
      final ok = await confirmXpDialog(
        context,
        title: '保存定时备份任务？',
        content:
            '保存后定时备份任务即生效：每次打开 App 会自动检查，'
            '距上次自动备份超过 24 小时就自动备份一份。\n\n'
            '文件自动保存到固定位置（可配置），只覆盖上一次定时备份文件，'
            '不影响手动备份。${auto.hasPassword ? '' : '\n\n当前未加密，建议开启「加密备份」防止文件泄露。'}',
        confirmLabel: '保存任务',
      );
      if (!ok || !mounted) return;
    }
    await ref
        .read(autoBackupProvider.notifier)
        .saveTask(includeSettings: _includeSettings);
    if (!mounted) return;
    showXpSnack(context, auto.enabled ? '定时备份任务已覆盖保存' : '定时备份任务已创建');
  }

  /// 删除定时备份任务：确认弹窗内长按 3 秒才真正删除。
  Future<void> _onDeleteAutoTask() async {
    final confirmed = await showXpDialog<bool>(
      context: context,
      title: '删除定时备份任务？',
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '删除后定时备份将停止，不再自动备份。'
            '已产生的定时备份文件仍保留，可随时恢复。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          LongPressDeleteButton(
            seconds: 3,
            onConfirmed: () => Navigator.pop(context, true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    await ref.read(autoBackupProvider.notifier).setEnabled(false);
    if (!mounted) return;
    showXpSnack(context, '已删除定时备份任务');
  }

  String _fmtTime(int ms) => DateFormat(
    'yyyy-MM-dd HH:mm',
  ).format(DateTime.fromMillisecondsSinceEpoch(ms));

  /// 从定时备份恢复：读固定文件 →（加密则输密码，可无限重试）→
  /// 选覆盖/追加 → 执行 → 刷新数据源。
  Future<void> _restoreFromAutoBackup() async {
    final mgr = ref.read(databaseManagerProvider);
    final content = await AutoBackupService(mgr).readLast();
    if (content == null) {
      if (!mounted) return;
      showXpSnack(context, '还没有定时备份文件');
      return;
    }
    if (!mounted) return;

    // 1. 识别加密并解出明文负载（复用恢复页密码弹窗）。
    final String payloadJson;
    try {
      final head = jsonDecode(content);
      if (head is Map && head['enc'] == BackupEncryption.envelopeMagic) {
        final decrypted = await showDialog<String>(
          context: context,
          builder: (_) => RestorePasswordDialog(envelopeJson: content),
        );
        if (decrypted == null || !mounted) return; // 取消
        payloadJson = decrypted;
      } else {
        payloadJson = content;
      }
    } catch (_) {
      if (!mounted) return;
      showXpSnack(context, '定时备份文件无法解析', error: true);
      return;
    }

    // 2. 格式 / 版本校验。
    final RestoreSummary summary;
    try {
      summary = RestoreService.inspect(payloadJson);
    } catch (e) {
      if (!mounted) return;
      showXpSnack(context, '定时备份文件不适配：$e', error: true);
      return;
    }
    if (!mounted) return;

    // 3. 选择恢复方式（覆盖 / 追加）+ 是否覆盖应用设置。
    final options =
        await showDialog<({RestoreMode mode, bool overwriteSettings})>(
          context: context,
          builder: (_) => RestoreOptionsDialog(summary: summary),
        );
    if (options == null || !mounted) return;

    // 4. 执行恢复。
    setState(() => _autoBacking = true);
    try {
      await RestoreService(mgr).restore(
        payloadJson,
        mode: options.mode,
        overwriteSettings: options.overwriteSettings,
      );
      await _ensureCurrentBookAndRefresh(
        overwriteSettings: options.overwriteSettings,
      );
      if (!mounted) return;
      showXpSnack(
        context,
        options.mode == RestoreMode.overwrite
            ? '已覆盖恢复 ${summary.bookNames.length} 个账本'
            : '已追加导入 ${summary.bookNames.length} 个账本',
      );
    } catch (e) {
      if (!mounted) return;
      // 覆盖模式可能已删除部分账本：兜底当前账本并刷新，避免停留在
      // 「无当前账本」状态（后续访问 dbProvider 会抛 StateError）。
      await _ensureCurrentBookAndRefresh(overwriteSettings: false);
      if (!mounted) return;
      showXpSnack(context, '恢复失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _autoBacking = false);
    }
  }

  /// 确保存在当前账本（覆盖恢复后可能为 null），并刷新数据/设置数据源。
  Future<void> _ensureCurrentBookAndRefresh({
    required bool overwriteSettings,
  }) async {
    final mgr = ref.read(databaseManagerProvider);
    if (mgr.currentBookId == null) {
      final rest = await mgr.listBooks();
      if (rest.isNotEmpty) {
        await mgr.openBook(rest.first.id);
      } else {
        await mgr.createBook(name: '默认账本');
      }
    }
    _refreshAfterRestore(overwriteSettings: overwriteSettings);
  }

  /// 恢复后刷新数据源；覆盖了应用设置时连偏好 provider 一并重建。
  void _refreshAfterRestore({required bool overwriteSettings}) {
    ref.invalidate(dbProvider);
    ref.invalidate(currentBookProvider);
    ref.invalidate(baseCurrencyProvider);
    ref.invalidate(minBillTimeProvider);
    ref.invalidate(minDataTimeProvider);
    ref.read(homeMonthsProvider.notifier).state = 1;
    ref.read(homeTypeFilterProvider.notifier).state = HomeTypeFilter.all;
    ref.read(homeCustomRangeProvider.notifier).state = null;
    if (overwriteSettings) {
      ref.invalidate(themeProvider);
      ref.invalidate(frostedGlassProvider);
      ref.invalidate(transitionBlurProvider);
      ref.invalidate(iconPackProvider);
      // 主题级字段为 null 时兜底回全局值，恢复设置后全局兜底也须重建。
      ref.invalidate(legacyFrostedGlassProvider);
      ref.invalidate(legacyTransitionBlurProvider);
      ref.invalidate(legacyIconPackProvider);
      ref.invalidate(defaultAccountProvider);
      ref.invalidate(aiConfigProvider);
      ref.invalidate(aiScopeProvider);
      ref.invalidate(aiChatProvider);
      ref.invalidate(currencyServiceProvider);
    }
  }

  // ---------- 手动备份动作 ----------

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
                '确认后浏览器会弹出保存窗口，由你选择保存位置。'
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
      final json = await BackupService(
        mgr,
      ).exportAll(password: password, includeSettings: _includeSettings);
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
              hintText: '至少 4 位',
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

/// 任务信息行：标签 + 值（当前定时任务卡用）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}

/// 说明列表项：小圆点 + 文字。
class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: XpSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
