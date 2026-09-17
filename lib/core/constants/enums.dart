// 核心业务枚举与常量。
//
// 所有枚举在数据库中以 TEXT（name）存储，转换统一走 `.dbName` / `.fromDbName`。

/// 账单类型
enum BillType { expense, income, transfer }

/// 账户三大类（来自一木记账的 assettype 语义）
enum AccountCategory { fund, record, debt }

/// 账户类型
enum AccountType { alipay, wechat, bank, cash, credit, investment, other }

/// 第三方导入来源
enum ImportSource { yimu, zhouhu, qianji }

/// 余额快照类型常量（对齐 cent-xyx SnapshotType）
abstract final class SnapshotType {
  static const int expense = 1;
  static const int income = 2;
  static const int transferOut = 3;
  static const int transferIn = 4;
  static const int manual = 5;
  static const int historical = 6;
}

/// 预算周期
enum BudgetPeriodType { month, year, custom }

/// 借贷类型
enum LendType { lend, collect }

extension EnumDbName on Enum {
  String get dbName => name;

  static T fromDbName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    if (name == null) return fallback;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
