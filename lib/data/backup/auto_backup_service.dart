import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_manager.dart';
import 'auto_backup_store.dart';
import 'backup_service.dart';

/// 定时备份：开关开启时，每次启动距上次备份 ≥24h 自动备份一次。
///
/// - 保存位置固定（应用文档目录固定文件 / Web 浏览器 localStorage），
///   只覆盖上一次定时备份文件，与手动备份（用户另存）互不干扰。
/// - 加密：开启「加密定时备份」时密码保存在本机 SharedPreferences，
///   每次自动备份都用它加密；密码不会随备份文件导出。
/// - 启动检查失败静默（不打扰启动，不更新时间戳，下次启动重试）。
class AutoBackupService {
  AutoBackupService(this._mgr);

  final DatabaseManager _mgr;

  /// 定时备份开关。
  static const String kEnabled = 'auto_backup_enabled';

  /// 上次定时备份时间（毫秒时间戳）。
  static const String kLastAt = 'auto_backup_last_at';

  /// 定时备份加密密码（应用内记忆，明文仅存本机）。
  static const String kPassword = 'auto_backup_password';

  /// 定时备份保存目录（IO：路径；Web：目录名；空 = 默认位置）。
  static const String kDir = 'auto_backup_dir';

  /// 自动备份间隔：超过 24 小时才触发下一次。
  static const Duration interval = Duration(hours: 24);

  /// 启动时检查：开关开且距上次 ≥24h → 自动备份。失败静默（下次再试）。
  Future<void> maybeRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kEnabled) != true) return;
    final lastAt = prefs.getInt(kLastAt) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastAt;
    if (elapsed < interval.inMilliseconds) return;
    try {
      await run();
    } catch (_) {
      // 静默失败：不打断启动流程，下次启动再试。
    }
  }

  /// 立即执行一次定时备份（加密按记忆密码）。成功更新时间戳并返回展示文案。
  /// [includeSettings] 透传备份内容选择（应用设置是否包含）。
  Future<String> run({bool includeSettings = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString(kPassword);
    final dir = prefs.getString(kDir);
    final json = await BackupService(_mgr).exportAll(
      password: (password == null || password.isEmpty) ? null : password,
      includeSettings: includeSettings,
    );
    final info = await saveAutoBackup(json, dir: dir);
    await prefs.setInt(kLastAt, DateTime.now().millisecondsSinceEpoch);
    return info;
  }

  /// 读取上次定时备份内容（恢复入口用）；不存在返回 null。
  Future<String?> readLast() async {
    final prefs = await SharedPreferences.getInstance();
    return readAutoBackup(dir: prefs.getString(kDir));
  }

  /// 选择定时备份保存目录（一次性配置，之后自动备份都写该目录）。
  /// 返回展示名（目录名/路径）；取消返回 null；不支持抛 [UnsupportedError]。
  Future<String?> configureDir() => configureAutoBackupDir();

  /// 清除自定义保存目录（恢复默认位置）。
  Future<void> clearDir() => clearAutoBackupDir();
}
