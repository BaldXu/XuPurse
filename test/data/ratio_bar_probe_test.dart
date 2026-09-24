import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 隔离验证：储蓄条（绿底 + 红进度从左增长）在月卡同款约束链下，
/// 红段恒靠左、宽度 = 条宽 × 支出/收入，绿底铺满整条。
void main() {
  const green = Color(0xFF20B978);
  const red = Color(0xFFE5484D);

  // 模拟月卡结构：外层 Row 里 Expanded 包条，条内 SizedBox(height)+fill
  Widget harness(Widget fill) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Row(
              children: [
                const SizedBox(width: 18),
                const SizedBox(width: 8),
                const Text('2026年8月'),
                const SizedBox(width: 16),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(height: 6, child: fill),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 与 _RatioBar 相同的 Positioned 定宽实现
  Widget positionedFill({required int expense, required int income}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final redWidth = constraints.maxWidth * (expense / income);
        return Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(key: ValueKey('green'), color: green),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: redWidth,
              child: ColoredBox(key: const ValueKey('red'), color: red),
            ),
          ],
        );
      },
    );
  }

  testWidgets('红靠左、绿铺满、宽度占比正确（支出500/收入800）', (tester) async {
    await tester.pumpWidget(
      harness(positionedFill(expense: 5000000, income: 8000000)),
    );
    expect(tester.takeException(), isNull, reason: '不应有布局异常');
    final greenRect = tester.getRect(find.byKey(const ValueKey('green')));
    final redRect = tester.getRect(find.byKey(const ValueKey('red')));
    // 绿铺满整条（绿 = 条的范围）
    final barWidth = greenRect.width;
    // 红从最左开始
    expect(redRect.left, closeTo(greenRect.left, 0.01));
    // 红宽 = 条宽 × 5/8
    expect(redRect.width / barWidth, closeTo(0.625, 0.02));
    // 红不超出条
    expect(redRect.right, lessThanOrEqualTo(greenRect.right + 0.01));
  });

  testWidgets('纯收入月份（支出0/收入800）只有绿', (tester) async {
    await tester.pumpWidget(
      harness(positionedFill(expense: 0, income: 8000000)),
    );
    expect(tester.takeException(), isNull);
    final redRect = tester.getRect(find.byKey(const ValueKey('red')));
    expect(redRect.width, closeTo(0, 0.01));
    final greenRect = tester.getRect(find.byKey(const ValueKey('green')));
    expect(greenRect.width, greaterThan(0));
  });
}
