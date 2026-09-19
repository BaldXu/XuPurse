import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/state/theme_provider.dart';
import 'package:xupurse/ui/pages/theme_settings_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    await ThemeNotifier.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ThemeSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> ensureVisible(WidgetTester tester, Finder finder) async {
    // 页面加了「外观定制」区块后内容更长:
    // 元素未挂载时在 ListView 上双向滚动查找(先下后上,位置未知)
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    final list = find.byType(ListView).first;
    for (var i = 0; i < 10 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -300));
      await tester.pumpAndSettle();
    }
    for (var i = 0; i < 10 && finder.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, 300));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('点按预设主题可切换', (tester) async {
    final container = await pumpPage(tester);
    expect(container.read(themeProvider).current.id, presetThemes.first.id);

    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_ball_preset_blue')),
    );
    await tester.tap(find.byKey(const ValueKey('theme_ball_preset_blue')));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider).current.id, 'preset_blue');
    expect(
      container.read(currentThemeProvider).seedColor,
      presetThemes[1].seedColor,
    );
  });

  testWidgets('自定义主题：输入名称保存后新增并应用', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await ensureVisible(tester, find.text('保存为预设主题'));
    await tester.tap(find.text('保存为预设主题'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.userThemes, hasLength(1));
    expect(state.userThemes.single.name, '我的主题');
    expect(state.current.id, state.userThemes.single.id, reason: '保存后自动应用');
  });

  testWidgets('长按用户自建主题出现减号，确认后删除；内置预设长按不出现', (tester) async {
    final container = await pumpPage(tester);

    // 新增一个用户主题
    await ensureVisible(tester, find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await ensureVisible(tester, find.text('保存为预设主题'));
    await tester.tap(find.text('保存为预设主题'));
    await tester.pumpAndSettle();
    final userThemeId = container.read(themeProvider).current.id;
    expect(userThemeId, startsWith('user_'));

    // 先切回内置预设（用户主题不再当前，才允许删除）
    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_ball_preset_green')),
    );
    await tester.tap(find.byKey(const ValueKey('theme_ball_preset_green')));
    await tester.pumpAndSettle();

    // 内置预设长按不出现减号
    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_ball_preset_klein')),
    );
    await tester.longPress(
      find.byKey(const ValueKey('theme_ball_preset_klein')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.remove), findsNothing);

    // 用户主题长按出现减号 → 点击 → 确认删除
    await ensureVisible(
      tester,
      find.byKey(ValueKey('theme_ball_$userThemeId')),
    );
    await tester.longPress(find.byKey(ValueKey('theme_ball_$userThemeId')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.remove), findsOneWidget);

    await ensureVisible(tester, find.byKey(ValueKey('theme_del_$userThemeId')));
    await tester.tap(find.byKey(ValueKey('theme_del_$userThemeId')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider).userThemes, isEmpty);
  });

  testWidgets('当前使用中的用户主题不可删除（长按不出现减号）', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await ensureVisible(tester, find.text('保存为预设主题'));
    await tester.tap(find.text('保存为预设主题'));
    await tester.pumpAndSettle();
    final userThemeId = container.read(themeProvider).current.id;

    // 当前即用户主题 → 长按不进入删除态
    await ensureVisible(
      tester,
      find.byKey(ValueKey('theme_ball_$userThemeId')),
    );
    await tester.longPress(find.byKey(ValueKey('theme_ball_$userThemeId')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('点击颜色项打开取色器，滑动色相并确认后写回该颜色项', (tester) async {
    final container = await pumpPage(tester);
    // 初始：主题色/页面背景/卡片背景 均非「默认」的有 0 个（背景、卡片为默认）
    expect(find.text('默认'), findsNWidgets(2));

    // 点击「页面背景色」行 → 打开取色器
    await ensureVisible(tester, find.text('页面背景色'));
    await tester.tap(find.text('页面背景色'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('color_picker_sv_panel')),
      findsOneWidget,
      reason: '取色器弹窗应出现',
    );

    // 滑动色相条（模拟取色），点确认
    await tester.drag(
      find.byKey(const ValueKey('color_picker_hue_bar')),
      const Offset(150, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();

    // 页面背景色已写回（不再是「默认」），只剩卡片背景为默认
    expect(find.text('默认'), findsOneWidget);
    expect(container.read(themeProvider).current.id, presetThemes.first.id);
  });
}
