import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_config.dart';
import '../../domain/ai/ai_service.dart';
import '../../domain/ai/stats_context.dart';
import '../../state/theme_provider.dart';
import '../tokens/design_tokens.dart';
import 'app_icon.dart';
import 'xp_empty_state.dart';
import 'xp_sheet.dart';

/// AI 悬浮按钮纵向位置（占页面可用高度的比例 0~1）；null = 使用默认 30%。
///
/// 由 MainShell 在每次切入统计页时重置为 null，按钮回到默认位置。
final aiFabTopProvider = StateProvider<double?>((ref) => null);

/// 统计页 AI 悬浮按钮：已配置 AI 时显示，点击弹出底部聊天窗口。
///
/// 默认位于屏幕右侧 30% 高度处；仅允许上下拖动（水平锁定右缘）；
/// 每次进入统计页重置回默认位置（见 [aiFabTopProvider]）。
class AiDraggableFab extends ConsumerStatefulWidget {
  const AiDraggableFab({super.key});

  @override
  ConsumerState<AiDraggableFab> createState() => _AiDraggableFabState();
}

class _AiDraggableFabState extends ConsumerState<AiDraggableFab> {
  /// 默认位于页面可用高度 70% 处。
  static const double _defaultFraction = 0.70;

  /// 右缘留白（与页面左右边距一致）。
  static const double _rightInset = XpSpacing.l;

  /// 拖动时上下最小留白。
  static const double _minMargin = 8;

  /// 按钮尺寸（FAB 标准 56）。
  static const double _fabSize = 56;

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(
      aiConfigProvider.select((s) => s.isConfigured),
    );
    if (!configured) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        // 窄屏磨砂导航开启时 body 延伸到底部导航之后，预留导航高度避免
        // 按钮被拖入/遮挡在导航栏区域；其余情况 body 已止于导航之上。
        final barsOn = ref.watch(frostedGlassProvider).barsOn;
        final reserve = barsOn && constraints.maxWidth < kSectionBreakpoint
            ? kBottomNavigationBarHeight
            : 0.0;
        final effectiveH = maxH - reserve;
        final minTop = _minMargin;
        final maxTop = effectiveH - _fabSize - _minMargin;
        if (effectiveH <= 0 || maxTop < minTop) {
          return const SizedBox.shrink();
        }

        final fraction = ref.watch(aiFabTopProvider);
        final defaultTop = effectiveH * _defaultFraction;
        final top = (fraction == null ? defaultTop : fraction * effectiveH)
            .clamp(minTop, maxTop)
            .toDouble();

