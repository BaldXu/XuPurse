import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  // 曾绕过 AppIcon / 未登记映射的界面图标，补齐后锁定，防止回归。
  const migratedIcons = <IconData>[
    Icons.vibration,
    Icons.blur_on,
    Icons.vertical_split,
    Icons.style_outlined,
    Icons.article_outlined,
    Icons.motion_photos_on_outlined,
    Icons.restart_alt,
    Icons.lock_outline,
    Icons.folder_outlined,
    Icons.restore,
    Icons.sync,
    Icons.tune,
    Icons.shield_outlined,
    Icons.help_outline,
    Icons.swap_vert,
    Icons.sell_outlined,
    Icons.notes_outlined,
    Icons.warning_amber_rounded,
    Icons.filter_alt_outlined,
    Icons.percent,
    Icons.event_outlined,
    Icons.edit_note,
    Icons.replay,
    Icons.delete_forever_outlined,
    Icons.keyboard_alt_outlined,
    Icons.merge_type,
    Icons.download_done,
    Icons.call_made,
    Icons.call_received,
  ];

  test('曾缺口的界面图标均已登记 materialEmojiNames', () {
    for (final icon in migratedIcons) {
      expect(
        materialEmojiNames.containsKey(icon),
        isTrue,
        reason: '0x${icon.codePoint.toRadixString(16)} 未登记映射',
      );
    }
  });

  testWidgets('twemoji 图标包：已登记界面图标实际渲染为 SVG 而非 Material', (tester) async {
    for (final icon in migratedIcons) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AppIcon(icon: icon, size: 24, pack: IconPack.twemoji),
            ),
          ),
        ),
      );
      expect(
        find.byType(SvgPicture),
        findsOneWidget,
        reason: '0x${icon.codePoint.toRadixString(16)} 未渲染为 twemoji SVG',
      );
    }
  });
}
