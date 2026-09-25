import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/state/theme_provider.dart';
import 'package:xupurse/ui/pages/theme_settings_page.dart';
import 'package:xupurse/ui/widgets/xp_sliding_segmented.dart';

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

  /// 把主题页 push 到宿主路由下（首页 + 进入主题页），用于测返回拦截。
  /// [beforePush] 可在进入页面前预置容器状态（如先选中某个自定义主题）。
  Future<ProviderContainer> pumpPushedPage(
    WidgetTester tester, {
    Future<void> Function(ProviderContainer container)? beforePush,
  }) async {
    await ThemeNotifier.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (beforePush != null) await beforePush(container);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ThemeSettingsPage(),
                    ),
                  ),
                  child: const Text('打开主题页'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开主题页'));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> ensureVisible(WidgetTester tester, Finder finder) async {
    // 页面分区多（画廊 + 编辑器），元素未挂载时在 ListView 上双向滚动查找
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

  testWidgets('内置预设只读但展示真实配色', (tester) async {
    await pumpPage(tester);

    // 顶部编辑器头部即有「复制为自定义主题」
    expect(find.text('复制为自定义主题'), findsOneWidget);

    await ensureVisible(tester, find.text('页面背景色'));
    // 克莱因蓝预设：页面背景 #F7F8F6、卡片 #FFFFFF 直接展示，无需重新配置
    expect(find.text('#F7F8F6'), findsOneWidget);
    expect(find.text('#FFFFFF'), findsOneWidget);
    // 颜色行带锁，只读不可点
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
  });

  testWidgets('点按主题卡可切换主题', (tester) async {
    final container = await pumpPage(tester);
    expect(container.read(themeProvider).current.id, presetThemes.first.id);

    // 新建自定义主题使其成为当前，再点回内置预设
    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider).current.id, startsWith('user_'));

    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_card_preset_klein')),
    );
    await tester.tap(find.byKey(const ValueKey('theme_card_preset_klein')));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider).current.id, 'preset_klein');
    expect(
      container.read(currentThemeProvider).seedColor,
      presetThemes.first.seedColor,
    );
  });

  testWidgets('新建主题：弹窗输入名称后新增并应用', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.userThemes, hasLength(1));
    expect(state.userThemes.single.name, '我的主题');
    expect(state.current.id, state.userThemes.single.id, reason: '新建后自动应用');
  });

  testWidgets('重命名当前自定义主题：弹窗预填原名，确认后原地更新', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '初始主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    final id = container.read(themeProvider).current.id;
    expect(id, startsWith('user_'));

    await ensureVisible(tester, find.text('重命名'));
    await tester.tap(find.text('重命名'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '改名主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.userThemes, hasLength(1), reason: '重命名不应新增主题');
    expect(state.userThemes.single.id, id);
    expect(state.userThemes.single.name, '改名主题');
    expect(state.current.id, id);
  });

  testWidgets('复制内置预设为自定义主题并应用', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.text('复制为自定义主题'));
    await tester.tap(find.text('复制为自定义主题'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.userThemes, hasLength(1));
    expect(state.userThemes.single.name, '克莱因蓝 副本');
    expect(state.current.id, state.userThemes.single.id, reason: '复制后自动应用');
    // 副本保留预设配色
    expect(state.current.background, const Color(0xFFF7F8F6));
  });

  testWidgets('长按用户自建主题出现减号，确认后删除；内置预设长按不出现', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    final userThemeId = container.read(themeProvider).current.id;
    expect(userThemeId, startsWith('user_'));

    // 先切回内置预设（用户主题不再当前，才允许删除）
    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_card_preset_klein')),
    );
    await tester.tap(find.byKey(const ValueKey('theme_card_preset_klein')));
    await tester.pumpAndSettle();

    // 内置预设长按不出现减号
    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_card_preset_klein')),
    );
    await tester.longPress(
      find.byKey(const ValueKey('theme_card_preset_klein')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.remove), findsNothing);

    // 用户主题长按出现减号 → 点击 → 确认删除
    await ensureVisible(
      tester,
      find.byKey(ValueKey('theme_card_$userThemeId')),
    );
    await tester.longPress(find.byKey(ValueKey('theme_card_$userThemeId')));
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

    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    final userThemeId = container.read(themeProvider).current.id;

    // 当前即用户主题 → 长按不进入删除态
    await ensureVisible(
      tester,
      find.byKey(ValueKey('theme_card_$userThemeId')),
    );
    await tester.longPress(find.byKey(ValueKey('theme_card_$userThemeId')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.remove), findsNothing);
  });

  testWidgets('点击颜色项打开取色器，确认后写回当前主题', (tester) async {
    final container = await pumpPage(tester);

    // 先新建自定义主题使其可编辑
    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

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

    // 背景色写回当前主题，行内显示色值
    final theme = container.read(themeProvider).current;
    expect(theme.background, isNotNull, reason: '确认后应写回当前主题');
    final hex =
        '#${theme.background!.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    expect(find.text(hex), findsOneWidget);
  });

  testWidgets('卡片样式用滑块分段组件切换，实时生效', (tester) async {
    final container = await pumpPage(tester);

    // 新建自定义主题使其可编辑
    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await ensureVisible(tester, find.text('卡片样式'));
    expect(find.byType(XpSlidingSegmented<XpCardStyle>), findsOneWidget);
    await tester.tap(find.text('描边'));
    await tester.pumpAndSettle();

    expect(
      container.read(themeProvider).current.cardStyle,
      XpCardStyle.outlined,
    );
  });

  testWidgets('卡片圆角滑动条（5~32）调整并实时生效', (tester) async {
    final container = await pumpPage(tester);

    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    await ensureVisible(tester, find.byType(Slider));
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 5);
    expect(slider.max, 32);

    // 拖动滑条 → 圆角写入主题
    await tester.drag(find.byType(Slider), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider).current.cardRadius, isNotNull);
  });

  testWidgets('未修改直接返回不弹确认', (tester) async {
    final container = await pumpPushedPage(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('保留主题修改？'), findsNothing);
    expect(container.read(themeProvider).current.id, presetThemes.first.id);
  });

  testWidgets('自定义主题为当前且未修改，直接返回不弹确认', (tester) async {
    final container = await pumpPushedPage(
      tester,
      beforePush: (c) async {
        await c
            .read(themeProvider.notifier)
            .addUserTheme(
              const AppTheme(
                id: 'user_a',
                name: '主题A',
                seedColor: Color(0xFF123456),
              ),
            );
        await c.read(themeProvider.notifier).select('user_a');
      },
    );
    expect(container.read(themeProvider).current.id, 'user_a');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('保留主题修改？'), findsNothing);
    expect(container.read(themeProvider).current.id, 'user_a');
  });

  testWidgets('带磨砂配置的主题未修改直接返回不弹确认（回归：嵌套 Map 比较）', (tester) async {
    final container = await pumpPushedPage(
      tester,
      beforePush: (c) async {
        await c
            .read(themeProvider.notifier)
            .addUserTheme(
              const AppTheme(
                id: 'user_frost',
                name: '磨砂主题',
                seedColor: Color(0xFF123456),
                frosted: FrostedState(
                  enabled: true,
                  appBar: true,
                  card: false,
                  sheet: false,
                ),
              ),
            );
        await c.read(themeProvider.notifier).select('user_frost');
      },
    );
    expect(container.read(themeProvider).current.id, 'user_frost');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('保留主题修改？'), findsNothing);
    expect(container.read(themeProvider).current.id, 'user_frost');
  });

  testWidgets('带磨砂主题修改后保存，再返回不弹确认', (tester) async {
    final container = await pumpPushedPage(
      tester,
      beforePush: (c) async {
        await c
            .read(themeProvider.notifier)
            .addUserTheme(
              const AppTheme(
                id: 'user_frost',
                name: '磨砂主题',
                seedColor: Color(0xFF123456),
                frosted: FrostedState(
                  enabled: true,
                  appBar: true,
                  card: false,
                  sheet: false,
                ),
              ),
            );
        await c.read(themeProvider.notifier).select('user_frost');
      },
    );

    // 修改磨砂总开关（关闭 → 产生未保存修改，保存按钮出现）
    final cur = container.read(themeProvider).current;
    container
        .read(themeProvider.notifier)
        .updateCurrentThemeSilent(
          cur.copyWith(
            frosted: const FrostedState(
              enabled: false,
              appBar: true,
              card: false,
              sheet: false,
            ),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('保存'), findsOneWidget);

    // 保存 → 弹确认 → 确认
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('保存主题修改？'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.text('已保存'), findsOneWidget);
    expect(find.text('保存'), findsNothing, reason: '保存后脏状态复位');

    // 保存后返回：不应再弹
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('保留主题修改？'), findsNothing);
  });

  testWidgets('磨砂「恢复默认」置回 null，与进入时一致则不再判脏', (tester) async {
    final container = await pumpPushedPage(
      tester,
      beforePush: (c) async {
        // 主题磨砂跟随全局（frosted 为 null），是「开关开→关再恢复」的典型场景
        await c
            .read(themeProvider.notifier)
            .addUserTheme(
              const AppTheme(
                id: 'user_frost',
                name: '磨砂主题',
                seedColor: Color(0xFF123456),
              ),
            );
        await c.read(themeProvider.notifier).select('user_frost');
      },
    );

    // 用户把磨砂开关开→关（写入显式值，与进入时的 null 不同）→ 产生未保存修改
    final cur = container.read(themeProvider).current;
    container
        .read(themeProvider.notifier)
        .updateCurrentThemeSilent(
          cur.copyWith(
            frosted: const FrostedState(
              enabled: false,
              appBar: true,
              card: false,
              sheet: false,
            ),
          ),
        );
    await tester.pumpAndSettle();
    expect(find.text('保存'), findsOneWidget, reason: '有修改时显示保存');

    // 滚动到磨砂区，点「恢复默认」把 frosted 置回 null（与进入时一致）
    for (var i = 0; i < 8 && find.text('恢复默认').evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
    }
    final restore = find.text('恢复默认');
    expect(restore, findsOneWidget);
    await tester.ensureVisible(restore);
    await tester.tap(restore);
    await tester.pumpAndSettle();

    expect(
      container.read(themeProvider).current.frosted,
      isNull,
      reason: '恢复默认把 frosted 置回 null（跟随全局）',
    );
    expect(find.text('保存'), findsNothing, reason: '与进入时快照一致，不再判脏');

    // 返回不弹确认
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('保留主题修改？'), findsNothing);
  });

  testWidgets('右上角保存后直接返回不弹确认（保存会同步脏状态）', (tester) async {
    final container = await pumpPushedPage(tester);

    // 新建自定义主题（产生未保留的修改，保存按钮出现）
    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    final id = container.read(themeProvider).current.id;
    expect(find.text('保存'), findsOneWidget, reason: '有修改时右上角显示保存');

    // 点右上角保存 → 弹确认 → 点弹窗「保存」
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('保存主题修改？'), findsOneWidget);
    await tester.tap(find.text('保存').last);
    await tester.pumpAndSettle();
    expect(find.text('已保存'), findsOneWidget);
    expect(find.text('保存'), findsNothing, reason: '保存后脏状态复位，保存按钮消失');

    // 保存后返回：不应再弹「保留主题修改？」
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('保留主题修改？'), findsNothing);
    expect(container.read(themeProvider).current.id, id, reason: '已保存的主题保持');
  });

  testWidgets('有修改时返回弹确认，选「恢复原状并离开」回到进入时主题', (tester) async {
    final container = await pumpPushedPage(tester);

    // 新建自定义主题（产生未保留的修改）
    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(container.read(themeProvider).userThemes, hasLength(1));

    // 返回 → 弹确认
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('保留主题修改？'), findsOneWidget);

    // 恢复原状并离开
    await tester.tap(find.text('恢复原状并离开'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.current.id, presetThemes.first.id, reason: '恢复为进入时主题');
    expect(state.userThemes, isEmpty, reason: '本会话新建的主题一并删除');
  });

  testWidgets('有修改时返回弹确认，选「保留修改并离开」保留修改', (tester) async {
    final container = await pumpPushedPage(tester);

    await ensureVisible(tester, find.byKey(const ValueKey('theme_new')));
    await tester.tap(find.byKey(const ValueKey('theme_new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '我的主题');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    final id = container.read(themeProvider).current.id;

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('保留主题修改？'), findsOneWidget);
    await tester.tap(find.text('保留修改并离开'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.current.id, id, reason: '保留修改后主题保持');
    expect(state.userThemes, hasLength(1));
  });

  testWidgets('恢复原状会还原会话内对其他既有主题的修改（切回进入主题仍判脏）', (tester) async {
    await ThemeNotifier.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container
        .read(themeProvider.notifier)
        .addUserTheme(
          const AppTheme(
            id: 'user_a',
            name: '主题A',
            seedColor: Color(0xFF123456),
          ),
        );
    await container
        .read(themeProvider.notifier)
        .addUserTheme(
          const AppTheme(
            id: 'user_b',
            name: '主题B',
            seedColor: Color(0xFF654321),
          ),
        );
    await container.read(themeProvider.notifier).select('user_a');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ThemeSettingsPage(),
                    ),
                  ),
                  child: const Text('打开主题页'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开主题页'));
    await tester.pumpAndSettle();

    // 切到主题B并修改其背景色
    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_card_user_b')),
    );
    await tester.tap(find.byKey(const ValueKey('theme_card_user_b')));
    await tester.pumpAndSettle();
    await ensureVisible(tester, find.text('页面背景色'));
    await tester.tap(find.text('页面背景色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(themeProvider)
          .userThemes
          .firstWhere((t) => t.id == 'user_b')
          .background,
      isNotNull,
    );

    // 切回进入时的主题A：仍应判定有修改（B 被改过）→ 返回弹确认
    await ensureVisible(
      tester,
      find.byKey(const ValueKey('theme_card_user_a')),
    );
    await tester.tap(find.byKey(const ValueKey('theme_card_user_a')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('保留主题修改？'), findsOneWidget);

    await tester.tap(find.text('恢复原状并离开'));
    await tester.pumpAndSettle();

    final state = container.read(themeProvider);
    expect(state.current.id, 'user_a');
    expect(state.userThemes, hasLength(2));
    expect(
      state.userThemes.firstWhere((t) => t.id == 'user_b').background,
      isNull,
      reason: 'B 的背景色修改应被还原',
    );
  });
}
