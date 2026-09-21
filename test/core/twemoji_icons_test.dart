import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/core/utils/twemoji_icons.dart';
import 'package:xupurse/state/icon_pack_provider.dart';
import 'package:xupurse/ui/widgets/app_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('materialEmojiNames 的语义名均能在 twemojiIconRegistry 中解析', () {
    for (final entry in materialEmojiNames.entries) {
      expect(
        twemojiIconRegistry[entry.value],
        isNotNull,
        reason: '${entry.key} → ${entry.value} 未命中 twemojiIconRegistry',
      );
    }
  });

  testWidgets('twemoji 图标包：注册表中每个 SVG 均可被渲染（无解析异常）', (tester) async {
    for (final entry in twemojiIconRegistry.entries) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppIcon(name: entry.key, size: 24, pack: IconPack.twemoji),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'twemoji SVG 解析失败: ${entry.key}',
      );
    }
  });
}
