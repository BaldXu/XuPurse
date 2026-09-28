import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/utils/icons.dart';
import '../../core/utils/twemoji_icons.dart';
import '../../state/icon_pack_provider.dart';
import '../../state/theme_provider.dart';

/// 纯操作符号（方向/关闭/确认/更多等），设计上不参与图标包切换，
/// 因此不计入 [AppIcon] 的未登记映射告警。
final Set<int> _nonSwitchableIconCodePoints = <int>{
  Icons.add.codePoint,
  Icons.close.codePoint,
  Icons.clear.codePoint,
  Icons.check.codePoint,
  Icons.chevron_left.codePoint,
  Icons.chevron_right.codePoint,
  Icons.keyboard_arrow_up.codePoint,
  Icons.keyboard_arrow_down.codePoint,
  Icons.arrow_back.codePoint,
  Icons.more_vert.codePoint,
  Icons.more_horiz.codePoint,
};

/// 已告警过的图标（按 codePoint 去重），避免每次 build 重复刷屏。
final Set<int> _warnedIconCodePoints = <int>{};

/// debug 下提示：该调用点传入了未登记映射的 [IconData]，
/// 切到 twemoji 图标包时不会跟随切换。补齐映射或改用语义名 [AppIcon.name]。
void _warnUnmappedIcon(IconData icon) {
  if (!kDebugMode || !_warnedIconCodePoints.add(icon.codePoint)) return;
  debugPrint(
    '[AppIcon] 图标 0x${icon.codePoint.toRadixString(16)} 未登记 materialEmojiNames，'
    '切换图标包时不生效；请补充映射或改用 name。',
  );
}

/// 业务图标（分类/账户图标）：按当前图标包渲染，切换后整 App 自动刷新。
///
/// - 简约（[IconPack.minimal]）：Material Icons，经 [resolveIcon] 解析语义名。
/// - Twitter 表情（[IconPack.twemoji]）：twemoji 彩色 SVG；未覆盖的名称
///   回退到简约图标渲染。
class AppIcon extends ConsumerWidget {
  const AppIcon({
    super.key,
    this.name,
    this.icon,
    this.size = 24,
    this.color,
    this.pack,
  });

  /// 语义图标名（如 `restaurant`、`savings`），对应种子数据的 icon 字段。
  /// 与 [icon] 二选一；同时给定时优先 [name]。
  final String? name;

  /// Material 图标（界面图标，如底部导航/设置入口）；按 [materialEmojiNames]
  /// 映射为对应语义名参与 twemoji 切换，未收录时保持 Material 渲染。
  final IconData? icon;

  final double size;

  /// 仅简约图标包生效（Material 单色图标可染色）；twemoji 为彩色，忽略该值。
  final Color? color;

  /// 指定图标包渲染（图标选择页预览用）；null 时跟随全局设置。
  final IconPack? pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = pack ?? ref.watch(iconPackProvider);
    final iconData = icon;
    if (name == null &&
        iconData != null &&
        !materialEmojiNames.containsKey(iconData) &&
        !_nonSwitchableIconCodePoints.contains(iconData.codePoint)) {
      _warnUnmappedIcon(iconData);
    }
    if (p == IconPack.twemoji) {
      final svg = twemojiIconRegistry[name ?? materialEmojiNames[icon]];
      if (svg != null) {
        return SvgPicture.string(svg, width: size, height: size);
      }
    }
    // name 可能为 null（数据里 icon 字段可空）：resolveIcon 已兜底书签图标。
    return Icon(
      name != null ? resolveIcon(name) : (icon ?? Icons.bookmark_outline),
      size: size,
      color: color,
    );
  }
}
