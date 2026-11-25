import 'package:flutter/material.dart';

import 'ai_help_page.dart';
import 'location_help_page.dart';

/// 一条「说明」：说明列表页据此渲染条目，点击进入 [buildPage] 指向的说明页。
@immutable
class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buildPage,
  });

  /// 稳定标识（未来做深链/跳转时用），不要随意改。
  final String id;

  /// 列表条目图标（跟随图标包切换，走 AppIcon）。
  final IconData icon;

  final String title;
  final String subtitle;

  /// 说明页构造器。同一主题被多处入口引用时，指向同一个页面。
  final Widget Function() buildPage;
}

/// 全站「说明」的唯一登记处（单一口径，避免同一内容出现两份文案）。
///
/// 新增一条说明：
/// 1. 在 `pages/help/` 下新建说明页，排版复用 `help_widgets.dart`；
/// 2. 在 [helpTopics] 末尾加一条 [HelpTopic]；
/// 3. 其它入口（如 AI 设置页的帮助入口）如果讲的是同一件事，直接跳同一个
///    页面，不要在别处再写一份内容。
///
/// 说明列表页只读本表，不写死任何标题/跳转目标。
final List<HelpTopic> helpTopics = <HelpTopic>[
  HelpTopic(
    id: 'location',
    icon: Icons.place_outlined,
    title: '账单位置（定位）',
    subtitle: '原理、精度与为什么不要权限',
    buildPage: () => const LocationHelpPage(),
  ),
  HelpTopic(
    id: 'ai',
    icon: Icons.smart_toy_outlined,
    title: '配置AI有什么用？',
    subtitle: 'AI 的接入方法、能力与边界',
    // 与「AI 设置 → 配置AI有什么用？」是同一页面，别另写一份。
    buildPage: () => const AiHelpPage(),
  ),
];

/// 按 id 取一条说明（未来深链/程序化跳转用）。
HelpTopic? helpTopicById(String id) {
  for (final topic in helpTopics) {
    if (topic.id == id) return topic;
  }
  return null;
}
