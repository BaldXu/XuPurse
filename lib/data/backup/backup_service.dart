import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/global_database.dart';

/// 备份导出：当前账本全量数据导出为 JSON（格式对齐 docs/deployment.md）。
class BackupService {
  BackupService(this._db, this._global);

  final AppDatabase _db;
  final GlobalDatabase _global;

  /// 导出指定账本的全部业务数据（不含其他账本）。
  Future<String> exportBook(String bookId) async {
    final book = await (_global.select(
      _global.books,
    )..where((t) => t.id.equals(bookId))).getSingleOrNull();
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'book': book == null
          ? null
          : {'name': book.name, 'baseCurrency': book.baseCurrency},
      'accounts': await _rows(_db.select(_db.accounts)),
      'categories': await _rows(_db.select(_db.categories)),
      'tags': await _rows(_db.select(_db.tags)),
      'bills': await _rows(_db.select(_db.bills)),
      'billTags': await _rows(_db.select(_db.billTags)),
      'snapshots': await _rows(_db.select(_db.balanceSnapshots)),
      'transfers': await _rows(_db.select(_db.transfers)),
      'lends': await _rows(_db.select(_db.lends)),
      'refunds': await _rows(_db.select(_db.refunds)),
      'reimbursements': await _rows(_db.select(_db.reimbursements)),
      'instalments': await _rows(_db.select(_db.instalments)),
      'budgets': await _rows(_db.select(_db.budgets)),
      'importMappings': await _rows(_db.select(_db.importMappings)),
    });
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
