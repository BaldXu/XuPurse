import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/encryption_service.dart';
import '../../data/backup/restore_service.dart';
import '../../data/backup/saver.dart';
import '../../domain/ai/ai_config.dart';
import '../../domain/ai/ai_scope.dart';
import '../../domain/ai/ai_service.dart';
import '../../state/default_account_provider.dart';
import '../../state/icon_pack_provider.dart';
import '../../state/providers.dart';
import '../../state/theme_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_button.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_param_row.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';

/// 恢复备份页：选择备份文件 →（加密则输入密码，可无限重试）→
/// 选择恢复方式（覆盖 / 追加）+ 是否覆盖应用设置 → 执行 → 刷新数据源。
class RestorePage extends ConsumerStatefulWidget {
  const RestorePage({super.key});

  @override
  ConsumerState<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends ConsumerState<RestorePage>
    with XpPageScaffold<RestorePage> {
  String? _selectedFile;
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('恢复备份')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          Text(
            '从备份文件恢复数据。覆盖恢复会清空现有数据，请先确认已做好备份；'
            '追加恢复则把备份账本作为新账本导入，不动现有数据。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: XpSpacing.xl),
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: XpParamRow(
              leadingIcon: Icons.restore,
              label: '选择备份文件',
              subtitle: _selectedFile ?? '选择本应用导出的 .json 备份文件',
              onTap: _restoring ? null : _start,
            ),
          ),
          const SizedBox(height: XpSpacing.l),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.xs),
            child: Text(
              '目前仅支持恢复本应用「备份」页导出的 .json 备份文件'
              '（可加密）。第三方应用的备份文件不支持恢复。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  /// 恢复主流程：选文件 → 识别加密 → 校验格式 → 选择方式 → 执行。
  Future<void> _start() async {
    final picked = await pickBackupFile();
    if (picked == null || !mounted) return;
    setState(() => _selectedFile = picked.name);

    // 1. 识别并解出明文负载（加密备份弹密码框，可无限重试）
    final String payloadJson;
    try {
      final head = jsonDecode(picked.content);
      if (head is Map && head['enc'] == BackupEncryption.envelopeMagic) {
        final decrypted = await showDialog<String>(
          context: context,
          builder: (_) => _RestorePasswordDialog(envelopeJson: picked.content),
        );
        if (decrypted == null || !mounted) return; // 取消
        payloadJson = decrypted;
      } else {
        payloadJson = picked.content;
      }
    } on FormatException {
      _showNotCompatible(picked.name);
      return;
    } catch (_) {
      _showNotCompatible(picked.name);
      return;
    }

    // 2. 格式 / 版本校验（不适配直接提示）
    final RestoreSummary summary;
    try {
      summary = RestoreService.inspect(payloadJson);
    } on UnsupportedBackupException catch (e) {
      _showNotCompatible(picked.name, detail: e.message);
      return;
    } catch (_) {
      _showNotCompatible(picked.name);
      return;
    }
    if (!mounted) return;

    // 3. 选择恢复方式（覆盖 / 追加）+ 是否覆盖应用设置
    final options =
        await showDialog<({RestoreMode mode, bool overwriteSettings})>(
          context: context,
          builder: (_) => _RestoreOptionsDialog(summary: summary),
        );
    if (options == null || !mounted) return;

    // 4. 执行恢复
    setState(() => _restoring = true);
    _showRestoring();
    try {
      final mgr = ref.read(databaseManagerProvider);
      await RestoreService(mgr).restore(
        payloadJson,
        mode: options.mode,
        overwriteSettings: options.overwriteSettings,
      );
      if (!mounted) return;
      _closeRestoring();
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
      _closeRestoring();
      // 覆盖模式可能已删除部分账本：兜底当前账本并刷新数据源，避免应用
      // 停留在「无当前账本」状态（后续访问 dbProvider 会抛 StateError）。
      await _ensureCurrentBookAndRefresh(overwriteSettings: false);
      if (!mounted) return;
      showXpSnack(context, '恢复失败：$e', error: true);
    } finally {
      if (mounted) setState(() => _restoring = false);
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

  /// 不适配提示（文案：仅支持本应用固定格式备份）。
  void _showNotCompatible(String name, {String? detail}) {
    showXpDialog(
      context: context,
      title: '无法恢复此文件',
      content:
          '「$name」不是 XuPurse 的备份文件，或文件格式不受支持。\n\n'
          '目前仅支持恢复本应用「备份」页导出的 .json 备份文件'
          '${detail == null ? '' : '\n\n$detail'}',
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  /// 恢复执行中的阻断加载框。
  void _showRestoring() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              SizedBox(width: XpSpacing.l),
              Text('正在恢复…'),
            ],
          ),
        ),
      ),
    );
  }

  void _closeRestoring() {
    Navigator.of(context, rootNavigator: true).pop();
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
}

