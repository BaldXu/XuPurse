import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import '../database/database_manager.dart';
import 'encryption_service.dart';

/// 恢复方式。
enum RestoreMode {
  /// 覆盖：删除现有全部数据，完整还原为备份状态（换机 / 重装后恢复用）。
  overwrite,

  /// 追加：保留现有数据，备份中的账本作为新账本导入（合并场景用）。
  append,
}

/// 备份不适配异常：不是本应用备份 / 格式或版本不支持。
class UnsupportedBackupException implements Exception {
  const UnsupportedBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 备份概览（恢复选项弹窗展示用）。
class RestoreSummary {
  const RestoreSummary({required this.hasSettings, required this.bookNames});

  /// 备份是否包含应用设置段。
  final bool hasSettings;

  /// 备份内账本名（按导出顺序）。
  final List<String> bookNames;
}

/// 恢复服务：解析校验备份 → 按「覆盖 / 追加」写回账本数据 → 可选覆盖设置。
///
/// 仅支持本应用 v2 固定格式（[BackupEncryption.formatName]）；
/// 加密备份需先由调用方解密为明文 JSON 再传入。
class RestoreService {
  RestoreService(this._mgr);

  final DatabaseManager _mgr;

  /// 解析并校验备份内容；不适配抛 [UnsupportedBackupException]。
  static RestoreSummary inspect(String json) {
    final payload = _parsePayload(json);
    final bookNames = <String>[];
    final books = payload['books'];
    if (books is List) {
      for (final b in books) {
        if (b is Map && b['name'] is String) {
          bookNames.add(b['name'] as String);
        }
      }
    }
    return RestoreSummary(
      hasSettings: payload['settings'] is Map,
      bookNames: bookNames,
    );
  }

  /// 执行恢复。覆盖模式以备份替换现有账本（两阶段删除缩小破坏窗口）；
  /// 追加模式为备份账本生成新 ID，保留现有数据不动。
  Future<void> restore(
    String json, {
    required RestoreMode mode,
    bool overwriteSettings = false,
  }) async {
    final payload = _parsePayload(json);
    final books = <Map<String, Object?>>[
      for (final raw in (payload['books'] as List?) ?? const [])
        if (raw is Map) Map<String, Object?>.from(raw),
    ];

    // 覆盖模式：先只删除「备份中同 ID」的本地账本（释放全局主键），
    // 备份账本重建成功后再删除备份中没有的本地账本——中途失败不会像
    // 「全量先删后建」那样清空全部现有数据。
    final leftoverIds = <String>{};
    if (mode == RestoreMode.overwrite) {
      for (final book in await _mgr.listBooks()) {
        leftoverIds.add(book.id);
      }
      for (final book in books) {
        final id = book['id'];
        if (id is String && leftoverIds.remove(id)) {
          await _mgr.deleteBook(id);
        }
      }
    }

    for (final book in books) {
      // 覆盖模式复用备份原 ID；追加模式生成新 ID 避免与现有账本冲突。
      final bookId = mode == RestoreMode.overwrite
          ? (book['id'] as String? ?? genId())
          : genId();
      await _mgr.registerBook(
        id: bookId,
        name: book['name'] as String? ?? '未命名账本',
        baseCurrency: book['baseCurrency'] as String? ?? 'CNY',
        remark: book['remark'] as String?,
        createdAt: book['createdAt'] as int?,
        updatedAt: book['updatedAt'] as int?,
      );
      if (book['data'] is Map) {
        await _restoreBookData(
          bookId,
          Map<String, Object?>.from(book['data'] as Map),
        );
      }
    }

    if (mode == RestoreMode.overwrite) {
      for (final id in leftoverIds) {
        await _mgr.deleteBook(id);
      }
    }

    if (overwriteSettings && payload['settings'] is Map) {
      await _restoreSettings(
        Map<String, Object?>.from(payload['settings'] as Map),
      );
    }
  }

  /// 解析 + 格式/版本校验（只认本应用 v2 格式）。
  static Map<String, Object?> _parsePayload(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw const UnsupportedBackupException('文件内容无法解析，不是有效的备份');
    }
    if (decoded is! Map) {
      throw const UnsupportedBackupException('文件内容无法解析，不是有效的备份');
    }
    final map = Map<String, Object?>.from(decoded);
    if (map['format'] != BackupEncryption.formatName) {
      throw const UnsupportedBackupException('不是 XuPurse 备份文件，格式不匹配');
    }
    final version = map['version'];
    if (version is! int) {
      throw const UnsupportedBackupException('备份文件缺少版本信息');
    }
    if (version > BackupEncryption.formatVersion) {
      throw const UnsupportedBackupException('备份版本过新，请升级应用后再试');
    }
    if (version < BackupEncryption.formatVersion) {
      throw const UnsupportedBackupException('备份版本过旧，暂不支持恢复');
    }
    return map;
  }

