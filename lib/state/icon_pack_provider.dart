import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 图标包：决定分类/账户等业务图标的渲染风格。
///
/// - [minimal]：简约（Material Icons，App 默认图标）
/// - [twemoji]：Twitter 表情（colorful_iconify_flutter 的 twemoji 彩色 SVG）
enum IconPack {
  minimal('简约'),
  twemoji('Twitter 表情');

  const IconPack(this.label);

  /// 在图标选择页展示的名称。
  final String label;

  static IconPack fromName(String? name) => IconPack.values.firstWhere(
    (e) => e.name == name,
    orElse: () => IconPack.minimal,
  );
}

/// 当前图标包（全局开关），持久化到 SharedPreferences。
///
/// UI 层统一通过 [AppIcon] 消费；切换后所有订阅 [iconPackProvider] 的
/// 图标组件自动重建，实现「整 App 刷新图标」。
final iconPackProvider = NotifierProvider<IconPackNotifier, IconPack>(
  IconPackNotifier.new,
);

class IconPackNotifier extends Notifier<IconPack> {
  static const _key = 'ui_icon_pack';

  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 需要同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  @override
  IconPack build() => IconPack.fromName(_prefsCache?.getString(_key));

  Future<void> set(IconPack pack) async {
    if (state == pack) return;
    state = pack;
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setString(_key, pack.name);
  }
}
