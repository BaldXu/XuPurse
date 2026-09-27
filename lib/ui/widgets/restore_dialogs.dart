import 'package:flutter/material.dart';

import '../../data/backup/encryption_service.dart';
import '../../data/backup/restore_service.dart';
import '../tokens/design_tokens.dart';
import 'app_icon.dart';
import 'xp_button.dart';

/// 加密备份密码输入弹窗：错误可无限重试，解密成功返回明文 JSON 并关闭。
///
/// 供「恢复备份」页与备份页「从定时备份恢复」共用。
class RestorePasswordDialog extends StatefulWidget {
  const RestorePasswordDialog({super.key, required this.envelopeJson});

  final String envelopeJson;

  @override
  State<RestorePasswordDialog> createState() => _RestorePasswordDialogState();
}

class _RestorePasswordDialogState extends State<RestorePasswordDialog> {
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
class RestoreOptionsDialog extends StatefulWidget {
  const RestoreOptionsDialog({super.key, required this.summary});

  final RestoreSummary summary;

  @override
  State<RestoreOptionsDialog> createState() => _RestoreOptionsDialogState();
}

class _RestoreOptionsDialogState extends State<RestoreOptionsDialog> {
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
