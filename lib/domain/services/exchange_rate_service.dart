import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'currency_service.dart';

/// 汇率获取失败异常：携带面向用户的原因。
class RateFetchException implements Exception {
  const RateFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 本币：汇率表以 CNY 为锚（`rate['CNY'] = 1`）。
const _baseCode = 'CNY';

/// 汇率数据源：Frankfurter（https://frankfurter.dev）。
///
/// 聚合各国央行每日参考汇率；免费、无需 API key、允许商用与自托管，响应头
/// CORS 为 `*`，Web 端可直接请求（无需自建代理）。
/// 注意是「每日参考汇率」而非实时行情：一天一个值，周末/节假日返回上一交易日。
const _endpoint = 'https://api.frankfurter.dev/v2/rates';

/// 汇率请求超时：数据每日只更新一次，失败应快速暴露而非长时间等待。
const _timeout = Duration(seconds: 12);

/// 拉取最新汇率表，`rate[code]` = 1 单位 code 折合 CNY 的数量
/// （口径与 [CurrencyService] 一致，如 `rate['USD'] = 7.15` 表示 1 美元 = 7.15 元）。
///
/// 请求失败 / 响应异常 / 无可用币种均抛 [RateFetchException]。
Future<Map<String, double>> fetchRates() async {
  final quotes = CurrencyService.supportedCodes
      .where((c) => c != _baseCode)
      .join(',');
  final uri = Uri.parse('$_endpoint?base=$_baseCode&quotes=$quotes');
  final http.Response resp;
  try {
    resp = await http.get(uri).timeout(_timeout);
  } catch (e) {
    throw RateFetchException('请求汇率服务失败：$e');
  }
  if (resp.statusCode != 200) {
    throw RateFetchException('汇率服务返回 HTTP ${resp.statusCode}');
  }
  return parseRatesResponse(resp.body);
}

/// 解析 Frankfurter `/v2/rates` 响应，转成本项目口径的汇率表。
///
/// 响应形如（`base=CNY&quotes=USD`）：
/// ```json
/// [{"date":"2026-09-24","base":"CNY","quote":"USD","rate":0.1492}]
/// ```
/// 其中 `rate` 是「1 CNY = 多少 USD」，与本项目「1 单位外币 = 多少 CNY」
/// **正好互为倒数**，故必须取倒数入库——方向写反会让 100 美元折成 14.92 元
/// （上一代同类功能踩过该坑）。只保留 [CurrencyService.supportedCodes] 内的币种。
Map<String, double> parseRatesResponse(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } catch (e) {
    throw RateFetchException('汇率服务返回的内容不是合法 JSON：$e');
  }
  if (decoded is! List) {
    throw const RateFetchException('汇率服务返回的 JSON 不是数组结构');
  }

  final supported = CurrencyService.supportedCodes.toSet();
  final result = <String, double>{};
  final rejected = <String>[];
  for (final item in decoded) {
    if (item is! Map) {
      rejected.add('$item(格式错误)');
      continue;
    }
    final code = item['quote'];
    final value = item['rate'];
    if (code is! String || code == _baseCode || !supported.contains(code)) {
      rejected.add('$code(未知币种)');
      continue;
    }
    if (value is! num || !value.isFinite || value <= 0) {
      rejected.add('$code($value)');
      continue;
    }
    result[code] = 1 / value;
  }

  if (result.isEmpty) {
    throw RateFetchException(
      '没有取到任何可用汇率${rejected.isEmpty ? '' : '：${rejected.join('、')}'}',
    );
  }
  return result;
}

/// 「上次更新时间」持久化键。
const _lastUpdatedKey = 'currency_rate_last_updated_at';

/// 上次一键更新汇率**生效**的时间。
///
/// 记录的是用户点「确认更新」并写入成功的时间，而非拉取时间；从未更新过为 null。
class RateLastUpdatedNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastUpdatedKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// 用户确认且汇率写入成功后调用，把「现在」记为生效时间。
  Future<void> markNow() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastUpdatedKey, now.millisecondsSinceEpoch);
    state = AsyncData(now);
  }
}

/// 上次汇率更新时间（null = 尚未更新过）。
final rateLastUpdatedProvider =
    AsyncNotifierProvider<RateLastUpdatedNotifier, DateTime?>(
      RateLastUpdatedNotifier.new,
    );
