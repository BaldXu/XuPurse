import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 接口协议类型。
enum AiProtocol { openai, anthropic }

extension AiProtocolLabel on AiProtocol {
  String get label => switch (this) {
    AiProtocol.openai => 'OpenAI 兼容',
    AiProtocol.anthropic => 'Anthropic 兼容',
  };

  /// 默认 base 地址（用户可改为任意兼容网关/代理）。
  String get defaultBaseUrl => switch (this) {
    AiProtocol.openai => 'https://api.openai.com/v1',
    AiProtocol.anthropic => 'https://api.anthropic.com/v1',
  };
}

/// 一份 AI API 配置（用户可保存多份，如 DeepSeek / 火山方舟 / OpenAI 各一份）。
class AiConfig {
  const AiConfig({
    required this.id,
    required this.name,
    required this.protocol,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.enabled = true,
  });

  final String id;
  final String name; // 配置别名，如「DeepSeek」「火山方舟」
  final AiProtocol protocol;
  final String baseUrl; // 如 https://api.deepseek.com/v1
  final String apiKey;
  final String model; // 如 deepseek-chat / claude-sonnet-4-5 / doubao-*
  final double temperature;
  final int maxTokens;
  final bool enabled; // 是否作为可用配置（可临时停用）

  AiConfig copyWith({
    String? id,
    String? name,
    AiProtocol? protocol,
    String? baseUrl,
    String? apiKey,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? enabled,
  }) {
    final String theKey = apiKey ?? this.apiKey;
    final int theMax = maxTokens ?? this.maxTokens;
    final String theModel = model ?? this.model;
    final String theBase = baseUrl ?? this.baseUrl;
    final String theName = name ?? this.name;
    final String theId = id ?? this.id;
    final AiProtocol theProto = protocol ?? this.protocol;
    final double theTemp = temperature ?? this.temperature;
    final bool theEnabled = enabled ?? this.enabled;
    return AiConfig(
      id: theId,
      name: theName,
      protocol: theProto,
      baseUrl: theBase,
      apiKey: theKey,
      model: theModel,
      temperature: theTemp,
      maxTokens: theMax,
      enabled: theEnabled,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'protocol': protocol.name,
    'baseUrl': baseUrl,
    'apiKey': apiKey,
    'model': model,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'enabled': enabled,
  };

  static AiConfig fromJson(Map<String, Object?> json) => AiConfig(
    id: json['id'] as String,
    name: json['name'] as String? ?? '未命名',
    protocol: AiProtocol.values.firstWhere(
      (p) => p.name == json['protocol'],
      orElse: () => AiProtocol.openai,
    ),
    baseUrl: json['baseUrl'] as String? ?? '',
    apiKey: json['apiKey'] as String? ?? '',
    model: json['model'] as String? ?? '',
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    maxTokens: json['maxTokens'] as int? ?? 2048,
    enabled: json['enabled'] as bool? ?? true,
  );

  /// 对外展示的 key（仅首尾，避免完整明文外泄到界面/日志）。
  String get maskedKey {
    if (apiKey.length <= 8) return '••••';
    return '${apiKey.substring(0, 4)}••••${apiKey.substring(apiKey.length - 4)}';
  }
}

/// AI 状态：配置列表 + 当前使用的配置 id。
class AiState {
  const AiState({required this.configs, this.currentId});

  final List<AiConfig> configs;
  final String? currentId;

  /// 当前使用的配置（null = 未配置或已全部删除）。
  AiConfig? get current {
    if (configs.isEmpty) return null;
    return configs.firstWhere(
      (c) => c.id == currentId && c.enabled,
      orElse: () =>
          configs.firstWhere((c) => c.enabled, orElse: () => configs.first),
    );
  }

  bool get isConfigured => current != null && current!.apiKey.isNotEmpty;

  AiState copyWith({List<AiConfig>? configs, String? currentId}) => AiState(
    configs: configs ?? this.configs,
    currentId: currentId ?? this.currentId,
  );
}

/// AI 配置状态（多配置管理），持久化到 SharedPreferences。
///
/// 注意：apiKey 以明文存储于本地（与主流记账/客户端行为一致），
/// 不上传、不进日志；界面一律展示 maskedKey。
final aiConfigProvider = NotifierProvider<AiConfigNotifier, AiState>(
  AiConfigNotifier.new,
);

class AiConfigNotifier extends Notifier<AiState> {
  static const _configsKey = 'ai_configs';
  static const _currentKey = 'ai_current_id';

  @override
  AiState build() {
    final raw = _prefs?.getString(_configsKey);
    var configs = const <AiConfig>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        configs = [
          for (final e in jsonDecode(raw) as List<dynamic>)
            AiConfig.fromJson((e as Map).cast<String, Object?>()),
        ];
      } catch (_) {
        configs = const [];
      }
    }
    final currentId = _prefs?.getString(_currentKey);
    return AiState(configs: configs, currentId: currentId);
  }

  static SharedPreferences? _prefs;

  /// main 启动时调用（与 ThemeNotifier.init 同模式）。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _persist(AiState next) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(
      _configsKey,
      jsonEncode([for (final c in next.configs) c.toJson()]),
    );
    if (next.currentId != null) {
      await prefs.setString(_currentKey, next.currentId!);
    } else {
      await prefs.remove(_currentKey);
    }
  }

  /// 新增/更新配置（id 相同即更新）。返回保存后的 id。
  Future<String> upsert(AiConfig config) async {
    final id = config.id.isEmpty
        ? DateTime.now().microsecondsSinceEpoch.toString()
        : config.id;
    final saved = config.copyWith(id: id);
    final exists = state.configs.any((c) => c.id == id);
    final configs = exists
        ? [for (final c in state.configs) c.id == id ? saved : c]
        : [...state.configs, saved];
    final next = AiState(
      configs: configs,
      currentId: state.currentId ?? id, // 首个配置自动设为当前
    );
    await _persist(next);
    state = next;
    return id;
  }

  Future<void> remove(String id) async {
    final configs = state.configs.where((c) => c.id != id).toList();
    final currentId = state.currentId == id ? null : state.currentId;
    final next = AiState(configs: configs, currentId: currentId);
    await _persist(next);
    state = next;
  }

  /// 切换当前使用的配置（跳过已停用的）。
  Future<void> select(String id) async {
    if (!state.configs.any((c) => c.id == id && c.enabled)) return;
    final next = state.copyWith(currentId: id);
    await _persist(next);
    state = next;
  }

  /// 启用/停用配置。
  Future<void> setEnabled(String id, bool enabled) async {
    final configs = [
      for (final c in state.configs)
        c.id == id ? c.copyWith(enabled: enabled) : c,
    ];
    final next = AiState(configs: configs, currentId: state.currentId);
    await _persist(next);
    state = next;
  }
}
