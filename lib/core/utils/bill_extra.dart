import 'dart:convert';

/// 账单扩展字段（存 bills.extra JSON）。
///
/// 布尔标记决定账单在余额重算中的跳过行为（见 docs/algorithms.md 算法三）。
class BillExtra {
  const BillExtra({
    this.isAdjustment = false,
    this.isYimu = false,
    this.isZhouhu = false,
    this.isQianji = false,
    this.excludeFromStats = false,
    this.other = const {},
  });

  /// 调账账单（重算时跳过）
  final bool isAdjustment;

  /// 第三方导入来源标记（重算时跳过，余额以第三方权威值为准）
  final bool isYimu;
  final bool isZhouhu;
  final bool isQianji;

  /// 不计入收支：仅记流水与余额，不参与收入/支出统计。
  /// 兼容旧数据 `other.notInTotal`（一木导入历史字段）。
  final bool excludeFromStats;

  /// 其他自由扩展（如关联业务 ID）
  final Map<String, Object?> other;

  factory BillExtra.fromJson(String? json) {
    if (json == null || json.isEmpty) return const BillExtra();
    final map = jsonDecode(json);
    if (map is! Map<String, Object?>) return const BillExtra();
    final other = Map<String, Object?>.from(
      (map['other'] as Map?)?.cast<String, Object?>() ?? const {},
    );
    return BillExtra(
      isAdjustment: map['isAdjustment'] == true,
      isYimu: map['isYimu'] == true,
      isZhouhu: map['isZhouhu'] == true,
      isQianji: map['isQianji'] == true,
      excludeFromStats:
          map['excludeFromStats'] == true || other['notInTotal'] == true,
      other: other,
    );
  }

  String? encode() {
    final hasFlags =
        isAdjustment || isYimu || isZhouhu || isQianji || excludeFromStats;
    if (!hasFlags && other.isEmpty) return null;
    return jsonEncode({
      if (isAdjustment) 'isAdjustment': true,
      if (isYimu) 'isYimu': true,
      if (isZhouhu) 'isZhouhu': true,
      if (isQianji) 'isQianji': true,
      if (excludeFromStats) 'excludeFromStats': true,
      if (other.isNotEmpty) 'other': other,
    });
  }

  /// 是否为导入账单（任一来源标记）
  bool get isImported => isYimu || isZhouhu || isQianji;

  /// 重算时是否跳过该账单
  bool get skipInRecalculate => isAdjustment || isImported;
}
