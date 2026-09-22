import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/state/theme_provider.dart';
import 'package:xupurse/ui/layout/xp_page_scaffold_mixin.dart';
import 'package:xupurse/ui/theme.dart';

void main() {
  Widget buildApp() => ProviderScope(
    child: MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final p in TargetPlatform.values)
              p: const XpPageTransitionsBuilder(),
          },
        ),
      ),
      home: const _Home(),
    ),
  );

  /// 旧页子树中是否存在「后退缩放」（X 轴 scale < 1）的 Transform。
  /// 注意不能用 getMaxScaleOnAxis()：其含 Z 轴（恒为 1.0），会掩盖 XY 缩放。
  bool homeHasPushBack(WidgetTester tester) {
    final transforms = find.ancestor(
      of: find.byType(_Home),
      matching: find.byType(Transform),
    );
    for (final e in transforms.evaluate()) {
      final t = e.widget as Transform;
      if (t.transform.storage[0] < 0.999) return true;
    }
    return false;
  }

  testWidgets('push 二级页：新页整页滑入 + 旧页后退，返回后恢复', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(XpRoute<void>(builder: (_) => const _Detail()));

    // 转场中段：旧页后退（缩放<1），新页仍在滑入（position.dx>0）
    await tester.pump(); // 安装路由，开始转场
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(_Detail), findsOneWidget);
    expect(homeHasPushBack(tester), isTrue, reason: '旧页应处于后退缩放态');
    final slide = tester.widget<SlideTransition>(find.byType(SlideTransition));
    expect(slide.position.value.dx, greaterThan(0), reason: '新页应处于滑入中');

    // 转场完成：enter=1 后转场壳退出（无 SlideTransition，静止零开销）
    await tester.pumpAndSettle();
    expect(find.byType(SlideTransition), findsNothing);
    expect(find.byType(_Detail), findsOneWidget);

    // 返回：动画反向，新页滑出、旧页恢复
    nav.pop();
    await tester.pump(); // 开始返回转场
    await tester.pump(const Duration(milliseconds: 120));
    expect(homeHasPushBack(tester), isTrue, reason: '返回过程中旧页仍在恢复');
    final popSlide = tester.widget<SlideTransition>(
      find.byType(SlideTransition),
    );
    expect(popSlide.position.value.dx, greaterThan(0), reason: '返回中新页向右滑出');
    await tester.pumpAndSettle();
    expect(homeHasPushBack(tester), isFalse, reason: '返回完成后旧页恢复原位');
    expect(find.byType(_Detail), findsNothing);
  });

  testWidgets('实时模糊动效开关：关闭后旧页不再套 ImageFiltered 模糊', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(buildApp());
    await tester.pump();
    final nav = tester.state<NavigatorState>(find.byType(Navigator));

    // 默认开启：push 转场中旧页（home）被 ImageFiltered 模糊
    nav.push(XpRoute<void>(builder: (_) => const _Detail()));
    await tester.pump(); // 安装路由，开始转场
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(ImageFiltered), findsWidgets, reason: '开关默认开启时旧页应有实时模糊');
    await tester.pumpAndSettle();
    nav.pop();
    await tester.pumpAndSettle();

    // 关闭开关：再次 push，旧页无模糊（退化纯位移+缩放+变暗）
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_Home)),
    );
    await container.read(transitionBlurProvider.notifier).set(false);
    await tester.pumpAndSettle();

    nav.push(XpRoute<void>(builder: (_) => const _Detail()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byType(ImageFiltered), findsNothing, reason: '开关关闭后旧页不应有模糊');
    await tester.pumpAndSettle();
  });
}

class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('home'));
}

class _Detail extends StatelessWidget {
  const _Detail();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('detail'));
}
