import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AI 数据模式。
///
/// - [summary]：只给 AI 聚合统计摘要（默认，低隐私）。
/// - [detail]：给 AI 逐笔明细 JSON（高隐私，需单独确认）。
enum AiDataMode {
  summary('标准'),
  detail('详细');

  const AiDataMode(this.label);

  final String label;

  static AiDataMode fromName(String? name) => values.firstWhere(
    (e) => e.name == name,
    orElse: () => AiDataMode.summary,
  );
}

/// 标准模式：聚合摘要的时间范围档位。
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

/// 详细模式：逐笔明细的时间范围档位。
enum AiAnalysisRange {
  thisMonth('本月'),
  lastMonth('上月'),
  last3Months('近3月'),
  custom('自定义');

  const AiAnalysisRange(this.label);

  final String label;

  static AiAnalysisRange fromName(String? name) => values.firstWhere(
    (e) => e.name == name,
    orElse: () => AiAnalysisRange.thisMonth,
  );
}

/// AI 数据范围配置（一次设置全局生效）。
///
/// 标准模式沿用原有聚合摘要开关；详细模式只关心时间范围与是否附带备注。
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
    this.mode = AiDataMode.summary,
    this.detailRange = AiAnalysisRange.thisMonth,
    this.detailCustomStart,
    this.detailCustomEnd,
    this.detailIncludeNotes = false,
    this.detailPrivacyAcked = false,
  });

  /// 当前模式。
  final AiDataMode mode;

  /// 总开关：关闭后完全不给 AI 读取本机数据（纯聊天），仅对标准模式生效。
  final bool enabled;

  /// 标准模式时间范围档位。
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

  /// 详细模式时间档位。
  final AiAnalysisRange detailRange;

  /// 详细模式自定义范围（毫秒，均为当天 00:00）。
  final int? detailCustomStart;
  final int? detailCustomEnd;

  /// 详细模式是否附带备注（会做本地脱敏）。
  final bool detailIncludeNotes;

  /// 详细模式的隐私须知是否已确认（只在首次切到详细模式时弹一次）。
  final bool detailPrivacyAcked;

  /// 默认模板（除涉及隐私的标签/备注外全开；详细模式默认本月、不带备注）。
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

  bool get isDetail => mode == AiDataMode.detail;

  /// 详细模式解析为 `[start, end)` 毫秒区间（end 为开区间）。
  (int, int) resolveDetailRange(DateTime now) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);
    switch (detailRange) {
      case AiAnalysisRange.thisMonth:
        return (
          thisMonthStart.millisecondsSinceEpoch,
          nextMonthStart.millisecondsSinceEpoch,
        );
      case AiAnalysisRange.lastMonth:
        return (
          DateTime(now.year, now.month - 1, 1).millisecondsSinceEpoch,
          thisMonthStart.millisecondsSinceEpoch,
        );
      case AiAnalysisRange.last3Months:
        return (
          DateTime(now.year, now.month - 2, 1).millisecondsSinceEpoch,
          nextMonthStart.millisecondsSinceEpoch,
        );
      case AiAnalysisRange.custom:
        final s = detailCustomStart;
        final e = detailCustomEnd;
        if (s == null || e == null || e < s) {
          return (
            thisMonthStart.millisecondsSinceEpoch,
            nextMonthStart.millisecondsSinceEpoch,
          );
        }
        final endDay = DateTime.fromMillisecondsSinceEpoch(e);
        return (
          s,
          DateTime(endDay.year, endDay.month, endDay.day + 1)
              .millisecondsSinceEpoch,
        );
    }
  }

  AiScope copyWith({
    bool? enabled,
    AiScopeRange? range,
    bool? includeAssets,
    bool? includeIncomeExpense,
    bool? includeCategories,
    int? categoryTopN,
    bool? includeTags,
    bool? includeRemarks,
    AiDataMode? mode,
    AiAnalysisRange? detailRange,
    int? detailCustomStart,
    int? detailCustomEnd,
    bool? detailIncludeNotes,
    bool? detailPrivacyAcked,
  }) => AiScope(
    enabled: enabled ?? this.enabled,
    range: range ?? this.range,
    includeAssets: includeAssets ?? this.includeAssets,
    includeIncomeExpense: includeIncomeExpense ?? this.includeIncomeExpense,
    includeCategories: includeCategories ?? this.includeCategories,
    categoryTopN: categoryTopN ?? this.categoryTopN,
    includeTags: includeTags ?? this.includeTags,
    includeRemarks: includeRemarks ?? this.includeRemarks,
    mode: mode ?? this.mode,
    detailRange: detailRange ?? this.detailRange,
    detailCustomStart: detailCustomStart ?? this.detailCustomStart,
    detailCustomEnd: detailCustomEnd ?? this.detailCustomEnd,
    detailIncludeNotes: detailIncludeNotes ?? this.detailIncludeNotes,
    detailPrivacyAcked: detailPrivacyAcked ?? this.detailPrivacyAcked,
  );

  Map<String, Object?> toJson() => {
    'mode': mode.name,
    'enabled': enabled,
    'range': range.name,
    'includeAssets': includeAssets,
    'includeIncomeExpense': includeIncomeExpense,
    'includeCategories': includeCategories,
    'categoryTopN': categoryTopN,
    'includeTags': includeTags,
    'includeRemarks': includeRemarks,
    'detailRange': detailRange.name,
    'detailIncludeNotes': detailIncludeNotes,
    'detailPrivacyAcked': detailPrivacyAcked,
    if (detailCustomStart != null) 'detailCustomStart': detailCustomStart,
    if (detailCustomEnd != null) 'detailCustomEnd': detailCustomEnd,
  };

  @override
  bool operator ==(Object other) =>
      other is AiScope &&
      other.mode == mode &&
      other.enabled == enabled &&
      other.range == range &&
      other.includeAssets == includeAssets &&
      other.includeIncomeExpense == includeIncomeExpense &&
      other.includeCategories == includeCategories &&
      other.categoryTopN == categoryTopN &&
      other.includeTags == includeTags &&
      other.includeRemarks == includeRemarks &&
      other.detailRange == detailRange &&
      other.detailCustomStart == detailCustomStart &&
      other.detailCustomEnd == detailCustomEnd &&
      other.detailIncludeNotes == detailIncludeNotes &&
      other.detailPrivacyAcked == detailPrivacyAcked;

  @override
  int get hashCode => Object.hash(
    mode,
    enabled,
    range,
    includeAssets,
    includeIncomeExpense,
    includeCategories,
    categoryTopN,
    includeTags,
    includeRemarks,
    detailRange,
    detailCustomStart,
    detailCustomEnd,
    detailIncludeNotes,
    detailPrivacyAcked,
  );

  static AiScope fromJson(Map<String, Object?> json) => AiScope(
    mode: AiDataMode.fromName(json['mode'] as String?),
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
    detailRange: AiAnalysisRange.fromName(json['detailRange'] as String?),
    detailCustomStart: json['detailCustomStart'] as int?,
    detailCustomEnd: json['detailCustomEnd'] as int?,
    detailIncludeNotes: json['detailIncludeNotes'] as bool? ?? false,
    detailPrivacyAcked: json['detailPrivacyAcked'] as bool? ?? false,
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
