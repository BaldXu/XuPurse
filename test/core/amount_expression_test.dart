import 'package:flutter_test/flutter_test.dart';
import 'package:xupurse/core/utils/amount_expression.dart';

void main() {
  group('evaluateAmountExpression（键盘四则运算求值）', () {
    test('纯数字等价于直接输入', () {
      expect(evaluateAmountExpression('12'), 120000);
      expect(evaluateAmountExpression('12.5'), 125000);
      expect(evaluateAmountExpression('0.01'), 100);
    });

    test('加减乘除基本运算', () {
      expect(evaluateAmountExpression('12+3'), 150000);
      expect(evaluateAmountExpression('12−3'), 90000);
      expect(evaluateAmountExpression('12×3'), 360000);
      expect(evaluateAmountExpression('12÷3'), 40000);
    });

    test('先乘除后加减', () {
      // 12.5 + 3 × 2 = 18.5
      expect(evaluateAmountExpression('12.5+3×2'), 185000);
      // 2 + 10 ÷ 4 = 4.5
      expect(evaluateAmountExpression('2+10÷4'), 45000);
      // 1 − 2 × 3 = −5
      expect(evaluateAmountExpression('1−2×3'), -50000);
    });

    test('末尾悬挂运算符按省略处理（边输入边预览）', () {
      expect(evaluateAmountExpression('12+'), 120000);
      expect(evaluateAmountExpression('12+3×'), 150000);
      expect(evaluateAmountExpression('12.'), 120000);
    });

    test('ASCII 减号与 U+2212 等价', () {
      expect(evaluateAmountExpression('10-4'), 60000);
      expect(evaluateAmountExpression('10−4'), 60000);
    });

    test('浮点误差被四舍五入吸收', () {
      // 0.1 + 0.2 = 0.30000000000000004
      expect(evaluateAmountExpression('0.1+0.2'), 3000);
      expect(evaluateAmountExpression('0.3−0.1'), 2000);
    });

    test('非法表达式返回 null', () {
      expect(evaluateAmountExpression(''), isNull);
      expect(evaluateAmountExpression('+'), isNull);
      expect(evaluateAmountExpression('12++3'), isNull);
      expect(evaluateAmountExpression('12+×3'), isNull);
      expect(evaluateAmountExpression('abc'), isNull);
      expect(evaluateAmountExpression('12..3+1'), isNull);
    });

    test('除零返回 null', () {
      expect(evaluateAmountExpression('5÷0'), isNull);
      expect(evaluateAmountExpression('5÷0.00'), isNull);
    });
  });

  group('hasAmountOperator / lastAmountOperand', () {
    test('识别运算符', () {
      expect(hasAmountOperator('12'), isFalse);
      expect(hasAmountOperator('12.'), isFalse);
      expect(hasAmountOperator('12+'), isTrue);
      expect(hasAmountOperator('12×3'), isTrue);
    });

    test('取最后一段操作数（数字键限制只作用于这一段）', () {
      expect(lastAmountOperand('12'), '12');
      expect(lastAmountOperand('12+'), '');
      expect(lastAmountOperand('12+34'), '34');
      expect(lastAmountOperand('12×3.5'), '3.5');
      expect(lastAmountOperand('1+2×'), '');
    });
  });

  group('parseAmountInput（保存/预览统一入口）', () {
    test('纯数字与 parseYuanInput 一致', () {
      expect(parseAmountInput('12.5'), 125000);
      expect(parseAmountInput(''), isNull);
    });

    test('算式折叠成金额', () {
      expect(parseAmountInput('12.5+3×2'), 185000);
      expect(parseAmountInput('5÷0'), isNull);
    });
  });
}
