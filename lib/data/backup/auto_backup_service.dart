import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_manager.dart';
import 'auto_backup_store.dart';
import 'backup_service.dart';

/// 定时备份：开关开启时，每次启动距上次备份 ≥24h 自动备份一次。
///
/// - 保存位置固定：Android 写公共目录 `Download/XuPurse/`（应用私有目录会随
///   卸载被删，放那里等于没有备份），桌面写应用文档目录，Web 写浏览器私有
///   文件系统；只保留最近若干份，与手动备份（用户另存）互不干扰。
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

  /// 定时备份备份内容（是否包含应用设置）。
  static const String kIncludeSettings = 'auto_backup_include_settings';

  /// 上次自动备份的失败原因（成功时清空；备份页展示，避免静默失败没人知道）。
  static const String kLastError = 'auto_backup_last_error';

  /// 自动备份间隔：超过 24 小时才触发下一次。
  static const Duration interval = Duration(hours: 24);

  /// 启动时检查：开关开且距上次 ≥24h → 自动备份。失败记下原因（下次再试）。
  Future<void> maybeRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kEnabled) != true) return;
    final lastAt = prefs.getInt(kLastAt) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastAt;
    if (elapsed < interval.inMilliseconds) return;
    try {
      await run();
      await prefs.remove(kLastError);
    } catch (e) {
      // 不打断启动流程，但把原因留下来，备份页能看到「上次失败原因」
      await prefs.setString(kLastError, describeError(e));
    }
  }

  /// 把异常翻译成一句能看懂的原因。
  static String describeError(Object e) {
    final text = e.toString();
    if (text.contains('permission_denied')) {
      return '未授予存储权限，无法写入保存位置';
    }
    if (text.contains('ENOENT') || text.contains('No such file')) {
      return '保存目录不存在（可能被删除或 SD 卡已拔出）';
    }
    if (text.contains('permission') || text.contains('EACCES')) {
      return '保存目录没有写入权限（授权可能已失效，请重新选目录）';
    }
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }

  /// 立即执行一次定时备份（加密按记忆密码），返回展示文案。
  ///
  /// 备份内容/加密/保存位置均取任务保存时的配置。
  /// [manual] = true 表示用户点的「立即备份」：**不更新**上次自动备份时间，
  /// 因此 24 小时节奏不变（原定明天 14:00 仍是明天 14:00）。
  Future<String> run({bool manual = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final password = prefs.getString(kPassword);
    final dir = prefs.getString(kDir);
    final includeSettings = prefs.getBool(kIncludeSettings) ?? true;
    final json = await BackupService(_mgr).exportAll(
      password: (password == null || password.isEmpty) ? null : password,
      includeSettings: includeSettings,
    );
    final info = await saveAutoBackup(json, dir: dir);
    // 自选目录写失败时 store 会退回默认位置：这次备份没丢，但要告诉用户目录没生效
    final fellBack = isTreeUri(dir) && !info.startsWith(treeDirLabel(dir!));
    if (fellBack) {
      await prefs.setString(
        kLastError,
        '自选目录写入失败，本次已保存到 $info，请重新选一次目录',
      );
    } else {
      await prefs.remove(kLastError);
    }
    if (!manual) {
      await prefs.setInt(kLastAt, DateTime.now().millisecondsSinceEpoch);
    }
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
