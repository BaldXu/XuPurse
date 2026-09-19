import 'package:sqlite3/common.dart';

import 'db_reader.dart';

/// 昼虎记账 .db 解析结果。
///
/// 行内 key 已做 snake_case → camelCase 转换（specialKeyMap 处理
/// createtime/modifytime/starttime/endtime），extdata 已解析为 Map。
class ZhouhuParsedData {
  ZhouhuParsedData({
    required this.accountBooks,
    required this.accounts,
    required this.categories,
    required this.bills,
    required this.changeLogs,
    required this.budgets,
  });

  final List<Map<String, Object?>> accountBooks;
  final List<Map<String, Object?>> accounts;
  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> bills;
  final List<Map<String, Object?>> changeLogs;
  final List<Map<String, Object?>> budgets;
}

const _zhouhuSpecialKeys = {
  'createtime': 'createTime',
  'modifytime': 'modifyTime',
  'starttime': 'startTime',
  'endtime': 'endTime',
};

String _toCamelCase(String key) {
  final special = _zhouhuSpecialKeys[key];
  if (special != null) return special;
  return key.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (m) => m.group(1)!.toUpperCase(),
  );
}

List<Map<String, Object?>> _queryAndMap(CommonDatabase db, String sql) {
  return [
    for (final row in queryRows(db, sql))
      row.map((k, v) => MapEntry(_toCamelCase(k), v)),
  ];
}

/// 读取昼虎记账导出的 .db 文件。
ZhouhuParsedData parseZhouhuDB(CommonDatabase db) {
  return ZhouhuParsedData(
    accountBooks: _queryAndMap(db, 'SELECT * FROM account_book'),
    accounts: _queryAndMap(db, 'SELECT * FROM account'),
    categories: _queryAndMap(db, 'SELECT * FROM category'),
    bills: _queryAndMap(db, 'SELECT * FROM bill'),
    changeLogs: _queryAndMap(db, 'SELECT * FROM account_change_log'),
    budgets: _queryAndMap(db, 'SELECT * FROM budget'),
  );
}
