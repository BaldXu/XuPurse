import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_analysis_context.dart';
import '../../domain/ai/ai_config.dart';
import '../../domain/ai/ai_scope.dart';
import '../../domain/ai/ai_service.dart';
import '../../domain/ai/stats_context.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/ai_mode_banner.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'ai_analysis_privacy_page.dart';
import 'ai_scope_page.dart';

/// AI 助手聊天页（整页，替代原来的底部弹窗）。
///
/// 数据来源由「数据范围设置」的模式决定：
/// - 标准：注入聚合统计摘要；
/// - 详细：注入逐笔明细 JSON。
///
/// 两种模式都在**每一轮**请求里重新拼进 system prompt（数据在进入页面时
/// 生成一份快照并缓存），不会出现「第二轮就失忆」的问题。
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage>
    with XpPageScaffold<AiChatPage> {
  /// 进入页面时的范围快照：页面内不跟随全局变化，避免中途换数据。
  late AiScope _scope;

  String _summary = '';
  AiAnalysisData? _detail;

  bool _preparing = true;
  String? _prepareError;

  String? _convId;
  bool _sending = false;

  /// 思考模式（默认关闭；仅疑似支持的模型显示开关）。
  bool _thinking = false;

  /// 当前配置的模型是否疑似支持思考模式（启发式，按模型名判断）。
  bool get _modelSupportsThinking {
    final model = ref.watch(
      aiConfigProvider.select((s) => s.current?.model ?? ''),
    );
    return AiClient.modelSupportsThinking(model);
  }

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool get _isDetail => _scope.isDetail;

  static const _summarySuggestions = [
    '这个月我的钱都花哪了？',
    '我的消费结构有什么问题？',
    '预算执行得怎么样？',
  ];

  static const _detailSuggestions = [
    '这个月哪类支出涨得最多？',
    '有没有重复扣款或可疑订阅？',
    '帮我挑出几笔最该控制的大额支出',
  ];

  @override
  void initState() {
    super.initState();
    _scope = ref.read(aiScopeProvider);
    _ensureConversation();
    _prepare();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      if (_isDetail) {
        final (start, end) = _scope.resolveDetailRange(DateTime.now());
        final data = await AiAnalysisContext(ref).build(
          start: start,
          end: end,
          includeNotes: _scope.detailIncludeNotes,
        );
        if (!mounted) return;
        setState(() {
          _detail = data;
          _preparing = false;
        });
      } else {
        final text = _scope.enabled
            ? await AiStatsContext(ref).build(override: _scope)
            : '';
        if (!mounted) return;
        setState(() {
          _summary = text;
          _preparing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _prepareError = e.toString();
        _preparing = false;
      });
    }
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
    if (mounted) setState(() => _convId = conv.id);
  }

  /// 本轮 system prompt：每轮都带上数据快照。
  String _systemPrompt() {
    if (_isDetail) {
      final d = _detail;
      if (d == null || d.json.isEmpty) return kDefaultSystemPrompt;
      final from = DateTime.fromMillisecondsSinceEpoch(d.start);
      final to = DateTime.fromMillisecondsSinceEpoch(d.end - 1);
      return '$kDefaultSystemPrompt\n\n'
          '## 本机账单明细（用户已授权，逐笔）\n'
          '（这是用户单独授权发送的原始账目，不是聚合摘要；请直接把它当作已知数据。）\n'
          '用户选择的范围：${from.year}/${from.month}/${from.day} - '
          '${to.year}/${to.month}/${to.day}，共 ${d.count} 笔，'
          '${d.includeNotes ? '附带备注（*** 表示已脱敏）' : '不含备注'}。\n'
          '字段说明：t 时间；ty 类型（exp 支出 / inc 收入 / trf 转账）；'
          'a 金额（元）；c 分类（一级/叶子）；ac 账户；n 备注。\n'
          '请直接基于这份明细回答，不要要求用户再提供数据；'
          '可以引用具体账目（日期 + 金额），但不要整段复述 JSON。\n\n'
          '```json\n${d.json}\n```';
    }
    if (_summary.isEmpty) return kDefaultSystemPrompt;
    return '$kDefaultSystemPrompt\n\n$_summary';
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending || _preparing) return;
    if (_isDetail && (_detail?.overLimit ?? true)) return;
    final client = ref.read(aiClientProvider);
    final conv = _current(ref.read(aiChatProvider));
    if (client == null || conv == null) return;

    _inputCtrl.clear();
    setState(() => _sending = true);
    final chat = ref.read(aiChatProvider.notifier);

    await chat.appendMessage(conv.id, AiMessage(role: 'user', content: text));
    await chat.appendMessage(
      conv.id,
      const AiMessage(role: 'assistant', content: ''),
    );
    _scrollToBottom();

    try {
      final convNow = _current(ref.read(aiChatProvider));
      if (convNow == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      final history = convNow.messages.sublist(0, convNow.messages.length - 1);
      final reply = await client.chat(
        systemPrompt: _systemPrompt(),
        history: history,
        userMessage: text,
        enableThinking: _thinking,
      );
      if (reply.trim().isEmpty) {
        await chat.replaceLast(
          conv.id,
          const AiMessage(
            role: 'assistant',
            content:
                '（未收到回复内容：模型可能把全部输出 tokens 用在思考上。'
                '请在「AI 设置」里调大「最大输出 tokens」，或换用非推理模型。）',
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
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openScopeSettings() async {
    await Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => const AiScopePage()));
    if (!mounted) return;
    // 设置可能变了：重新准备数据，并新开一个会话避免上下文串味。
    final next = ref.read(aiScopeProvider);
    if (next != _scope) {
      setState(() {
        _scope = next;
        _preparing = true;
        _prepareError = null;
        _summary = '';
        _detail = null;
      });
      await _prepare();
      await _newConversation();
      if (mounted) showXpSnack(context, '数据范围已更新，已开始新的对话');
    }
  }

  void _openPrivacy() {
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => const AiAnalysisPrivacyPage()));
  }

  /// 模式条第二行：说清这次到底发了什么。
  String _bannerDescription(AiAnalysisData? d) {
    if (_preparing) return '正在准备本机数据…';
    if (!_scope.isDetail) {
      return _scope.enabled
          ? '只发送聚合摘要 · ${_scope.range.label} · 不含单笔明细'
          : '未授权读取账单数据，当前为纯聊天模式';
    }
    if (d == null) return '数据不可用，请到「数据范围设置」检查范围';
    final from = DateTime.fromMillisecondsSinceEpoch(d.start);
    final to = DateTime.fromMillisecondsSinceEpoch(d.end - 1);
    final kb = (d.bytes / 1024).toStringAsFixed(1);
    final tokens = (d.tokens / 1000).toStringAsFixed(1);
    return '每一笔账单都会发给 AI · '
        '${from.year}/${from.month}/${from.day}-'
        '${to.year}/${to.month}/${to.day} · ${d.count} 笔 · $kb KB'
        '${d.includeNotes ? ' · 含备注（脱敏）' : ' · 不含备注'}'
        ' · 每轮 ≈${tokens}k tokens'
        '${d.overLimit ? ' · 已超单次上限' : ''}';
  }

  Future<void> _showHistory() async {
    final conversations = ref.read(aiChatProvider);
    await showXpSheet<void>(
      context: context,
      heightFactor: 0.6,
      builder: (sheetCtx) => ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.m,
          XpSpacing.l,
          XpSpacing.l,
        ),
        children: [
          Text(
            '历史对话',
            style: Theme.of(
              sheetCtx,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: XpSpacing.m),
          if (conversations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(XpSpacing.l),
              child: Text(
                '还没有历史对话',
                style: Theme.of(sheetCtx).textTheme.bodySmall,
              ),
            )
          else
            for (final c in conversations)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const AppIcon(icon: Icons.chat_bubble_outline),
                title: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${c.messages.length} 条消息'),
                trailing: c.id == _convId
                    ? Icon(
                        Icons.check,
                        color: Theme.of(sheetCtx).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _convId = c.id);
                  Navigator.of(sheetCtx).pop();
                },
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final conversations = ref.watch(aiChatProvider);
    final conv = _current(conversations);
    final messages = conv?.messages ?? const <AiMessage>[];
    final detail = _detail;
    final blocked = _isDetail && (_detail?.overLimit ?? true);

    if (_prepareError != null) {
      return buildXpScaffold(
        appBar: AppBar(title: const Text('AI 助手')),
        body: XpEmptyState(
          icon: Icons.error_outline,
          title: '数据准备失败',
          message: _prepareError,
          actionLabel: '重试',
          onAction: () {
            setState(() {
              _prepareError = null;
              _preparing = true;
            });
            _prepare();
          },
        ),
      );
    }

    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        actions: [
          if (_modelSupportsThinking)
            IconButton(
              tooltip: _thinking ? '思考模式：开（点击关闭）' : '思考模式：关（点击开启）',
              icon: Icon(
                _thinking ? Icons.psychology : Icons.psychology_outlined,
                size: 22,
                color: _thinking
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _thinking = !_thinking),
            ),
          IconButton(
            tooltip: '数据范围设置',
            icon: const AppIcon(icon: Icons.tune, size: 22),
            onPressed: _openScopeSettings,
          ),
          IconButton(
            tooltip: '历史对话',
            icon: const AppIcon(icon: Icons.history, size: 22),
            onPressed: _showHistory,
          ),
          IconButton(
            tooltip: '新建对话',
            icon: const AppIcon(icon: Icons.add_comment_outlined, size: 22),
            onPressed: _sending ? null : _newConversation,
          ),
          const SizedBox(width: XpSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.s,
              XpSpacing.l,
              0,
            ),
            child: AiModeBanner(
              modeLabel: _scope.isDetail ? '详细' : '标准',
              warning: _scope.isDetail,
              description: _bannerDescription(detail),
              onTap: _scope.isDetail ? _openPrivacy : _openScopeSettings,
            ),
          ),
          Expanded(
            child: _preparing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(height: XpSpacing.m),
                        Text(
                          '正在读取本机数据…',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : messages.isEmpty
                ? _EmptyHint(
                    suggestions: _isDetail
                        ? _detailSuggestions
                        : _summarySuggestions,
                    onPick: (s) {
                      _inputCtrl.text = s;
                      _inputCtrl.selection = TextSelection.collapsed(
                        offset: s.length,
                      );
                    },
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(
                      XpSpacing.l,
                      XpSpacing.m,
                      XpSpacing.l,
                      XpSpacing.m,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, i) =>
                        _Bubble(message: messages[i]),
                  ),
          ),
          if (_sending)
            Padding(
              padding: const EdgeInsets.only(bottom: XpSpacing.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: XpSpacing.s),
                  Text(
                    'AI 正在思考…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                XpSpacing.l,
                0,
                XpSpacing.l,
                XpSpacing.m,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: '问问你的账单…',
                        filled: true,
                        fillColor: scheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(XpRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: XpSpacing.l,
                          vertical: XpSpacing.s,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: XpSpacing.s),
                  IconButton.filled(
                    onPressed: _sending || _preparing || blocked
                        ? null
                        : _send,
                    tooltip: '发送',
                    icon: const Icon(Icons.arrow_upward, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空会话提示 + 建议问题。
class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.suggestions, required this.onPick});

  final List<String> suggestions;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.all(XpSpacing.xl),
      children: [
        const SizedBox(height: XpSpacing.xl),
        AppIcon(icon: Icons.insights_outlined, size: 40, color: scheme.primary),
        const SizedBox(height: XpSpacing.m),
        Text(
          '可以直接问，也可以点下面的问题',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: XpSpacing.xl),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: XpSpacing.s),
            child: XpCard(
              padding: const EdgeInsets.all(XpSpacing.m),
              onTap: () => onPick(s),
              child: Text(s, style: theme.textTheme.bodyMedium),
            ),
          ),
      ],
    );
  }
}

/// 单条消息气泡（用户靠右、助手靠左）。
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUser = message.role == 'user';
    final isError = message.error != null;
    final bg = isUser
        ? scheme.primary
        : (isError
              ? scheme.errorContainer
              : scheme.surfaceContainerHighest);
    final fg = isUser
        ? scheme.onPrimary
        : (isError ? scheme.onErrorContainer : scheme.onSurface);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: XpSpacing.s),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.m,
          vertical: XpSpacing.s,
        ),
        decoration: ShapeDecoration(
          color: bg,
          shape: XpShape.smooth(
            borderRadius: BorderRadius.circular(XpRadius.m),
          ),
        ),
        child: message.content.isEmpty
            ? SizedBox(
                width: 28,
                height: 14,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : SelectableText(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  height: 1.55,
                ),
              ),
      ),
    );
  }
}
