/// 账单相关 SQL 片段（多仓储共用，避免各处手抄口径）。
///
/// 净额口径：**退款只冲减原支出，绝不计入收入**——支出净额 =
/// `amount − (该账单退款合计)`；收入/转账账单不参与扣减。
/// 退款按**原账单的时间/分类**归集（统计上仍算在原支出的那个月与分类里）。
library;

/// 账单净额 SQL（无表别名版，`FROM bills` 时用）。
const String kBillNetSql =
    "(CASE WHEN type = 'expense' THEN amount - COALESCE("
    '(SELECT SUM(r.amount) FROM refunds r WHERE r.bill_id = bills.id), 0) '
    'ELSE amount END)';

/// 账单净额 SQL（`b` 表别名版，JOIN 查询用）。
const String kBillNetSqlB =
    "(CASE WHEN b.type = 'expense' THEN b.amount - COALESCE("
    '(SELECT SUM(r.amount) FROM refunds r WHERE r.bill_id = b.id), 0) '
    'ELSE b.amount END)';
