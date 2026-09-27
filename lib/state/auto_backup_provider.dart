import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/backup/auto_backup_service.dart';

/// 定时备份 UI 状态（开关 / 上次时间 / 是否已设加密密码 / 保存目录）。
class AutoBackupState {
  const AutoBackupState({
    required this.enabled,
    this.lastAt,
    this.hasPassword = false,
    this.dir,
  });

  final bool enabled;

  /// 上次自动备份时间（毫秒）；从未备份过为 null。
  final int? lastAt;

  /// 是否已设置定时备份加密密码。
  final bool hasPassword;

  /// 已配置的保存目录（IO：路径；Web：目录名）；null = 默认位置。
  final String? dir;

  AutoBackupState copyWith({
    bool? enabled,
    int? lastAt,
    bool? hasPassword,
    String? dir,
  }) {
    return AutoBackupState(
      enabled: enabled ?? this.enabled,
      lastAt: lastAt ?? this.lastAt,
      hasPassword: hasPassword ?? this.hasPassword,
      dir: dir ?? this.dir,
    );
  }
}

/// 定时备份状态：持久化到 SharedPreferences（main 预热缓存）。
final autoBackupProvider =
    NotifierProvider<AutoBackupNotifier, AutoBackupState>(
      AutoBackupNotifier.new,
    );

class AutoBackupNotifier extends Notifier<AutoBackupState> {
  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  @override
  AutoBackupState build() {
    final p = _prefsCache;
    return AutoBackupState(
      enabled: p?.getBool(AutoBackupService.kEnabled) ?? false,
      lastAt: p?.getInt(AutoBackupService.kLastAt),
      hasPassword: (p?.getString(AutoBackupService.kPassword) ?? '').isNotEmpty,
      dir: p?.getString(AutoBackupService.kDir),
    );
  }

  /// 设置（或清除，传 null）定时备份保存目录。
  Future<void> setDir(String? dir) async {
    state = state.copyWith(dir: dir);
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    if (dir == null || dir.isEmpty) {
      await prefs.remove(AutoBackupService.kDir);
    } else {
      await prefs.setString(AutoBackupService.kDir, dir);
    }
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setBool(AutoBackupService.kEnabled, value);
  }

  /// 设置定时备份加密密码（空串 = 清除）。
  Future<void> setPassword(String password) async {
    state = state.copyWith(hasPassword: password.isNotEmpty);
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    if (password.isEmpty) {
      await prefs.remove(AutoBackupService.kPassword);
    } else {
      await prefs.setString(AutoBackupService.kPassword, password);
    }
  }
}
