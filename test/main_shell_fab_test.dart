import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 回归：外层 Scaffold(extendBody + 底部导航 + FAB) 时，FAB 由 Scaffold
/// 自动置于底部导航之上（修复「明细页 + 按钮被磨砂导航遮挡」问题——
/// 原实现把 FAB 放在内层页面 Scaffold，落到了导航栏背后）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('外层 Scaffold 的 FAB 应位于底部导航之上', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          extendBody: true,
          body: const SizedBox.expand(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: 0,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: '明细'),
              NavigationDestination(icon: Icon(Icons.person), label: '我的'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fabBox = tester.getRect(find.byType(FloatingActionButton));
    final navBox = tester.getRect(find.byType(NavigationBar));
    expect(
      fabBox.bottom <= navBox.top + 1,
      isTrue,
      reason:
          'FAB 应浮在底部导航之上（FAB bottom=${fabBox.bottom}, nav top=${navBox.top}）',
    );
  });
}
