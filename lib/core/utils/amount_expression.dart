/// 金额输入框内的四则运算（键盘上的 `+ − × ÷ =`）。
///
/// 键盘把用户按键拼成一个「表达式」文本（如 `12.5+3×2`），
/// 显示层实时求值预览，保存时再折叠成万分之元整数。
/// 金额红线不变：表达式的求值结果最终仍走 [yuanToAmount]，存储一律整数。
///
/// 只支持不带括号的连续四则运算（先乘除后加减），不引入第三方解析库。
library;

import 'amount.dart';

/// 键盘可输入的运算符（减号用 U+2212，视觉比 ASCII `-` 更居中）。
const List<String> amountOperators = ['+', '−', '×', '÷'];

/// 是否为运算符字符（同时兼容 ASCII 减号 `-`，便于外部输入/测试）。
bool isAmountOperatorChar(String c) =>
    c == '+' || c == '-' || c == '−' || c == '×' || c == '÷';

/// 表达式是否含运算符（决定是否显示「= 结果」）。
bool hasAmountOperator(String expr) {
  for (var i = 0; i < expr.length; i++) {
    if (isAmountOperatorChar(expr[i])) return true;
  }
  return false;
}

/// 表达式最后一段操作数。
///
/// 数字键 / 小数点 / `00` 的输入限制（整数 9 位、小数 2 位）只作用于这一段，
/// 前面的算式部分原样保留。
String lastAmountOperand(String expr) {
  for (var i = expr.length - 1; i >= 0; i--) {
    if (isAmountOperatorChar(expr[i])) return expr.substring(i + 1);
  }
  return expr;
}

/// 求值表达式 → 万分之元整数；非法 / 除零 / 结果非有限 → null。
///
/// 末尾悬挂的运算符按省略处理（`'12+'` → 12），便于用户边输入边看预览，
/// 也让「算式还没打完就直接点确认」不会报「请输入有效金额」。
int? evaluateAmountExpression(String expr) {
  final text = expr.trim();
  if (text.isEmpty) return null;
  var end = text.length;
  while (end > 0 && isAmountOperatorChar(text[end - 1])) {
    end--;
  }
  if (end == 0) return null;
  final src = text.substring(0, end);

  // 词法切分：数字 运算符 数字 ...
  final numbers = <double>[];
  final ops = <String>[];
  var start = 0;
  for (var i = 0; i < src.length; i++) {
    if (!isAmountOperatorChar(src[i])) continue;
    if (i == start) return null; // 连续运算符 / 以运算符开头
    final value = double.tryParse(src.substring(start, i));
    if (value == null || !value.isFinite) return null;
    numbers.add(value);
    ops.add(src[i] == '-' ? '−' : src[i]);
    start = i + 1;
  }
  final tail = double.tryParse(src.substring(start));
  if (tail == null || !tail.isFinite) return null;
  numbers.add(tail);

  // 两趟求值：先乘除（折叠成一个「项」），再加减。
  var sum = 0.0;
  var term = numbers.first;
  var sign = 1.0;
  for (var i = 0; i < ops.length; i++) {
    final rhs = numbers[i + 1];
    switch (ops[i]) {
      case '×':
        term *= rhs;
      case '÷':
        if (rhs == 0) return null; // 除零视为非法输入
        term /= rhs;
      case '+':
        sum += sign * term;
        sign = 1;
        term = rhs;
      default: // '−'（'-' 已在切分时归一化）
        sum += sign * term;
        sign = -1;
        term = rhs;
    }
  }
  sum += sign * term;
  if (!sum.isFinite) return null;
  // double 误差（0.1+0.2）由 yuanToAmount 的 round 吸收。
  return yuanToAmount(sum);
}

/// 解析键盘输入 → 万分之元；非法返回 null。
///
/// 含运算符时求值，纯数字时等价于 [parseYuanInput]。
/// 保存校验与金额预览统一走这里，避免表达式被当成非法金额。
int? parseAmountInput(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  if (!hasAmountOperator(text)) return parseYuanInput(text);
  return evaluateAmountExpression(text);
}
