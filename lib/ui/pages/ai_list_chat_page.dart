import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/bill_list_repository.dart';
import '../../domain/ai/ai_analysis_context.dart';
import '../../domain/ai/ai_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';

/// 消费清单 AI 分析：把整份清单（逐笔 + 清单内分类）交给 AI。
///
/// 进入即代表用户同意发送整份清单，因此没有额外范围设置；
/// 会话历史独立于统计助手。
class AiListChatPage extends ConsumerStatefulWidget {
  const AiListChatPage({
    super.key,
    required this.listName,
    required this.items,
    required this.sections,
  });

  final String listName;
  final List<BillListItemView> items;
  final List<BillListSection> sections;

  @override
  ConsumerState<AiListChatPage> createState() => _AiListChatPageState();
}

class _AiListChatPageState extends ConsumerState<AiListChatPage>
    with XpPageScaffold<AiListChatPage> {
  late final AiAnalysisData _data;
  late final String _sectionSummary;

  String? _convId;
  bool _sending = false;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _suggestions = [
    '这次一共花了多少？哪块最贵？',
    '前期准备里有哪些是没必要的？',
    '下次同样的行程，哪里可以省？',
  ];

  @override
  void initState() {
    super.initState();
    final sectionName = {for (final s in widget.sections) s.id: s.name};
    final sectionByBill = <String, String>{};
    for (final item in widget.items) {
      final name = sectionName[item.sectionId];
      if (name != null) sectionByBill[item.bill.id] = name;
    }
    final refunds =
        ref.read(refundTotalsProvider).valueOrNull ?? const <String, int>{};
    _data = AiAnalysisContext(ref).buildFromBills(
      bills: [for (final item in widget.items) item.bill],
      includeNotes: true,
      listName: widget.listName,
      sectionByBillId: sectionByBill,
      refundByBillId: refunds,
    );
    _sectionSummary = _buildSectionSummary(sectionName, refunds);
    _ensureConversation();
  }

  /// 各清单分类的小计，放在 system prompt 里便于 AI 直接引用。
  String _buildSectionSummary(
    Map<String, String?> sectionName,
    Map<String, int> refunds,
  ) {
    final total = <String, int>{};
    final count = <String, int>{};
    for (final item in widget.items) {
      if (item.bill.type == 'transfer') continue;
      final name = sectionName[item.sectionId] ?? '未分类';
      // 支出扣退款；收入（AA 回款/报销）抵扣该分类的花费。
      final int delta;
      if (item.bill.type == 'income') {
        delta = -item.bill.amount;
      } else {
        delta = item.bill.amount - (refunds[item.bill.id] ?? 0);
      }
      total.update(name, (v) => v + delta, ifAbsent: () => delta);
      count.update(name, (v) => v + 1, ifAbsent: () => 1);
    }
    if (total.isEmpty) return '';
    final buf = StringBuffer('各分类净花费（支出扣退款、收入已抵扣）：\n');
    total.forEach((name, amount) {
      buf.writeln('- $name：${count[name]} 笔，¥${formatYuan(amount)}');
    });
    return buf.toString();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _ensureConversation() async {
    final list = ref.read(aiListChatProvider);
    if (list.isNotEmpty) {
      setState(() => _convId = list.first.id);
      return;
    }
    final conv = await ref
        .read(aiListChatProvider.notifier)
        .createConversation();
    if (mounted) setState(() => _convId = conv.id);
  }

  AiConversation? _current(List<AiConversation> list) {
    if (_convId == null) return null;
    for (final c in list) {
      if (c.id == _convId) return c;
    }
    return null;
  }

  String _systemPrompt() {
    return '$kDefaultSystemPrompt\n\n'
        '## 本机消费清单（用户已授权，逐笔）\n'
        '清单：「${widget.listName}」，共 ${_data.count} 笔，'
        '支出 ¥${formatYuan(_data.expense)}，'
        '收入 ¥${formatYuan(_data.income)}，'
        '实际花费 ¥${formatYuan(_data.expense - _data.income)}。\n'
        '注意：清单里的收入（如朋友 AA 回款、报销）应视为抵扣，'
        '回答「这次花了多少」时用实际花费口径。\n'
        '$_sectionSummary\n'
        'JSON 字段：t 时间；ty 类型（exp 支出 / inc 收入 / trf 转账）；'
        'a 金额（元，支出已扣减退款）；c 记账分类；sec 清单内分类；ac 账户；'
        'rf 退款金额；n 备注（*** 表示已脱敏）。\n'
        '请围绕「这次事件花了多少、花在哪、哪些可以省」回答；'
        '可直接引用具体账目，但不要整段复述 JSON。\n\n'
        '```json\n${_data.json}\n```';
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final client = ref.read(aiClientProvider);
    final conv = _current(ref.read(aiListChatProvider));
    if (client == null || conv == null) return;

    _inputCtrl.clear();
    setState(() => _sending = true);
    final chat = ref.read(aiListChatProvider.notifier);
    await chat.appendMessage(conv.id, AiMessage(role: 'user', content: text));
    await chat.appendMessage(
      conv.id,
      const AiMessage(role: 'assistant', content: ''),
    );
    _scrollToBottom();

    try {
      final now = _current(ref.read(aiListChatProvider));
      if (now == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      final history = now.messages.sublist(0, now.messages.length - 1);
      final reply = await client.chat(
        systemPrompt: _systemPrompt(),
        history: history,
        userMessage: text,
      );
      if (reply.trim().isEmpty) {
        await chat.replaceLast(
          conv.id,
          const AiMessage(
            role: 'assistant',
            content: '（未收到回复内容：模型可能把输出 tokens 用在了思考上。）',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final conv = _current(ref.watch(aiListChatProvider));
    final messages = conv?.messages ?? const <AiMessage>[];

    return buildXpScaffold(
      appBar: AppBar(title: const Text('AI 分析清单')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: scheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(
              horizontal: XpSpacing.l,
              vertical: XpSpacing.s,
            ),
            child: Text(
              '${widget.listName} · ${_data.count} 笔 · '
              '实际 ¥${formatYuan(_data.expense - _data.income)}'
              '${_data.income > 0 ? '（收入 ¥${formatYuan(_data.income)} 已抵扣）' : ''}'
              ' · 含备注（脱敏）',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: messages.isEmpty
                ? _EmptyHint(
                    suggestions: _suggestions,
                    onPick: (s) {
                      _inputCtrl.text = s;
                      _inputCtrl.selection = TextSelection.collapsed(
                        offset: s.length,
                      );
                    },
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(XpSpacing.l),
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
                    'AI 正在阅读这份清单…',
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
                        hintText: '问问这次花了多少…',
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
                    onPressed: _sending ? null : _send,
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
          '这份清单已经交给 AI 了',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: XpSpacing.xs),
        Text(
          '可以直接问，也可以点下面的问题。',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: XpSpacing.xl),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: XpSpacing.s),
            child: Material(
              color: scheme.surfaceContainerHighest,
              borderRadius: XpRadius.card,
              child: InkWell(
                borderRadius: XpRadius.card,
                onTap: () => onPick(s),
                child: Padding(
                  padding: const EdgeInsets.all(XpSpacing.m),
                  child: Text(s, style: theme.textTheme.bodyMedium),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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
        : (isError ? scheme.errorContainer : scheme.surfaceContainerHighest);
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
            ? const SizedBox(
                width: 28,
                height: 14,
                child: LinearProgressIndicator(minHeight: 2),
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
