import 'package:sqlite3/common.dart';

import 'db_reader.dart';

/// 一木记账 .db 解析结果（原始行，字段名保持原样；delete_lpcolumn=0 过滤软删）。
class YimuParsedData {
  YimuParsedData({
    required this.accountBooks,
    required this.assets,
    required this.parentCategories,
    required this.childCategories,
    required this.tags,
    required this.bills,
    required this.billTags,
    required this.transfers,
    required this.lends,
    required this.budgets,
    required this.assetHistories,
    required this.refunds,
    required this.reimbursements,
    required this.instalments,
  });

  final List<Map<String, Object?>> accountBooks;
  final List<Map<String, Object?>> assets;
  final List<Map<String, Object?>> parentCategories;
  final List<Map<String, Object?>> childCategories;
  final List<Map<String, Object?>> tags;
  final List<Map<String, Object?>> bills;
  final List<Map<String, Object?>> billTags;
  final List<Map<String, Object?>> transfers;
  final List<Map<String, Object?>> lends;
  final List<Map<String, Object?>> budgets;
  final List<Map<String, Object?>> assetHistories;
  final List<Map<String, Object?>> refunds;
  final List<Map<String, Object?>> reimbursements;
  final List<Map<String, Object?>> instalments;
}

/// 读取一木记账导出的 .db 文件。
YimuParsedData parseYimuDB(CommonDatabase db) {
  return YimuParsedData(
    accountBooks: queryRows(
      db,
      'SELECT * FROM accountbook WHERE delete_lpcolumn = 0',
    ),
    assets: queryRows(db, 'SELECT * FROM asset WHERE delete_lpcolumn = 0'),
    parentCategories: queryRows(
      db,
      'SELECT * FROM parentcategory WHERE delete_lpcolumn = 0',
    ),
    childCategories: queryRows(
      db,
      'SELECT * FROM childcategory WHERE delete_lpcolumn = 0',
    ),
    tags: queryRows(db, 'SELECT * FROM tag WHERE delete_lpcolumn = 0'),
    bills: queryRows(db, 'SELECT * FROM bill WHERE delete_lpcolumn = 0'),
    billTags: queryRows(db, 'SELECT * FROM bill_tags'),
    transfers: queryRows(
      db,
      'SELECT * FROM transfer WHERE delete_lpcolumn = 0',
    ),
    lends: queryRows(db, 'SELECT * FROM lend WHERE delete_lpcolumn = 0'),
    budgets: queryRows(db, 'SELECT * FROM budget WHERE delete_lpcolumn = 0'),
    assetHistories: queryRows(
      db,
      'SELECT * FROM assethistory WHERE delete_lpcolumn = 0',
    ),
    refunds: queryRows(db, 'SELECT * FROM refund WHERE delete_lpcolumn = 0'),
    reimbursements: queryRows(
      db,
      'SELECT * FROM reimbursement WHERE delete_lpcolumn = 0',
    ),
    instalments: queryRows(
      db,
      'SELECT * FROM instalment WHERE delete_lpcolumn = 0',
    ),
  );
}