        return Stack(
          children: [
            Positioned(
              right: _rightInset,
              top: top,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  final next = (top + d.delta.dy)
                      .clamp(minTop, maxTop)
                      .toDouble();
                  ref.read(aiFabTopProvider.notifier).state = next / effectiveH;
                },
                child: FloatingActionButton(
                  tooltip: 'AI 助手',
                  heroTag: 'ai_fab',
                  onPressed: () => showAiChatSheet(context),
                  child: const AppIcon(icon: Icons.smart_toy_outlined),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 弹出 AI 聊天窗口（底部上移动画）。
void showAiChatSheet(BuildContext context) {
  showXpSheet<void>(context: context, builder: (_) => const _AiChatSheet());
}

class _AiChatSheet extends ConsumerStatefulWidget {
  const _AiChatSheet();

  @override
  ConsumerState<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<_AiChatSheet> {
  String? _convId;
  bool _sending = false;
  bool _attachStats = true; // 附带本机统计摘要（聚合口径）
  bool _thinking = false; // 思考模式（默认关闭；仅支持的模型显示开关）
  String? _statsCache; // 每次打开聊天窗只生成一次

  /// 当前配置的模型是否疑似支持思考模式（启发式，按模型名判断）。
  bool get _modelSupportsThinking {
    final model = ref.watch(
      aiConfigProvider.select((s) => s.current?.model ?? ''),
    );
    return AiClient.modelSupportsThinking(model);
  }

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ensureConversation();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureConversation() async {
    final conversations = ref.read(aiChatProvider);
    if (conversations.isNotEmpty) {
      setState(() => _convId = conversations.first.id);
    } else {
      final conv = await ref.read(aiChatProvider.notifier).createConversation();
      if (mounted) setState(() => _convId = conv.id);
    }
  }

  AiConversation? _current(List<AiConversation> list) {
    if (_convId == null) return null;
    for (final c in list) {
      if (c.id == _convId) return c;
    }
    return null;
  }

  Future<void> _newConversation() async {
    final conv = await ref.read(aiChatProvider.notifier).createConversation();
    if (!mounted) return;
    setState(() => _convId = conv.id);
  }

  Future<void> _deleteConversation(String id) async {
    await ref.read(aiChatProvider.notifier).deleteConversation(id);
    if (!mounted) return;
    final list = ref.read(aiChatProvider);
    if (_convId == id) {
      setState(() => _convId = list.isEmpty ? null : list.first.id);
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final client = ref.read(aiClientProvider);
    final conv = _current(ref.read(aiChatProvider));
    if (client == null || conv == null) return;

    _inputCtrl.clear();
    setState(() => _sending = true);
    final chat = ref.read(aiChatProvider.notifier);

    // 占位：先记录用户消息，再追加空助手消息滚动到底
    await chat.appendMessage(conv.id, AiMessage(role: 'user', content: text));
    await chat.appendMessage(
      conv.id,
      const AiMessage(role: 'assistant', content: ''),
    );
    _scrollToBottom();

    try {
      // 只带当前会话历史（不含占位空消息）。
      // 发送期间会话可能被删除：重新读取一次，为空则放弃（避免 ! 空断言崩溃）。
      final convNow = _current(ref.read(aiChatProvider));
      if (convNow == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      final history = convNow.messages.sublist(0, convNow.messages.length - 1);

      // 附带本机统计摘要（仅首次发送时生成，后续复用）
      var systemPrompt = kDefaultSystemPrompt;
      if (_attachStats) {
        _statsCache ??= await AiStatsContext(ref).build();
        systemPrompt = '$kDefaultSystemPrompt\n\n$_statsCache';
      }

      final reply = await client.chat(
        systemPrompt: systemPrompt,
        history: history,
        userMessage: text,
        enableThinking: _thinking,
      );
      // 推理模型可能把 max_tokens 全部耗在思考上导致 content 为空
      if (reply.trim().isEmpty) {
        await chat.replaceLast(
          conv.id,
          AiMessage(
            role: 'assistant',
            content:
                '（未收到回复内容：模型可能把全部输出 tokens 用在思考上。'
                '请在 AI 设置中把「最大输出 tokens」调大，如 4096，或换用非推理模型。）',
            error: 'empty_reply',
          ),
        );
      } else {
        await chat.replaceLast(
          conv.id,
          AiMessage(role: 'assistant', content: reply),
        );
      }
    } catch (e) {
      await chat.replaceLast(
        conv.id,
        AiMessage(
          role: 'assistant',
          content: '请求失败：${e.toString().replaceFirst('Exception: ', '')}',
          error: e.toString(),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(aiChatProvider);
    final conv = _current(conversations);

    return Column(
      children: [
        // 顶部栏：标题 + 历史 + 新建
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.m,
            XpSpacing.s,
            XpSpacing.s,
          ),
          child: Row(
            children: [
              const AppIcon(icon: Icons.smart_toy_outlined, size: 20),
              const SizedBox(width: XpSpacing.s),
              Expanded(
                child: Text(
                  'AI 财务分析助手',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: '历史对话',
                icon: const AppIcon(icon: Icons.history, size: 22),
                onPressed: () => _showHistoryDrawer(conversations),
              ),
              // 思考模式开关（仅对疑似支持思考的模型显示；默认关闭）
              if (_modelSupportsThinking)
                IconButton(
                  tooltip: _thinking ? '思考模式：开（点击关闭）' : '思考模式：关（点击开启）',
                  icon: Icon(
                    _thinking ? Icons.psychology : Icons.psychology_outlined,
                    size: 22,
                    color: _thinking
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () => setState(() => _thinking = !_thinking),
                ),
              // 附带统计数据开关（聚合口径，保护隐私）
              IconButton(
                tooltip: _attachStats ? '附带统计数据：开（点击关闭）' : '附带统计数据：关（点击开启）',
                icon: Icon(
                  _attachStats
                      ? Icons.dataset_linked
                      : Icons.dataset_linked_outlined,
                  size: 22,
                  color: _attachStats
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _attachStats = !_attachStats;
                    if (!_attachStats) _statsCache = null;
                  });
                },
              ),
              IconButton(
                tooltip: '新建对话',
                icon: const AppIcon(icon: Icons.add_comment_outlined, size: 22),
                onPressed: _sending ? null : _newConversation,
              ),
              IconButton(
                tooltip: '收起',
                icon: const Icon(Icons.keyboard_arrow_down, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 消息区
        Expanded(
          child: conv == null || conv.messages.isEmpty
              ? _ChatEmptyHint(
                  onSuggestion: (s) {
                    _inputCtrl.text = s;
                  },
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(
                    XpSpacing.l,
                    XpSpacing.m,
                    XpSpacing.l,
                    XpSpacing.s,
                  ),
                  itemCount: conv.messages.length,
                  itemBuilder: (context, i) =>
                      _MessageBubble(message: conv.messages[i]),
                ),
        ),
        // 输入区
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.m,
              XpSpacing.s,
              XpSpacing.m,
              XpSpacing.m,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: '描述你的问题，或粘贴数据摘要…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: XpSpacing.s),
                IconButton.filled(
                  tooltip: '发送',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showHistoryDrawer(List<AiConversation> conversations) {
    showXpSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(XpSpacing.l),
              child: Row(
                children: [
                  Text('历史对话', style: Theme.of(sheetCtx).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      _newConversation();
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (conversations.isEmpty)
              const Expanded(
                child: XpEmptyState(icon: Icons.history, title: '暂无历史对话'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, i) {
                    final c = conversations[i];
                    return ListTile(
                      leading: AppIcon(
                        icon: c.id == _convId
                            ? Icons.chat_bubble
                            : Icons.chat_bubble_outline,
                        size: 20,
                      ),
                      title: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${c.messages.length} 条消息 · ${_fmtTime(c.updatedAt)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _deleteConversation(c.id);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        setState(() => _convId = c.id);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatEmptyHint extends StatelessWidget {
  const _ChatEmptyHint({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  static const _suggestions = ['帮我分析这个月的收支情况', '我想制定一个省钱计划', '如何减少不必要的支出？'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(XpSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon: Icons.smart_toy_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: XpSpacing.m),
            Text('把统计数据发给我，我来帮你分析', style: theme.textTheme.bodyMedium),
            const SizedBox(height: XpSpacing.xs),
            Text(
              '建议只粘贴汇总数据，避免发送敏感账户信息',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: XpSpacing.l),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text(s, style: theme.textTheme.labelMedium),
                    onPressed: () => onSuggestion(s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == 'user';
    final isError = message.error != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: ShapeDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : isError
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceContainerHighest,
          // G2 平滑圆角对齐卡片语言;收尾角收小形成气泡指向
          shape: XpShape.smooth(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isUser ? 14 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 14),
            ),
          ),
        ),
        child: SelectableText(
          message.content.isEmpty && !isUser ? '思考中…' : message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isError ? theme.colorScheme.onErrorContainer : null,
          ),
        ),
      ),
    );
  }
}
