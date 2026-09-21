import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/state/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('自定义主题新增→重启后完整还原（id/名称/三色）', () async {
    await ThemeNotifier.init();
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);

    await c1
        .read(themeProvider.notifier)
        .addUserTheme(
          const AppTheme(
            id: 'user_t1',
            name: '我的主题',
            seedColor: Color(0xFF123456),
            background: Color(0xFFE8E8E8),
            cardColor: Color(0xFFFFF3E0),
          ),
        );
    expect(c1.read(themeProvider).current.id, 'user_t1');

    // 模拟重启：新容器 + 重新 init（静态缓存重读 mock prefs）
    await ThemeNotifier.init();
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);

    final s2 = c2.read(themeProvider);
    expect(s2.current.id, 'user_t1', reason: '重启后应还原到用户主题');
    final t = s2.current;
    expect(t.name, '我的主题');
    expect(t.seedColor, const Color(0xFF123456));
    expect(t.background, const Color(0xFFE8E8E8));
    expect(t.cardColor, const Color(0xFFFFF3E0));
  });

  test('选择预设主题→重启后还原为预设', () async {
    await ThemeNotifier.init();
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    await c1.read(themeProvider.notifier).select('preset_klein');

    await ThemeNotifier.init();
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    expect(c2.read(themeProvider).current.id, 'preset_klein');
  });

  test('原地更新用户主题后重启，颜色为更新后的值', () async {
    await ThemeNotifier.init();
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    await c1
        .read(themeProvider.notifier)
        .addUserTheme(
          const AppTheme(
            id: 'user_t1',
            name: '我的主题',
            seedColor: Color(0xFF123456),
          ),
        );
    final cur = c1.read(themeProvider).current;
    await c1
        .read(themeProvider.notifier)
        .updateCurrentTheme(
          cur.copyWith(),
        );
    final updated = AppTheme(
      id: cur.id,
      name: '改名',
      seedColor: const Color(0xFF654321),
      background: null,
      cardColor: null,
    );
    await c1.read(themeProvider.notifier).updateCurrentTheme(updated);

    await ThemeNotifier.init();
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final t = c2.read(themeProvider).current;
    expect(t.id, 'user_t1');
    expect(t.name, '改名');
    expect(t.seedColor, const Color(0xFF654321));
  });
}
