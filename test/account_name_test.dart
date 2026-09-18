import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/utils/account_name.dart';

void main() {
  group('normalizeAccountName', () {
    test('去括号内容、空格、卡号尾号，统一小写', () {
      expect(normalizeAccountName('支付宝（尾号1234）'), '支付宝');
      expect(normalizeAccountName(' 中国银行 - 港币 '), '中国银行-港币');
      expect(normalizeAccountName('招商银行 尾号8888'), '招商银行');
      expect(normalizeAccountName('ABC ****1234'), 'abc');
    });
  });

  group('accountNameSimilarity', () {
    test('归一化后完全相同 → 1.0', () {
      expect(accountNameSimilarity('微信钱包', '微信钱包'), 1.0);
      expect(accountNameSimilarity('支付宝（尾号1234）', '支付宝'), 1.0);
    });

    test('包含关系 → 0.85（微信 vs 微信钱包）', () {
      expect(accountNameSimilarity('微信', '微信钱包'), 0.85);
      expect(accountNameSimilarity('工商银行', '工商银行信用卡'), 0.85);
    });

    test('无关账户 → 0', () {
      expect(accountNameSimilarity('微信钱包', '招商银行'), 0);
    });

    test('公共子串 → 0 ~ 0.84', () {
      final s = accountNameSimilarity('中国银行港币', '港币现金');
      expect(s, greaterThan(0));
      expect(s, lessThan(0.85));
    });
  });
}
