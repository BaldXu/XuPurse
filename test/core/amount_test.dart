import 'package:flutter_test/flutter_test.dart';
import 'package:xupurse/core/utils/amount.dart';

void main() {
  group('yuanToAmount（元 → 万分之元）', () {
    test('整数元', () {
      expect(yuanToAmount(12), 120000);
    });

    test('两位小数', () {
      expect(yuanToAmount(12.5), 125000);
      expect(yuanToAmount(0.1), 1000);
    });

    test('浮点精度无损（round 处理）', () {
      // 1.005 * 10000 = 10050.000000000002
      expect(yuanToAmount(1.005), 10050);
      // 0.29 * 10000 = 2900.0000000000005
      expect(yuanToAmount(0.29), 2900);
      // 19.99 * 10000 = 199900.00000000003
      expect(yuanToAmount(19.99), 199900);
    });

    test('负数（退款/冲正）', () {
      expect(yuanToAmount(-3.2), -32000);
    });

    test('零', () {
      expect(yuanToAmount(0), 0);
    });
  });

  group('amountToYuan / formatYuan', () {
    test('还原为元', () {
      expect(amountToYuan(125000), 12.5);
      expect(amountToYuan(0), 0);
    });

    test('格式化两位小数', () {
      expect(formatYuan(125000), '12.50');
      expect(formatYuan(123456789), '12345.68');
      expect(formatYuan(-500), '-0.05');
    });

    test('四位小数精度保留', () {
      expect(formatYuan(12345, fractionDigits: 4), '1.2345');
    });
  });

  group('parseYuanInput', () {
    test('合法输入', () {
      expect(parseYuanInput('12.50'), 125000);
      expect(parseYuanInput('12'), 120000);
      expect(parseYuanInput(' 12 '), 120000);
      expect(parseYuanInput('.5'), 5000);
      expect(parseYuanInput('-3.2'), -32000);
    });

    test('非法输入返回 null', () {
      expect(parseYuanInput(''), isNull);
      expect(parseYuanInput('   '), isNull);
      expect(parseYuanInput('abc'), isNull);
      expect(parseYuanInput('12.3.4'), isNull);
    });
  });

  test('amountPercent', () {
    expect(amountPercent(1000000, 10), 100000);
    expect(amountPercent(999, 50), 499); // 向下取整
    expect(amountPercent(1000000, 0), 0);
    expect(amountPercent(1000000, 100), 1000000);
  });
}
