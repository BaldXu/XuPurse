import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/domain/services/currency_service.dart';
import 'package:xupurse/domain/services/exchange_rate_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('解析响应时取倒数：rate 语义是「1 CNY = 多少外币」', () {
    // 实测 api.frankfurter.dev/v2/rates?base=CNY&quotes=USD 返回 0.1492
    final rates = parseRatesResponse(
      '[{"date":"2026-09-24","base":"CNY","quote":"USD","rate":0.1492}]',
    );
    // 1 美元 ≈ 6.70 元
    expect(rates['USD'], closeTo(6.7024, 0.001));
  });

  test('100 美元折算约 670 元（防范方向写反的历史坑）', () {
    final rates = parseRatesResponse(
      '[{"date":"2026-09-24","base":"CNY","quote":"USD","rate":0.1492}]',
    );
    final withBase = {...rates, 'CNY': 1.0};
    // 100 元 = 1_000_000（万分之元）→ 100 美元 ≈ 670 元；方向写反约 14.92 元
    expect(
      convertAmount(1000000, 'USD', 'CNY', withBase),
      closeTo(6702400, 100),
    );
  });

  test('只保留支持币种，忽略未知币种与本币', () {
    final rates = parseRatesResponse(
      '['
      '{"date":"2026-09-24","base":"CNY","quote":"USD","rate":0.1492},'
      '{"date":"2026-09-24","base":"CNY","quote":"XXX","rate":1.5},'
      '{"date":"2026-09-24","base":"CNY","quote":"CNY","rate":1.0}'
      ']',
    );
    expect(rates.keys, ['USD']);
  });

  test('非法值被过滤', () {
    final rates = parseRatesResponse(
      '['
      '{"date":"2026-09-24","base":"CNY","quote":"USD","rate":0.1492},'
      '{"date":"2026-09-24","base":"CNY","quote":"EUR","rate":0},'
      '{"date":"2026-09-24","base":"CNY","quote":"JPY","rate":-1}'
      ']',
    );
    expect(rates.keys, ['USD']);
  });

  test('JSON 非法 / 结构错误 / 无可用币种均抛 RateFetchException', () {
    expect(
      () => parseRatesResponse('not json'),
      throwsA(isA<RateFetchException>()),
    );
    expect(
      () => parseRatesResponse('{"rate":1}'),
      throwsA(isA<RateFetchException>()),
    );
    expect(() => parseRatesResponse('[]'), throwsA(isA<RateFetchException>()));
    expect(
      () => parseRatesResponse(
        '[{"date":"2026-09-24","base":"CNY","quote":"XXX","rate":1.5}]',
      ),
      throwsA(isA<RateFetchException>()),
    );
  });

  test('上次更新时间：初始为空，markNow 后落盘且可跨容器读取', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(rateLastUpdatedProvider.future), isNull);

    await container.read(rateLastUpdatedProvider.notifier).markNow();
    expect(container.read(rateLastUpdatedProvider).value, isNotNull);

    final reopened = ProviderContainer();
    addTearDown(reopened.dispose);
    expect(await reopened.read(rateLastUpdatedProvider.future), isNotNull);
  });
}
