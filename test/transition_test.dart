import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/ui/layout/xp_page_scaffold_mixin.dart';
import 'package:xupurse/ui/theme.dart';

void main() {
  Widget buildApp() => MaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: const XpPageTransitionsBuilder(),
        },
      ),
    ),
    home: const _Home(),
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
