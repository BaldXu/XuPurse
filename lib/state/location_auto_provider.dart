import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 是否允许记账页自动识别当前位置（IP 城市级）。
///
/// 默认关闭：自动识别会把设备 IP 发给第三方定位服务，属于需要用户主动
/// 开启的行为。关闭后记账页仍可手动输入地点。
final locationAutoProvider =
    NotifierProvider<LocationAutoNotifier, bool>(LocationAutoNotifier.new);

class LocationAutoNotifier extends Notifier<bool> {
  static const _key = 'ui_location_auto';

  static SharedPreferences? _prefs;

  /// main 启动时调用（与其它轻量偏好同模式）。
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  bool build() => _prefs?.getBool(_key) ?? false;

  Future<void> set(bool enabled) async {
    state = enabled;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setBool(_key, enabled);
  }
}
