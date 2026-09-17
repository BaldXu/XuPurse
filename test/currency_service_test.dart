import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/domain/services/currency_service.dart';
import 'package:xupurse/state/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('内置汇率表以 CNY 为锚（rate[CNY] = 1）', () {
    expect(CurrencyService.builtinRates['CNY'], 1.0);
    expect(CurrencyService.builtinRates['USD'], isNotNull);
    expect(CurrencyService.supportedCodes, contains('USD'));
  });

  test('换算公式：amount × rate[to] / rate[from]', () {
    const rates = {'CNY': 1.0, 'USD': 7.2, 'EUR': 7.8};
    // 100 美元 → 人民币
    expect(convertAmount(1000000, 'USD', 'CNY', rates), 7200000);
    // 7200 人民币 → 美元（反向）
    expect(convertAmount(7200000, 'CNY', 'USD', rates), 1000000);
    // 外币互转：100 美元 → 欧元 = 100 × 7.2 / 7.8 元等值
    expect(
      convertAmount(1000000, 'USD', 'EUR', rates),
      (100 * 7.2 / 7.8 * 10000).round(),
    );
    // 同币种不折算
    expect(convertAmount(123456, 'USD', 'USD', rates), 123456);
    // 零值
    expect(convertAmount(0, 'USD', 'CNY', rates), 0);
  });

  test('CurrencyService 手动覆盖汇率并持久化', () async {
    await CurrencyService.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(currencyServiceProvider.notifier);

    // 内置 USD 7.2
    expect(container.read(currencyServiceProvider)['USD'], 7.2);

    // 覆盖 USD = 7.0
    await service.setOverride('USD', 7.0);
    expect(container.read(currencyServiceProvider)['USD'], 7.0);

    // 清除覆盖恢复内置
    await service.setOverride('USD', 0);
    expect(container.read(currencyServiceProvider)['USD'], 7.2);

    // 未知币种兜底 1.0
    expect(service.rateOf('XXX'), 1.0);
  });

  test('convert 使用覆盖后的汇率', () async {
    await CurrencyService.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(currencyServiceProvider.notifier);

    await service.setOverride('USD', 7.0);
    expect(service.convert(1000000, 'USD', 'CNY'), 7000000);
  });
}
