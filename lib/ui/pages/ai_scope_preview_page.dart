import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_scope.dart';
import '../../domain/ai/stats_context.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';

/// 统计摘要预览页：按传入的临时范围（设置页未保存的草稿）生成摘要文本，
/// 展示用户当前设置下实际会发给 AI 的内容，供用户知情确认。
class AiScopePreviewPage extends ConsumerStatefulWidget {
  const AiScopePreviewPage({super.key, required this.scope});

  /// 用于预览的临时范围（不依赖是否已保存）。
  final AiScope scope;

  @override
  ConsumerState<AiScopePreviewPage> createState() => _AiScopePreviewPageState();
}

class _AiScopePreviewPageState extends ConsumerState<AiScopePreviewPage>
    with XpPageScaffold<AiScopePreviewPage> {
  String? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await AiStatsContext(ref).build(override: widget.scope);
      if (mounted) {
        setState(() {
          _summary = s;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 总开关关闭时无需生成，直接提示纯聊天。
    final loading = widget.scope.enabled && _loading;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('统计摘要预览')),
      loading: loading,
      body: !widget.scope.enabled
          ? const XpEmptyState(
              icon: Icons.visibility_off_outlined,
              title: '数据授权已关闭',
              message: 'AI 无法读取任何本机数据，只会进行纯聊天。',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                XpSpacing.l,
                XpSpacing.s,
                XpSpacing.l,
                32,
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      icon: Icons.info_outline,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: XpSpacing.s),
                    Expanded(
                      child: Text(
                        '以下即按当前「数据范围设置」生成、随你的提问一起发给 '
                        'AI 的统计摘要（按临时规则生成，尚未保存，仅供预览知情）。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: XpSpacing.s),
                if (_error != null)
                  XpEmptyState(
                    icon: Icons.error_outline,
                    title: '生成失败',
                    message: _error,
                  )
                else if (_summary != null && _summary!.isNotEmpty)
                  XpCard(
                    padding: const EdgeInsets.all(XpSpacing.l),
                    child: SelectableText(
                      _summary!,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                    ),
                  )
                else
                  const XpEmptyState(
                    icon: Icons.inbox_outlined,
                    title: '暂无数据',
                    message: '当前范围内没有可生成的账单数据。',
                  ),
              ],
            ),
    );
  }
}
