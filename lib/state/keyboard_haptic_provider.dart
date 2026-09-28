import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 键盘震动偏好：记账页数字键盘按键时是否触发触觉反馈（默认开启）。
///
/// 仅控制自研数字键盘的按键反馈；系统触觉走 [HapticFeedback]，无需权限。
final keyboardHapticProvider = NotifierProvider<KeyboardHapticNotifier, bool>(
  KeyboardHapticNotifier.new,
);

class KeyboardHapticNotifier extends Notifier<bool> {
  static const _key = 'ui_keyboard_haptic';

  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 需要同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  @override
  bool build() => _prefsCache?.getBool(_key) ?? true;

  Future<void> set(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setBool(_key, enabled);
  }
}
