import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/state/theme_provider.dart';
import 'package:xupurse/ui/widgets/xp_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('showXpSheet：内容首帧即构建 + 默认 85% 高度', (tester) async {
    await ThemeNotifier.init();
    await FrostedGlassNotifier.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () =>
                    showXpSheet(context: context, builder: (_) => const Text('弹窗内容')),
                child: const Text('打开弹窗'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开弹窗'));
    await tester.pump(); // 路由首帧（动画刚开始）
    // 性能重写后内容首帧即构建（此时弹窗在屏幕外，构建成本不可见），
    // 避免「滑完才懒构建」在动画结束帧打出 build 尖刺。
    expect(find.text('弹窗内容'), findsOneWidget, reason: '内容应首帧即构建');

    await tester.pumpAndSettle(); // 动画完成 + 磨砂淡入完成
    expect(find.text('弹窗内容'), findsOneWidget);

    // 默认高度 = 屏幕 85%
    final surface = tester.getSize(find.byKey(const ValueKey('xp_sheet_surface')));
    final screenH = tester.getSize(find.byType(Scaffold).first).height;
    expect(surface.height, closeTo(screenH * 0.85, 1.0));
  });
}
