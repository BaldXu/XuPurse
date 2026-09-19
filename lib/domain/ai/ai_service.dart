import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_config.dart';

/// 一条聊天消息。
class AiMessage {
  const AiMessage({required this.role, required this.content, this.error});

  /// 'user' | 'assistant'
  final String role;
  final String content;

  /// 请求失败时的错误说明（仅 assistant 消息可能出现）。
  final String? error;

  Map<String, Object?> toJson() => {'role': role, 'content': content, if (error != null) 'error': error};

  static AiMessage fromJson(Map<String, Object?> json) => AiMessage(
    role: json['role'] as String,
    content: json['content'] as String? ?? '',
    error: json['error'] as String?,
  );
}

/// 一次会话（对话线程）。
class AiConversation {
  const AiConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title; // 取首条用户消息前缀
  final List<AiMessage> messages;
  final int createdAt;
  final int updatedAt;

  AiConversation copyWith({List<AiMessage>? messages, int? updatedAt, String? title}) =>
      AiConversation(
        id: id,
        title: title ?? this.title,
        messages: messages ?? this.messages,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'messages': [for (final m in messages) m.toJson()],
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  static AiConversation fromJson(Map<String, Object?> json) => AiConversation(
    id: json['id'] as String,
    title: json['title'] as String? ?? '新对话',
    messages: [
      for (final m in (json['messages'] as List<dynamic>? ?? const []))
        AiMessage.fromJson((m as Map).cast<String, Object?>()),
    ],
    createdAt: json['createdAt'] as int? ?? 0,
    updatedAt: json['updatedAt'] as int? ?? 0,
  );
}

/// 会话历史状态（多会话管理），持久化到 SharedPreferences。
final aiChatProvider =
    NotifierProvider<AiChatNotifier, List<AiConversation>>(AiChatNotifier.new);

class AiChatNotifier extends Notifier<List<AiConversation>> {
  static const _key = 'ai_conversations';

  @override
  List<AiConversation> build() {
    final raw = _prefs?.getStringSync(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [
        for (final e in jsonDecode(raw) as List<dynamic>)
          AiConversation.fromJson((e as Map).cast<String, Object?>()),
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const [];
    }
  }

  static SharedPreferencesLike? _prefs;

  /// main 启动时调用。
  static Future<void> init() async {
    _prefs = await SharedPreferencesLike.getInstance();
  }

  Future<void> _persist(List<AiConversation> next) async {
    final prefs = _prefs ?? await SharedPreferencesLike.getInstance();
    _prefs = prefs;
    await prefs.setString(
      _key,
      jsonEncode([for (final c in next) c.toJson()]),
    );
  }

  /// 新建对话并置顶返回。
  Future<AiConversation> createConversation() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final conv = AiConversation(
      id: 'ai-$now',
      title: '新对话',
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );
    final next = [conv, ...state];
    await _persist(next);
    state = next;
    return conv;
  }

  /// 追加消息（用户消息或助手回复）。
  Future<void> appendMessage(String convId, AiMessage message) async {
    final next = <AiConversation>[];
    for (final c in state) {
      if (c.id != convId) {
        next.add(c);
        continue;
      }
      final messages = [...c.messages, message];
      next.add(
        c.copyWith(
          messages: messages,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          // 首条用户消息作为会话标题
          title: c.messages.isEmpty && message.role == 'user'
              ? _titleOf(message.content)
              : null,
        ),
      );
    }
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persist(next);
    state = next;
  }

