import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_config.dart';
import '../../domain/ai/ai_service.dart';
import '../layout/breakpoints.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/xp_snack.dart';

/// AI 设置页：多配置管理（新增/编辑/删除/启用停用/切换当前）+ 连通性测试。
class AiSettingsPage extends ConsumerWidget {
  const AiSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiConfigProvider);
    final notifier = ref.read(aiConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('AI 设置')),
      body: XpEntrance(
        child: ContentWidthBox(
          child: aiState.configs.isEmpty
              ? _EmptyConfigHint(onAdd: () => _edit(context, ref, null))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Text(
                      '已保存 ${aiState.configs.length} 份配置，点击卡片切换当前使用',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final config in aiState.configs)
                      _ConfigCard(
                        config: config,
                        isCurrent: aiState.current?.id == config.id,
                        onTap: () => notifier.select(config.id),
                        onEdit: () => _edit(context, ref, config),
                        onDelete: () => _confirmDelete(context, ref, config),
                        onToggleEnabled: (v) =>
                            notifier.setEnabled(config.id, v),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _edit(context, ref, null),
                      icon: const Icon(Icons.add),
                      label: const Text('新增配置'),
                    ),
                    const SizedBox(height: 16),
                    Text('隐私说明', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      'API Key 仅保存在本机（浏览器本地存储），不会上传到除所配置 '
                      'AI 服务商以外的任何服务器；对话内容仅发送给你所配置的 '
                      'API 端点；系统提示词内置隐私规矩，限制 AI 索取敏感信息。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: aiState.configs.isEmpty
          ? null
          : FloatingActionButton(
              tooltip: '新增配置',
              onPressed: () => _edit(context, ref, null),
              child: const Icon(Icons.add),
            ),
    );
  }

  static Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    AiConfig? existing,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _AiConfigEditPage(existing: existing)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AiConfig config,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除配置'),
        content: Text('确定删除「${config.name}」？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref.read(aiConfigProvider.notifier).remove(config.id);
    }
  }
}

class _EmptyConfigHint extends StatelessWidget {
  const _EmptyConfigHint({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 56,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          const Text('尚未配置 AI'),
          const SizedBox(height: 4),
          Text(
            '支持 OpenAI 兼容 / Anthropic 兼容协议\n可保存多份配置随时切换',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('新增配置'),
          ),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({
    required this.config,
    required this.isCurrent,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleEnabled,
  });

  final AiConfig config;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: config.enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              // 当前配置指示（Radio 已弃用手动 groupValue，用图标替代）
              Icon(
                isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 20,
                color: isCurrent
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            config.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: config.enabled
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            config.protocol.label,
                            style: theme.textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${config.model} · ${config.baseUrl}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Key：${config.maskedKey}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: config.enabled, onChanged: onToggleEnabled),
              IconButton(
                tooltip: '编辑',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 配置编辑页（新增/编辑共用）。
class _AiConfigEditPage extends ConsumerStatefulWidget {
  const _AiConfigEditPage({this.existing});

  final AiConfig? existing;

  @override
  ConsumerState<_AiConfigEditPage> createState() => _AiConfigEditPageState();
}

class _AiConfigEditPageState extends ConsumerState<_AiConfigEditPage>
    with XpPageScaffold {
  late AiProtocol _protocol;
  late TextEditingController _name;
  late TextEditingController _baseUrl;
  late TextEditingController _apiKey;
  late TextEditingController _model;
  late TextEditingController _temperature;
  late TextEditingController _maxTokens;
  bool _testing = false;
  String? _testResult; // null=未测；'ok' 或错误信息
  bool _obscureKey = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _protocol = e?.protocol ?? AiProtocol.openai;
    _name = TextEditingController(text: e?.name ?? '');
    _baseUrl = TextEditingController(text: e?.baseUrl ?? '');
    _apiKey = TextEditingController(text: e?.apiKey ?? '');
    _model = TextEditingController(text: e?.model ?? '');
    _temperature = TextEditingController(
      text: (e?.temperature ?? 0.7).toString(),
    );
    _maxTokens = TextEditingController(text: (e?.maxTokens ?? 2048).toString());
    if (!_isEditing) {
      _baseUrl.text = _protocol.defaultBaseUrl;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    _temperature.dispose();
    _maxTokens.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: Text(_isEditing ? '编辑配置' : '新增配置')),
      body: ContentWidthBox(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<AiProtocol>(
              segments: AiProtocol.values
                  .map((p) => ButtonSegment(value: p, label: Text(p.label)))
                  .toList(),
              selected: {_protocol},
              onSelectionChanged: (s) {
                setState(() {
                  _protocol = s.first;
                  // 未手改过 baseUrl 时跟随协议默认
                  if (!_isEditing ||
                      _baseUrl.text == AiProtocol.openai.defaultBaseUrl ||
                      _baseUrl.text == AiProtocol.anthropic.defaultBaseUrl) {
                    _baseUrl.text = _protocol.defaultBaseUrl;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '配置名称 *',
                hintText: '如：DeepSeek / 火山方舟 / Claude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _baseUrl,
              decoration: InputDecoration(
                labelText: 'Base URL *',
                hintText: _protocol.defaultBaseUrl,
                helperText: _protocol == AiProtocol.openai
                    ? 'OpenAI 兼容地址，如 https://api.deepseek.com/v1'
                    : 'Anthropic 兼容地址，如 https://api.anthropic.com/v1',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _apiKey,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                labelText: 'API Key *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKey
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _model,
              decoration: InputDecoration(
                labelText: '模型名称（model） *',
                hintText: _protocol == AiProtocol.openai
                    ? '如 deepseek-chat / gpt-4o-mini / doubao-pro-32k'
                    : '如 claude-sonnet-4-5 / claude-haiku-4-5',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _temperature,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '温度 temperature',
                      hintText: '0.0 ~ 2.0，默认 0.7',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxTokens,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '最大输出 tokens',
                      hintText: '默认 2048',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_testResult != null && _testResult != 'ok')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '测试失败：$_testResult',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (_testResult == 'ok')
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '✓ 连接成功',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: XpSemanticColors.income,
                  ),
                ),
              ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check),
                  label: const Text('测试连接'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _save,
                  child: Text(_isEditing ? '保存修改' : '保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AiConfig _collect() {
    final temp = double.tryParse(_temperature.text.trim()) ?? 0.7;
    final maxTok = int.tryParse(_maxTokens.text.trim()) ?? 2048;
    return AiConfig(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      protocol: _protocol,
      baseUrl: _baseUrl.text.trim().isEmpty
          ? _protocol.defaultBaseUrl
          : _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
      model: _model.text.trim(),
      temperature: temp.clamp(0.0, 2.0),
      maxTokens: maxTok < 1 ? 2048 : maxTok,
    );
  }

  Future<void> _test() async {
    final config = _collect();
    if (config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      setState(() => _testResult = '请先填写 Base URL、API Key 和模型名称');
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      await AiClient(config).testConnection();
      if (mounted) setState(() => _testResult = 'ok');
    } catch (e) {
      if (mounted) {
        setState(
          () => _testResult = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final config = _collect();
    if (config.name.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty ||
        config.baseUrl.isEmpty) {
      showXpSnack(context, '请完整填写名称、Base URL、API Key 和模型名称');
      return;
    }
    await ref.read(aiConfigProvider.notifier).upsert(config);
    if (mounted) Navigator.of(context).pop();
  }
}
