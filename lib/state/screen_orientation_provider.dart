import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 屏幕旋转偏好：默认关闭 = 固定竖屏；开启 = 跟随设备旋转（系统设置）。
///
/// 仅在移动端有意义（web/桌面系统不响应 [SystemChrome.setPreferredOrientations]，
/// 这里直接跳过，避免无谓的平台通道调用）。
final screenRotationProvider =
    NotifierProvider<ScreenRotationNotifier, bool>(ScreenRotationNotifier.new);

class ScreenRotationNotifier extends Notifier<bool> {
  static const _key = 'ui_follow_system_rotation';

  static SharedPreferences? _prefsCache;

  /// main 启动时调用：预热 prefs 缓存（build 需同步读取）并立刻应用方向锁定，
  /// 保证首帧就是竖屏（不要等用户进设置页）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
    await _apply(_prefsCache?.getBool(_key) ?? false);
  }

  static Future<void> _apply(bool followSystem) async {
    if (kIsWeb) return;
    // 空列表 = 恢复系统默认（允许随设备旋转）；反之只允许正竖屏。
    await SystemChrome.setPreferredOrientations(
      followSystem
          ? const <DeviceOrientation>[]
          : const <DeviceOrientation>[DeviceOrientation.portraitUp],
    );
  }

  @override
  bool build() => _prefsCache?.getBool(_key) ?? false;

  Future<void> set(bool follow) async {
    if (state == follow) return;
    state = follow;
    await _apply(follow);
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setBool(_key, follow);
  }
}
