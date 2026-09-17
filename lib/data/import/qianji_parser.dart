import 'package:sqlite3/sqlite3.dart';

import 'db_reader.dart';

/// 钱迹 .db 解析结果。
///
/// 行内 key 先 lowercase 再 snake_case → camelCase（_id/_ID → id），
/// account.extra 解析为 {ftime, initmoney}，bill.extra 解析为结构化字段。
class QianjiParsedData {
  QianjiParsedData({
    required this.accountBooks,
    required this.accounts,
    required this.categories,
    required this.bills,
  });

  final List<Map<String, Object?>> accountBooks;
  final List<Map<String, Object?>> accounts;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> bills;
}

/// 钱迹导出列名统一转小写驼峰（参考实现语义：assetId/ASSETID/asset_id → assetid，
/// 因此 mapper 一律用小写 key 读取）。
String _toCamelCase(String key) {
  final lower = key.toLowerCase();
  if (lower == '_id') return 'id';
  return lower.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (m) => m.group(1)!.toUpperCase(),
  );
}

List<Map<String, Object?>> _queryAndMap(Database db, String sql) {
  return [
    for (final row in queryRows(db, sql))
      row.map((k, v) => MapEntry(_toCamelCase(k), v)),
  ];
}

/// 读取钱迹导出的 .db 文件。
QianjiParsedData parseQianjiDB(Database db) {
  return QianjiParsedData(
    accountBooks: _queryAndMap(db, 'SELECT * FROM user_book'),
    accounts: _queryAndMap(db, 'SELECT * FROM user_asset'),
    categories: _queryAndMap(db, 'SELECT * FROM category'),
    bills: _queryAndMap(db, 'SELECT * FROM user_bill'),
  );
}