  /// 把末尾占位的助手消息替换为最终内容（流式结束后调用）。
  Future<void> replaceLast(String convId, AiMessage message) async {
    final next = <AiConversation>[];
    for (final c in state) {
      if (c.id != convId || c.messages.isEmpty) {
        next.add(c);
        continue;
      }
      next.add(
        c.copyWith(
          messages: [...c.messages.sublist(0, c.messages.length - 1), message],
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    next.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _persist(next);
    state = next;
  }

  Future<void> deleteConversation(String id) async {
    final next = state.where((c) => c.id != id).toList();
    await _persist(next);
    state = next;
  }

  static String _titleOf(String content) {
    final t = content.trim().replaceAll('\n', ' ');
    return t.length <= 20 ? (t.isEmpty ? '新对话' : t) : '${t.substring(0, 20)}…';
  }
}

/// SharedPreferences 轻量封装（动态持有 shared_preferences 实例）。
class SharedPreferencesLike {
  SharedPreferencesLike._(this._prefs);

  final dynamic _prefs;

  static Future<SharedPreferencesLike> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesLike._(prefs);
  }

  String? getStringSync(String key) => _prefs.getString(key) as String?;

  Future<String?> getString(String key) async => getStringSync(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
}

/// AI 客户端：OpenAI 兼容 / Anthropic 兼容两种协议的 chat 调用。
class AiClient {
  AiClient(this._config);

  final AiConfig _config;

  static const _timeout = Duration(seconds: 60);

  /// 发送消息历史，返回助手回复全文。onDelta 用于渐进更新（非流式协议只回调一次）。
  Future<String> chat({
    required String systemPrompt,
    required List<AiMessage> history,
    required String userMessage,
    void Function(String delta)? onDelta,
  }) async {
    final headers = _headers();
    final body = _buildBody(systemPrompt, history, userMessage);
    final resp = await http
        .post(_chatUrl(), headers: headers, body: jsonEncode(body))
        .timeout(_timeout);

    if (resp.statusCode != 200) {
      throw Exception(
        'API ${resp.statusCode}：${resp.body.length > 300 ? resp.body.substring(0, 300) : resp.body}',
      );
    }
    final text = _extractText(jsonDecode(utf8.decode(resp.bodyBytes)));
    if (onDelta != null && text.isNotEmpty) onDelta(text);
    return text;
  }

  Uri _chatUrl() {
    final base = _config.baseUrl.endsWith('/')
        ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
        : _config.baseUrl;
    return switch (_config.protocol) {
      AiProtocol.openai => Uri.parse('$base/chat/completions'),
      AiProtocol.anthropic => Uri.parse('$base/messages'),
    };
  }

  Map<String, String> _headers() => switch (_config.protocol) {
    AiProtocol.openai => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_config.apiKey}',
    },
    AiProtocol.anthropic => {
      'Content-Type': 'application/json',
      'x-api-key': _config.apiKey,
      'anthropic-version': '2023-06-01',
      // 浏览器端 fetch 需要；Native 端无害
      'anthropic-dangerous-direct-browser-access': 'true',
    },
  };

  Map<String, Object?> _buildBody(
    String systemPrompt,
    List<AiMessage> history,
    String userMessage,
  ) {
    final msgs = [
      ...history.where((m) => m.error == null).map(
        (m) => {'role': m.role, 'content': m.content},
      ),
      {'role': 'user', 'content': userMessage},
    ];
    return switch (_config.protocol) {
      AiProtocol.openai => {
        'model': _config.model,
        'temperature': _config.temperature,
        'max_tokens': _config.maxTokens,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          ...msgs,
        ],
      },
      AiProtocol.anthropic => {
        'model': _config.model,
        'temperature': _config.temperature,
        'max_tokens': _config.maxTokens,
        'system': systemPrompt,
        'messages': msgs,
      },
    };
  }

  /// 从两种协议的响应 JSON 中提取回复文本。
  String _extractText(dynamic json) {
    if (json is! Map<String, dynamic>) return '';
    // OpenAI: choices[0].message.content
    final choices = json['choices'] as List<dynamic>?;
    if (choices != null && choices.isNotEmpty) {
      final msg = (choices.first as Map<String, dynamic>)['message'];
      if (msg is Map<String, dynamic>) return msg['content'] as String? ?? '';
    }
    // Anthropic: content[].text
    final content = json['content'] as List<dynamic>?;
    if (content != null && content.isNotEmpty) {
      final buf = StringBuffer();
      for (final part in content) {
        if (part is Map<String, dynamic> && part['type'] == 'text') {
          buf.write(part['text'] as String? ?? '');
        }
      }
      return buf.toString();
    }
    return '';
  }

  /// 连通性测试：发一句极短的探测消息，正常返回即通过。
  Future<void> testConnection() async {
    await chat(
      systemPrompt: 'You are a health check. Reply with: ok',
      history: const [],
      userMessage: 'ping',
    );
  }
}

/// AiClient provider（跟随当前 AI 配置变化）。
final aiClientProvider = Provider<AiClient?>((ref) {
  final state = ref.watch(aiConfigProvider);
  final config = state.current;
  if (config == null || config.apiKey.isEmpty || config.model.isEmpty) {
    return null;
  }
  return AiClient(config);
});

/// 默认系统提示词：角色 / 技能 / 隐私规矩。
final String kDefaultSystemPrompt = _systemPromptText.trim();

const String _systemPromptText = '''
你是 XuPurse 记账应用的财务分析助手。

## 角色
- 你是一名耐心的个人财务顾问，帮助用户理解自己的记账数据：收支结构、趋势变化、预算执行等。
- 用简体中文回答；语气自然、结论先行；金额使用「元」表述。

## 技能
- 分析用户粘贴的记账汇总/趋势数据（月收支、分类占比、资产趋势、累计净额等）。
- 给出可执行的建议：省钱方向、预算调整、异常消费提醒。
- 识别数据中的明显异常（如某分类暴涨、收支连续为负）并主动指出。

## 隐私规矩（最高优先级，不可违背）
- 用户数据仅用于本次对话分析。除用户在对话中主动粘贴的内容外，你不应请求、猜测或引导用户提供更多个人信息。
- 不要要求用户提供：完整身份证号、银行卡号、密码、API 密钥、验证码等敏感信息；即使用户主动提供，也应提醒不要在对话中发送。
- 你的回答中不要复述用户数据中的敏感标识（如完整账号），必要时用打码形式（如 6222••••1234）。
- 不确定的信息要明确说「不确定」，不要编造数字或结论。

## 限制
- 你无法直接访问用户的账本数据库；只能分析用户在对话中提供的数据摘要。
- 涉及投资建议时保持保守，强调「不构成投资建议」。
''';