/// 加密备份密码输入弹窗：错误可无限重试，解密成功返回明文 JSON 并关闭。
class _RestorePasswordDialog extends StatefulWidget {
  const _RestorePasswordDialog({required this.envelopeJson});

  final String envelopeJson;

  @override
  State<_RestorePasswordDialog> createState() => _RestorePasswordDialogState();
}

class _RestorePasswordDialogState extends State<_RestorePasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _controller.text;
    if (password.isEmpty) {
      setState(() => _error = '请输入密码');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final decrypted = await BackupEncryption.decryptJson(
        widget.envelopeJson,
        password,
      );
      if (!mounted) return;
      Navigator.pop(context, decrypted);
    } on InvalidPasswordException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '密码错误，请重试';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '解密失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('输入备份密码'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '该备份文件已加密，需要密码才能恢复。密码错误可无限次重试。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: XpSpacing.m),
            TextField(
              controller: _controller,
              obscureText: true,
              autofocus: true,
              enabled: !_busy,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: '备份密码',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('解密'),
        ),
      ],
    );
  }
}

/// 恢复方式选择弹窗：覆盖 / 追加 +（备份含设置时）是否覆盖应用设置。
class _RestoreOptionsDialog extends StatefulWidget {
  const _RestoreOptionsDialog({required this.summary});

  final RestoreSummary summary;

  @override
  State<_RestoreOptionsDialog> createState() => _RestoreOptionsDialogState();
}

class _RestoreOptionsDialogState extends State<_RestoreOptionsDialog> {
  RestoreMode _mode = RestoreMode.overwrite;
  bool _overwriteSettings = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final summary = widget.summary;
    return AlertDialog(
      title: const Text('选择恢复方式'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '备份包含 ${summary.bookNames.length} 个账本'
              '${summary.bookNames.isEmpty ? '' : '：${summary.bookNames.join('、')}'}',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: XpSpacing.s),
            _ModeRow(
              selected: _mode == RestoreMode.overwrite,
              title: '覆盖恢复',
              subtitle: '删除现有全部数据，完整还原为备份时的状态',
              onTap: () => setState(() => _mode = RestoreMode.overwrite),
            ),
            _ModeRow(
              selected: _mode == RestoreMode.append,
              title: '追加恢复',
              subtitle: '保留现有数据，备份中的账本作为新账本导入',
              onTap: () => setState(() => _mode = RestoreMode.append),
            ),
            if (summary.hasSettings) ...[
              const SizedBox(height: XpSpacing.s),
              CheckboxListTile(
                value: _overwriteSettings,
                onChanged: (v) =>
                    setState(() => _overwriteSettings = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('覆盖应用设置'),
                subtitle: const Text('主题、磨砂、默认账户、汇率、AI 配置等'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        _mode == RestoreMode.overwrite
            ? XpButton(
                variant: XpButtonVariant.danger,
                onPressed: () => Navigator.pop(context, (
                  mode: _mode,
                  overwriteSettings: _overwriteSettings,
                )),
                child: const Text('开始恢复'),
              )
            : FilledButton(
                onPressed: () => Navigator.pop(context, (
                  mode: _mode,
                  overwriteSettings: _overwriteSettings,
                )),
                child: const Text('开始恢复'),
              ),
      ],
    );
  }
}

/// 单选用途行：radio 图标 + 标题 + 副标题。
class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.s,
          vertical: XpSpacing.s,
        ),
        child: Row(
          children: [
            AppIcon(
              icon: selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: XpSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
