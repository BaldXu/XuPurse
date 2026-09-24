import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/state/icon_pack_provider.dart';
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
    await c1.read(themeProvider.notifier).updateCurrentTheme(cur.copyWith());
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

  test('主题级图标/磨砂/转场覆盖持久化，重启后还原', () async {
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
            iconPack: IconPack.twemoji,
            frosted: FrostedState(
              enabled: true,
              appBar: true,
              card: false,
              sheet: true,
            ),
            transitionBlur: false,
          ),
        );

    await ThemeNotifier.init();
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final t = c2.read(themeProvider).current;
    expect(t.iconPack, IconPack.twemoji);
    expect(t.transitionBlur, isFalse);
    expect(t.frosted, isNotNull);
    expect(t.frosted!.enabled, isTrue);
    expect(t.frosted!.appBar, isTrue);
    expect(t.frosted!.sheet, isTrue);
  });

  test('派生 provider：主题级覆盖优先，未设置时兜底全局值', () async {
    await ThemeNotifier.init();
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    // 全局兜底设 twemoji + 关闭转场
    await c1.read(legacyIconPackProvider.notifier).set(IconPack.twemoji);
    await c1.read(legacyTransitionBlurProvider.notifier).set(false);
    await c1.read(legacyFrostedGlassProvider.notifier).setEnabled(true);

    // 内置预设未配置 → 生效值 = 全局兜底
    expect(c1.read(iconPackProvider), IconPack.twemoji);
    expect(c1.read(transitionBlurProvider), isFalse);
    expect(c1.read(frostedGlassProvider).enabled, isTrue);

    // 新建自定义主题并设置主题级覆盖 → 生效值 = 主题级
    await c1
        .read(themeProvider.notifier)
        .addUserTheme(
          const AppTheme(
            id: 'user_t1',
            name: '我的主题',
            seedColor: Color(0xFF123456),
            iconPack: IconPack.minimal,
            transitionBlur: true,
          ),
        );
    expect(c1.read(iconPackProvider), IconPack.minimal);
    expect(c1.read(transitionBlurProvider), isTrue);
    expect(c1.read(themeProvider).current.frosted, isNull);
    expect(
      c1.read(frostedGlassProvider).enabled,
      isTrue,
      reason: '主题未配置磨砂时仍兜底全局值',
    );
  });

  test('亮度兜底清理深色背景时保留 v4 主题级覆盖字段', () async {
    await ThemeNotifier.init();
    final c1 = ProviderContainer();
    addTearDown(c1.dispose);
    await c1.read(themeProvider.notifier).addUserTheme(
      const AppTheme(
        id: 'user_t1',
        name: '我的主题',
        seedColor: Color(0xFF123456),
        background: Color(0xFF050505), // 近黑，加载时触发亮度兜底
        iconPack: IconPack.twemoji,
        frosted: FrostedState(
          enabled: true,
          appBar: true,
          card: false,
          sheet: true,
        ),
        transitionBlur: false,
      ),
    );

    await ThemeNotifier.init();
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    final t = c2.read(themeProvider).current;
    expect(t.id, 'user_t1');
    expect(t.background, isNull, reason: '近黑背景被亮度兜底清空');
    expect(t.iconPack, IconPack.twemoji, reason: 'v4 覆盖不得被兜底清空');
    expect(t.transitionBlur, isFalse);
    expect(t.frosted, isNotNull);
    expect(t.frosted!.enabled, isTrue);
  });
}
