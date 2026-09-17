import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 多币种服务（docs/algorithms.md 算法四）。
///
/// 汇率口径：`rate[code]` = 1 单位 code 折合多少**本位币（CNY）**，
/// 例如 `rate['USD'] = 7.2` 表示 1 美元 = 7.2 元。
/// 换算公式 `convert(amount, from, to) = amount × rate[from] / rate[to]`。
///
/// 状态 = 当前生效汇率表（内置 + 手动覆盖），覆盖项持久化到 SharedPreferences。
class CurrencyService extends Notifier<Map<String, double>> {
  /// 内置汇率（对 CNY；用户可在汇率设置页手动覆盖）。
  static const Map<String, double> builtinRates = {
    'CNY': 1.0,
    'USD': 7.2,
    'EUR': 7.8,
    'JPY': 0.05,
    'HKD': 0.92,
    'GBP': 9.1,
    'KRW': 0.005,
    'SGD': 5.3,
    'AUD': 4.7,
    'CAD': 5.2,
    'THB': 0.2,
    'TWD': 0.22,
    'MYR': 1.6,
    'INR': 0.086,
    'RUB': 0.08,
  };

  static const _prefsKey = 'currency_rate_overrides';

  /// 支持展示的币种列表（内置表全部键，按名称排序）。
  static List<String> get supportedCodes => builtinRates.keys.toList()..sort();

  @override
  Map<String, double> build() {
    final overrides = _loadOverrides();
    return {...builtinRates, ...overrides};
  }

  Map<String, double> _loadOverrides() {
    // build 为同步方法，从内存缓存读取（main 启动时已 [init] 预热）
    final json = _prefsCache?.getString(_prefsKey);
    if (json == null || json.isEmpty) return {};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 需要同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  /// 当前汇率（未知币种按 1.0 兜底）。
  double rateOf(String code) => state[code] ?? 1.0;

  /// 汇率换算：`amount × rate[to] / rate[from]`（万分之元整数，四舍五入）。
  int convert(int amount, String from, String to) =>
      convertAmount(amount, from, to, state);

  /// 设置手动覆盖汇率；rate <= 0 表示清除覆盖（恢复内置）。
  Future<void> setOverride(String code, double rate) async {
    final overrides = _loadOverrides();
    if (rate <= 0) {
      overrides.remove(code);
    } else {
      overrides[code] = rate;
    }
    await _persist(overrides);
    state = {...builtinRates, ...overrides};
  }

  Future<void> _persist(Map<String, double> overrides) async {
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setString(
      _prefsKey,
      jsonEncode(overrides.map((k, v) => MapEntry(k, v))),
    );
  }

  /// 该币种是否被手动覆盖。
  bool isOverridden(String code) => _loadOverrides().containsKey(code);
}

/// 纯函数汇率换算（docs/algorithms.md 算法四）。
///
/// 口径：`rate[code]` = 1 单位 code 折合本位币（CNY）的数量，例如
/// `rate['USD'] = 7.2` 表示 1 美元 = 7.2 元。
/// 因此 `convert(amount, from, to) = amount × rate[from] / rate[to]`
/// （100 美元 → CNY = 100 × 7.2 / 1 = 720 元；方向反写会得到 13.89 的错误结果）。
int convertAmount(
  int amount,
  String from,
  String to,
  Map<String, double> rates,
) {
  if (amount == 0 || from == to) return amount;
  final fromRate = rates[from] ?? 1.0;
  final toRate = rates[to] ?? 1.0;
  return (amount * fromRate / toRate).round();
}