  /// 逐表写入账本业务数据（顺序与导出一致：账户/分类等父表在前）。
  ///
  /// 整个账本包在单个 drift batch：一次事务执行全部插入，中途失败该账本
  /// 整体回滚（不留半套数据），大数据量下也远快于逐行 autocommit。
  Future<void> _restoreBookData(
    String bookId,
    Map<String, Object?> data,
  ) async {
    final db = await _mgr.openBookReadOnly(bookId);
    await db.batch((batch) {
      _batchInsert(
        batch,
        db.accounts,
        (m) => Account.fromJson(m).toCompanion(true),
        data['accounts'],
      );
      _batchInsert(
        batch,
        db.categories,
        (m) => Category.fromJson(m).toCompanion(true),
        data['categories'],
      );
      _batchInsert(
        batch,
        db.tags,
        (m) => Tag.fromJson(m).toCompanion(true),
        data['tags'],
      );
      _batchInsert(
        batch,
        db.tagGroups,
        (m) => TagGroup.fromJson(m).toCompanion(true),
        data['tag_groups'],
      );
      _batchInsert(
        batch,
        db.bills,
        (m) => Bill.fromJson(m).toCompanion(true),
        data['bills'],
      );
      _batchInsert(
        batch,
        db.billTags,
        (m) => BillTag.fromJson(m).toCompanion(true),
        data['bill_tags'],
      );
      _batchInsert(
        batch,
        db.balanceSnapshots,
        (m) => BalanceSnapshot.fromJson(m).toCompanion(true),
        data['balance_snapshots'],
      );
      _batchInsert(
        batch,
        db.transfers,
        (m) => Transfer.fromJson(m).toCompanion(true),
        data['transfers'],
      );
      _batchInsert(
        batch,
        db.lends,
        (m) => Lend.fromJson(m).toCompanion(true),
        data['lends'],
      );
      _batchInsert(
        batch,
        db.refunds,
        (m) => Refund.fromJson(m).toCompanion(true),
        data['refunds'],
      );
      _batchInsert(
        batch,
        db.reimbursements,
        (m) => Reimbursement.fromJson(m).toCompanion(true),
        data['reimbursements'],
      );
      _batchInsert(
        batch,
        db.instalments,
        (m) => Instalment.fromJson(m).toCompanion(true),
        data['instalments'],
      );
      _batchInsert(
        batch,
        db.budgets,
        (m) => Budget.fromJson(m).toCompanion(true),
        data['budgets'],
      );
      _batchInsert(
        batch,
        db.importMappings,
        (m) => ImportMapping.fromJson(m).toCompanion(true),
        data['import_mappings'],
      );
      _batchInsert(
        batch,
        db.yearReports,
        (m) => YearReport.fromJson(m).toCompanion(true),
        data['year_reports'],
      );
    });
  }

  /// 通用批量插入：drift 数据类 fromJson → 显式 Companion（null 视为缺省）。
  ///
  /// 泛型按「表 ↔ 伴生对象」成对约束：表与 Companion 错配时编译期即报错。
  void _batchInsert<
    T extends Table,
    D extends DataClass,
    C extends UpdateCompanion<D>
  >(
    Batch batch,
    TableInfo<T, D> table,
    C Function(Map<String, dynamic> json) toCompanion,
    Object? rows,
  ) {
    if (rows is! List) return;
    for (final r in rows) {
      if (r is! Map) continue;
      batch.insert(table, toCompanion(Map<String, dynamic>.from(r)));
    }
  }

  /// 应用设置覆盖写回：SharedPreferences 全量键值（JSON 可编码类型）。
  Future<void> _restoreSettings(Map<String, Object?> settings) async {
    final prefs = await SharedPreferences.getInstance();
    for (final e in settings.entries) {
      switch (e.value) {
        case final String s:
          await prefs.setString(e.key, s);
        case final bool b:
          await prefs.setBool(e.key, b);
        case final int i:
          await prefs.setInt(e.key, i);
        case final double d:
          await prefs.setDouble(e.key, d);
        case final List<String> l:
          await prefs.setStringList(e.key, l);
      }
    }
  }
}
