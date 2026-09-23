import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_service.dart';
import '../services/currency_service.dart';

/// AI 更新汇率的返回结果：解析出的新汇率表。
class AiRateResult {
  const AiRateResult({required this.rates});

  /// code → 新汇率（已过滤非法值，只含支持的币种）。
  final Map<String, double> rates;
}

/// AI 汇率更新异常：携带给用户看的原因。
class AiRateException implements Exception {
  const AiRateException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 组装「获取汇率」的固定 user prompt。
///
/// 要求 AI 只返回严格 JSON：`{"rates": {"USD": 7.15, ...}}`，
/// 无解释文字、无 markdown 代码块。币种列表动态取自内置支持表。
String buildRatePrompt() {
  final codes = CurrencyService.supportedCodes.join(', ');
  return '请提供以下币种兑 CNY（人民币）的最新汇率（1 单位外币 = X 元人民币）：\n'
      '$codes\n\n'
      '要求：只返回一个 JSON 对象，格式为 {"rates":{"USD":7.15,"EUR":7.8,...}}，'
      '包含上述所有币种，值为正数。\n'
      '不要返回任何解释文字，不要使用 markdown 代码块，不要省略币种。\n'
      '如果你无法获取实时汇率，请如实说明并给出你掌握的最新值，不要编造离谱数字。';
}

/// 从 AI 原始回复中解析出汇率表。
///
/// 容错：允许回复被 markdown 代码块包裹；只截取首个 `{` 到末个 `}` 之间的
/// JSON；值必须是正数；只保留 [CurrencyService.supportedCodes] 内的币种。
/// 解析失败抛 [AiRateException]（含面向用户的失败原因）。
Map<String, double> parseAiRates(String reply) {
  var text = reply.trim();
  // 剥掉 markdown 代码块围栏（```json ... ```）
  final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
  final fenceMatch = fence.firstMatch(text);
  if (fenceMatch != null) text = fenceMatch.group(1)!.trim();

  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const AiRateException(
      'AI 返回中没有可解析的 JSON 对象（缺少 { } 包裹）',
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(text.substring(start, end + 1));
  } catch (e) {
    throw AiRateException('AI 返回的 JSON 无法解析：$e');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const AiRateException('AI 返回的 JSON 不是对象结构');
  }
  final rates = decoded['rates'];
  if (rates is! Map<String, dynamic>) {
    throw const AiRateException('AI 返回缺少 "rates" 字段或格式错误');
  }

  final supported = CurrencyService.supportedCodes.toSet();
  final result = <String, double>{};
  final rejected = <String>[];
  for (final entry in rates.entries) {
    final code = entry.key;
    final value = entry.value;
    // 只接受支持的币种
    if (!supported.contains(code)) {
      rejected.add('$code(未知币种)');
      continue;
    }
    // 值必须是有限正数，且不可能是明显离谱的汇率
    if (value is! num || !value.isFinite || value <= 0 || value >= 100000) {
      rejected.add('$code($value)');
      continue;
    }
    result[code] = value.toDouble();
  }

  if (result.isEmpty) {
    throw AiRateException(
      '没有可用的汇率：${rejected.isEmpty ? 'AI 未返回任何币种' : rejected.join('、')}',
    );
  }
  // 有部分币种被拒时给出提示（不阻断可用部分）
  if (rejected.isNotEmpty) {
    throw AiRateException('部分币种被忽略：${rejected.join('、')}');
  }
  return result;
}

/// 调用当前 AI 配置获取最新汇率，返回解析后的汇率表。
///
/// 未配置 AI / 网络失败 / 解析失败均抛 [AiRateException]。
Future<AiRateResult> fetchAiRates(WidgetRef ref) async {
  final client = ref.read(aiClientProvider);
  if (client == null) {
    throw const AiRateException('尚未配置 AI，请先在「我的-设置-AI 设置」中完成配置');
  }
  final String reply;
  try {
    reply = await client.chat(
      systemPrompt:
          '你是 XuPurse 记账应用的汇率助手。严格遵守用户对输出格式的要求，'
          '只输出符合要求的 JSON，不要添加任何其他文字。',
      history: const [],
      userMessage: buildRatePrompt(),
    );
  } catch (e) {
    throw AiRateException('请求 AI 失败：$e');
  }
  if (reply.trim().isEmpty) {
    throw const AiRateException('AI 未返回任何内容');
  }
  return AiRateResult(rates: parseAiRates(reply));
}
