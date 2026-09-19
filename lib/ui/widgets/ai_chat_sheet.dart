import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_config.dart';
import '../../domain/ai/ai_service.dart';

/// 统计页 AI 悬浮按钮：已配置 AI 时显示，点击弹出底部聊天窗口。
class AiFab extends ConsumerWidget {
  const AiFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(
      aiConfigProvider.select((s) => s.isConfigured),
    );
    if (!configured) return const SizedBox.shrink();
    return FloatingActionButton(
      tooltip: 'AI 助手',
      heroTag: 'ai_fab',
      onPressed: () => showAiChatSheet(context),
      child: const Icon(Icons.smart_toy_outlined),
    );
  }
}

/// 弹出 AI 聊天窗口（底部上移动画）。
void showAiChatSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AiChatSheet(),
  );
}

class _AiChatSheet extends ConsumerStatefulWidget {
  const _AiChatSheet();

  @override
  ConsumerState<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<_AiChatSheet> {
  String? _convId;
  bool _sending = false;
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
    setState(() => _convId = conv.id);
  }

  Future<void> _deleteConversation(String id) async {
    await ref.read(aiChatProvider.notifier).deleteConversation(id);
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
    await chat.appendMessage(conv.id, const AiMessage(role: 'assistant', content: ''));
    _scrollToBottom();

    try {
      // 只带当前会话历史（不含占位空消息）
      final history = _current(ref.read(aiChatProvider))!.messages
          .sublist(0, _current(ref.read(aiChatProvider))!.messages.length - 1);
      final reply = await client.chat(
        systemPrompt: kDefaultSystemPrompt,
        history: history,
        userMessage: text,
      );
      await chat.replaceLast(
        conv.id,
        AiMessage(role: 'assistant', content: reply),
      );
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
    final height = MediaQuery.sizeOf(context).height;

    return SizedBox(
      height: height * 0.85,
      child: Column(
        children: [
          // 顶部栏：标题 + 历史 + 新建
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, size: 20),
                const SizedBox(width: 8),
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
                  icon: const Icon(Icons.history, size: 22),
                  onPressed: () => _showHistoryDrawer(conversations),
                ),
                IconButton(
                  tooltip: '新建对话',
                  icon: const Icon(Icons.add_comment_outlined, size: 22),
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
                  const SizedBox(width: 8),
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
      ),
    );
  }

  void _showHistoryDrawer(List<AiConversation> conversations) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
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
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无历史对话'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: conversations.length,
                  itemBuilder: (context, i) {
                    final c = conversations[i];
                    return ListTile(
                      leading: Icon(
                        c.id == _convId
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

  static const _suggestions = [
    '帮我分析这个月的收支情况',
    '我想制定一个省钱计划',
    '如何减少不必要的支出？',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text('把统计数据发给我，我来帮你分析', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '建议只粘贴汇总数据，避免发送敏感账户信息',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
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
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : isError
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
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
