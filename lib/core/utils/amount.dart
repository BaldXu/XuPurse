/// 金额单位红线：内部一律使用整数「万分之元」（1 元 = 10000）。
///
/// - 三方数据库原始单位为「元」（可能带小数），导入时 [yuanToAmount] 无损转换。
/// - UI 显示用 [amountToYuan] / [formatYuan]，存储一律整数。
/// - 任何 Service / Repository 的金额入参出参均为万分之元整数。
library;

/// 元 → 万分之元（四舍五入，无损）
int yuanToAmount(num yuan) => (yuan * 10000).round();

/// 万分之元 → 元（double，仅用于展示层）
double amountToYuan(int amount) => amount / 10000;

/// 格式化万分之元为显示字符串（默认两位小数）
String formatYuan(int amount, {int fractionDigits = 2}) {
  final yuan = amountToYuan(amount);
  return yuan.toStringAsFixed(fractionDigits);
}

/// 解析用户输入的金额文本（如 "12.50"、"12"）→ 万分之元；非法输入返回 null。
int? parseYuanInput(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  final v = double.tryParse(text);
  if (v == null || v.isNaN || v.isInfinite) return null;
  return yuanToAmount(v);
}

/// 按 [percent]（0-100）计算万分之元金额的比例（结果向下取整）
int amountPercent(int amount, num percent) => (amount * percent / 100).floor();
