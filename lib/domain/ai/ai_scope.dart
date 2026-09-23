import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 数据范围：时间范围档位。
enum AiScopeRange {
  m1('近1个月', 30),
  m3('近3个月', 90),
  m6('近6个月', 180),
  y1('近1年', 365),
  all('全部', 0);

  const AiScopeRange(this.label, this.days);

  /// 展示文案。
  final String label;

  /// 覆盖最近 N 天；0 = 全部（从最早账单起）。
  final int days;

  static AiScopeRange fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => AiScopeRange.m6);
}

/// AI 统计摘要的数据范围配置。
///
/// 控制聊天时自动附带的本机统计摘要包含哪些数据（聚合口径，无单笔明细）。
/// 持久化到 SharedPreferences，一次设置全局生效。
class AiScope {
  const AiScope({
    required this.enabled,
    required this.range,
    required this.includeAssets,
    required this.includeIncomeExpense,
    required this.includeCategories,
    required this.categoryTopN,
    required this.includeTags,
    required this.includeRemarks,
  });

  /// 总开关：关闭后完全不给 AI 读取本机数据（纯聊天）。
  final bool enabled;

  /// 时间范围档位。
  final AiScopeRange range;

  /// 是否允许读取资产情况（账户余额 + 资产趋势）。
  final bool includeAssets;

  /// 是否允许读取收支情况（收支汇总 + 按月趋势 + 预算执行）。
  final bool includeIncomeExpense;

  /// 是否允许读取分类 Top N。
  final bool includeCategories;

  /// 分类 Top N 的 N（10 / 20）。
  final int categoryTopN;

  /// 是否允许读取账单标签排行（涉及隐私，默认关闭）。
  final bool includeTags;

  /// 是否允许读取账单备注排行（涉及隐私，默认关闭）。
  final bool includeRemarks;

  /// 默认模板（除涉及隐私的标签/备注外全开）。
  static const AiScope defaultScope = AiScope(
    enabled: true,
    range: AiScopeRange.m6,
    includeAssets: true,
    includeIncomeExpense: true,
    includeCategories: true,
    categoryTopN: 10,
    includeTags: false,
    includeRemarks: false,
  );

  AiScope copyWith({
    bool? enabled,
    AiScopeRange? range,
    bool? includeAssets,
    bool? includeIncomeExpense,
    bool? includeCategories,
    int? categoryTopN,
    bool? includeTags,
    bool? includeRemarks,
  }) => AiScope(
    enabled: enabled ?? this.enabled,
    range: range ?? this.range,
    includeAssets: includeAssets ?? this.includeAssets,
    includeIncomeExpense: includeIncomeExpense ?? this.includeIncomeExpense,
    includeCategories: includeCategories ?? this.includeCategories,
    categoryTopN: categoryTopN ?? this.categoryTopN,
    includeTags: includeTags ?? this.includeTags,
    includeRemarks: includeRemarks ?? this.includeRemarks,
  );

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'range': range.name,
    'includeAssets': includeAssets,
    'includeIncomeExpense': includeIncomeExpense,
    'includeCategories': includeCategories,
    'categoryTopN': categoryTopN,
    'includeTags': includeTags,
    'includeRemarks': includeRemarks,
  };

  @override
  bool operator ==(Object other) =>
      other is AiScope &&
      other.enabled == enabled &&
      other.range == range &&
      other.includeAssets == includeAssets &&
      other.includeIncomeExpense == includeIncomeExpense &&
      other.includeCategories == includeCategories &&
      other.categoryTopN == categoryTopN &&
      other.includeTags == includeTags &&
      other.includeRemarks == includeRemarks;

  @override
  int get hashCode => Object.hash(
    enabled,
    range,
    includeAssets,
    includeIncomeExpense,
    includeCategories,
    categoryTopN,
    includeTags,
    includeRemarks,
  );

  static AiScope fromJson(Map<String, Object?> json) => AiScope(
    enabled: json['enabled'] as bool? ?? defaultScope.enabled,
    range: AiScopeRange.fromName(json['range'] as String?),
    includeAssets: json['includeAssets'] as bool? ?? defaultScope.includeAssets,
    includeIncomeExpense:
        json['includeIncomeExpense'] as bool? ??
        defaultScope.includeIncomeExpense,
    includeCategories:
        json['includeCategories'] as bool? ?? defaultScope.includeCategories,
    categoryTopN: json['categoryTopN'] as int? ?? defaultScope.categoryTopN,
    includeTags: json['includeTags'] as bool? ?? false,
    includeRemarks: json['includeRemarks'] as bool? ?? false,
  );
}

/// AI 数据范围状态，持久化到 SharedPreferences。
///
/// 仿 [AiConfigNotifier] 模式：`init()` 在 main 启动时调用，之后所有读取
/// 走内存态，变更先写内存再持久化。
final aiScopeProvider = NotifierProvider<AiScopeNotifier, AiScope>(
  AiScopeNotifier.new,
);

class AiScopeNotifier extends Notifier<AiScope> {
  static const _key = 'ai_scope';

  static SharedPreferences? _prefs;

  /// main 启动时调用（与 AiConfigNotifier.init 同模式）。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  AiScope build() {
    final raw = _prefs?.getString(_key);
    if (raw == null || raw.isEmpty) return AiScope.defaultScope;
    try {
      return AiScope.fromJson((jsonDecode(raw) as Map).cast<String, Object?>());
    } catch (_) {
      return AiScope.defaultScope;
    }
  }

  Future<void> _persist(AiScope next) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_key, jsonEncode(next.toJson()));
  }

  /// 保存新范围（确认后调用）。
  Future<void> save(AiScope scope) async {
    state = scope;
    await _persist(scope);
  }

  /// 恢复默认模板。
  Future<void> reset() => save(AiScope.defaultScope);
}
