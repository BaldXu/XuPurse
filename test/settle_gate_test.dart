import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/ui/layout/xp_page_scaffold_mixin.dart';
import 'package:xupurse/ui/widgets/xp_skeleton.dart';

/// 基类骨架门回归（xp_page_scaffold_mixin）：
/// - buildBody 门：push 转场期间只渲染轻量骨架，重内容连 widget 树都不建，
///   route animation completed 后才首次构建真实内容；
/// - xpFirstSettled 首帧门：无路由转场的常驻页（tab）首帧只出骨架，
///   首帧渲染完成后才构建真实内容。
///
/// 对应机制曾踩过「动画早已 completed 时骨架常驻卡死」的坑（挂 listener
/// 前动画已 1.0 paused，completed 事件不会重发），此处补查 status 已覆盖；
/// 本测试确保「转场完成 → 内容出现」链路不回归。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildBody 门：push 转场期间只渲染骨架，完成后首次构建内容', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(XpRoute(builder: (_) => const _BuildBodyGatePage())),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );

    // 直接走 NavigatorState.push，与 transition_test 同款驱动方式
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(XpRoute<void>(builder: (_) => const _BuildBodyGatePage()));
    await tester.pump(); // 安装路由，转场开始
    await tester.pump(const Duration(milliseconds: 120)); // 转场中段
    // 转场进行中：只出骨架，重内容未构建
    expect(find.byType(XpSkeletonPage), findsOneWidget);
    expect(find.text('HEAVY'), findsNothing);

    await tester.pumpAndSettle(); // 转场完成
    expect(find.byType(XpSkeletonPage), findsNothing);
    expect(find.text('HEAVY'), findsOneWidget);
  });

  testWidgets('xpFirstSettled 首帧门：首个未挂载帧只渲染骨架，之后构建内容', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: _FirstSettledPage())),
    );
    // 首帧（LazyIndexedStack 首次挂载 tab 页的等价场景）：只有骨架
    expect(find.byType(XpSkeletonPage), findsOneWidget);
    expect(find.text('HEAVY'), findsNothing);

    await tester.pumpAndSettle(); // 首帧渲染完成 → 重建真实内容
    expect(find.byType(XpSkeletonPage), findsNothing);
    expect(find.text('HEAVY'), findsOneWidget);
  });
}

/// 重页面：buildBody 惰性构建（重内容用大号文本标记，便于断言）。
class _BuildBodyGatePage extends StatefulWidget {
  const _BuildBodyGatePage();

  @override
  State<_BuildBodyGatePage> createState() => _BuildBodyGatePageState();
}

class _BuildBodyGatePageState extends State<_BuildBodyGatePage>
    with XpPageScaffold<_BuildBodyGatePage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('gate')),
      buildBody: (_) => const Center(child: Text('HEAVY')),
    );
  }
}

/// 常驻页：首帧门（tab 页场景，无 push 转场）。
class _FirstSettledPage extends StatefulWidget {
  const _FirstSettledPage();

  @override
  State<_FirstSettledPage> createState() => _FirstSettledPageState();
}

class _FirstSettledPageState extends State<_FirstSettledPage>
    with XpPageScaffold<_FirstSettledPage> {
  @override
  Widget build(BuildContext context) {
    if (!xpFirstSettled) {
      return buildXpScaffold(body: const XpSkeletonPage());
    }
    return buildXpScaffold(body: const Center(child: Text('HEAVY')));
  }
}
