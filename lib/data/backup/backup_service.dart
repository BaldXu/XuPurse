import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_manager.dart';
import 'encryption_service.dart';

/// 备份导出 v2：全量备份 = 应用设置 + 全部账本业务数据，可选加密。
///
/// 格式对齐 docs/deployment.md 的 JSON 导出约定，并扩展为多账本 + 设置：
/// ```json
/// {
///   "format": "xupurse-backup",
///   "version": 2,
///   "exportedAt": "...",
///   "settings": { ... SharedPreferences 全量键值 ... },
///   "books": [ { ...Book 行..., "data": { 表名: [行...] } } ]
/// }
/// ```
/// 加密时整体走 [BackupEncryption.encryptJson] 变为自描述信封。
class BackupService {
  BackupService(this._mgr);

  final DatabaseManager _mgr;

  /// 导出全量备份。返回待写入文件的 JSON 字符串；
  /// [password] 非空时加密为信封格式。
  Future<String> exportAll({String? password}) async {
    final books = await _mgr.listBooks();
    final payload = <String, Object?>{
      'format': BackupEncryption.formatName,
      'version': BackupEncryption.formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': await _exportSettings(),
      'books': [
        for (final book in books)
          {...book.toJson(), 'data': await _exportBookTables(book.id)},
      ],
    };
    final json = jsonEncode(payload);
    if (password != null && password.isNotEmpty) {
      return BackupEncryption.encryptJson(json, password);
    }
    return json;
  }

  /// 应用设置快照：SharedPreferences 全量键值（主题/磨砂/图标包/默认账户/
  /// 汇率覆盖/AI 配置等全部偏好；值均为 JSON 可编码类型）。
  static Future<Map<String, Object?>> _exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final key in prefs.getKeys()) key: prefs.get(key),
    };
  }

  /// 单账本全量业务数据（15 张业务表，snake_case 表名）。
  Future<Map<String, List<Map<String, Object?>>>> _exportBookTables(
    String bookId,
  ) async {
    final db = await _mgr.openBookReadOnly(bookId);
    return {
      'accounts': await _rows(db.select(db.accounts)),
      'categories': await _rows(db.select(db.categories)),
      'tags': await _rows(db.select(db.tags)),
      'tag_groups': await _rows(db.select(db.tagGroups)),
      'bills': await _rows(db.select(db.bills)),
      'bill_tags': await _rows(db.select(db.billTags)),
      'balance_snapshots': await _rows(db.select(db.balanceSnapshots)),
      'transfers': await _rows(db.select(db.transfers)),
      'lends': await _rows(db.select(db.lends)),
      'refunds': await _rows(db.select(db.refunds)),
      'reimbursements': await _rows(db.select(db.reimbursements)),
      'instalments': await _rows(db.select(db.instalments)),
      'budgets': await _rows(db.select(db.budgets)),
      'import_mappings': await _rows(db.select(db.importMappings)),
      'year_reports': await _rows(db.select(db.yearReports)),
    };
  }

  Future<List<Map<String, Object?>>> _rows<T extends DataClass>(
    Selectable<T> query,
  ) async {
    final rows = await query.get();
    return [
      for (final r in rows) (r as dynamic).toJson() as Map<String, Object?>,
    ];
  }
}
