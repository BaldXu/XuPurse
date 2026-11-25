import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/ai/ai_analysis_context.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_snack.dart';

/// 将发送给 AI 的 JSON 预览页：让用户亲眼看一遍发出去的东西。
class AiAnalysisPreviewPage extends StatefulWidget {
  const AiAnalysisPreviewPage({super.key, required this.data});

  final AiAnalysisData data;

  @override
  State<AiAnalysisPreviewPage> createState() => _AiAnalysisPreviewPageState();
}

class _AiAnalysisPreviewPageState extends State<AiAnalysisPreviewPage>
    with XpPageScaffold<AiAnalysisPreviewPage> {
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.data.json));
    if (mounted) showXpSnack(context, '已复制 JSON 到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final data = widget.data;
    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('发送内容预览'),
        actions: [
          IconButton(
            tooltip: '复制 JSON',
            icon: const AppIcon(icon: Icons.copy_all_outlined, size: 20),
            onPressed: _copy,
          ),
          const SizedBox(width: XpSpacing.xs),
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
            '下面就是随提问一起发给 AI 的完整内容，没有其他隐藏字段。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          XpCard(
            padding: const EdgeInsets.all(XpSpacing.l),
            child: Wrap(
              spacing: XpSpacing.l,
              runSpacing: XpSpacing.s,
              children: [
                _Meta('记录', '${data.count} 笔'),
                _Meta('体积', '${(data.bytes / 1024).toStringAsFixed(1)} KB'),
                _Meta('估算 token', '${(data.tokens / 1000).toStringAsFixed(1)}k'),
                _Meta('备注', data.includeNotes ? '已附带（脱敏）' : '未附带'),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          XpCard(
            padding: const EdgeInsets.all(XpSpacing.m),
            child: SelectableText(
              data.json,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
