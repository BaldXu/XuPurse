import 'package:drift/drift.dart';

/// XuPurse 全部表定义（对齐 docs/data-model.md，金额一律万分之元整数）。

/// 账本（全局库）
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseCurrency => text().withDefault(const Constant('CNY'))();
  TextColumn get remark => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 账户（三类：fund/record/debt）
@TableIndex(name: 'idx_accounts_category', columns: {#category, #enabled})
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get type => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get initialBalance => integer().withDefault(const Constant(0))();
  IntColumn get currentBalance => integer().withDefault(const Constant(0))();
  TextColumn get currency => text().withDefault(const Constant('CNY'))();
  BoolColumn get includeInAssets => boolean().withDefault(const Constant(true))();
  IntColumn get creditLimit => integer().nullable()();
  TextColumn get cardCode => text().nullable()();
  IntColumn get statementDate => integer().nullable()();
  IntColumn get repaymentDate => integer().nullable()();
  TextColumn get remark => text().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  // 第三方原始 ID（导入映射与追溯）
  IntColumn get yimuAssetId => integer().nullable()();
  IntColumn get zhouhuAccountId => integer().nullable()();
  IntColumn get qianjiAssetId => integer().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 分类（两级；type = income|expense|transfer）
@TableIndex(name: 'idx_categories_parent', columns: {#parentId})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get parentId => text().nullable()();
  BoolColumn get customName => boolean().withDefault(const Constant(false))();
  BoolColumn get defaultSelect => boolean().withDefault(const Constant(false))();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  TextColumn get seedKey => text().nullable()(); // 种子分类固定键（幂等）
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 标签
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get groupId => text().nullable()();
  TextColumn get preferCurrency => text().nullable()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 标签分组
class TagGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 账单（核心表；type = income|expense|transfer，amount 恒为正）
@TableIndex(name: 'idx_bills_time', columns: {#time})
@TableIndex(name: 'idx_bills_account', columns: {#accountId})
@TableIndex(name: 'idx_bills_category', columns: {#categoryId})
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get categoryId => text()();
  IntColumn get amount => integer()();
  TextColumn get accountId => text().nullable()();
  TextColumn get incomeAccountId => text().nullable()(); // 存在即视为转账
  IntColumn get time => integer()();
  TextColumn get comment => text().nullable()();
  RealColumn get locationLat => real().nullable()();
  RealColumn get locationLng => real().nullable()();
  TextColumn get images => text().nullable()(); // JSON 数组
  // 多币种：记账当时的币种与金额
  TextColumn get currencyCode => text().nullable()();
  IntColumn get currencyAmount => integer().nullable()();
  TextColumn get baseCurrency => text().nullable()();
  // 扩展 JSON：isAdjustment / isYimu / isZhouhu / isQianji / 关联业务 ID 等
  TextColumn get extra => text().nullable()();
  TextColumn get creatorId => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 账单-标签关联
@TableIndex(name: 'idx_bill_tags_tag', columns: {#tagId})
class BillTags extends Table {
  TextColumn get billId => text()();
  TextColumn get tagId => text()();

  @override
  Set<Column> get primaryKey => {billId, tagId};
}

/// 余额快照（趋势图数据源；isValid=false 表示关联账单已失效）
@TableIndex(name: 'idx_snapshots_account', columns: {#accountId, #timestamp})
class BalanceSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  IntColumn get balance => integer()();
  IntColumn get timestamp => integer()();
  TextColumn get note => text().nullable()();
  BoolColumn get isValid => boolean().withDefault(const Constant(true))();
  TextColumn get billId => text().nullable()();
  IntColumn get type => integer()(); // SnapshotType 常量
  IntColumn get yimuAssetHistoryId => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 转账扩展（主流水在 bills；本表保留手续费/到账金额）
@TableIndex(name: 'idx_transfers_bill', columns: {#billId})
class Transfers extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  TextColumn get fromAccountId => text()();
  TextColumn get toAccountId => text()();
  IntColumn get amount => integer()();
  IntColumn get toAmount => integer().nullable()();
  IntColumn get fee => integer().withDefault(const Constant(0))();
  IntColumn get time => integer()();
  TextColumn get comment => text().nullable()();
  IntColumn get yimuTransferId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 借贷
class Lends extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // lend|collect
  TextColumn get accountId => text()();
  TextColumn get repaymentAccountId => text().nullable()();
  IntColumn get amount => integer()();
  IntColumn get interest => integer().withDefault(const Constant(0))();
  IntColumn get originalAmount => integer().nullable()();
  TextColumn get billId => text().nullable()();
  IntColumn get time => integer()();
  TextColumn get comment => text().nullable()();
  IntColumn get yimuLendId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 退款
class Refunds extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  IntColumn get amount => integer()();
  IntColumn get time => integer()();
  TextColumn get comment => text().nullable()();
  IntColumn get yimuRefundId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 报销
class Reimbursements extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  IntColumn get amount => integer()();
  TextColumn get accountId => text().nullable()();
  TextColumn get reimbursementAccountId => text().nullable()();
  BoolColumn get ended => boolean().withDefault(const Constant(false))();
  IntColumn get time => integer()();
  TextColumn get comment => text().nullable()();
  IntColumn get yimuReimbursementId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 分期
class Instalments extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text()();
  TextColumn get accountId => text()();
  IntColumn get totalAmount => integer()();
  IntColumn get serviceFee => integer().withDefault(const Constant(0))();
  IntColumn get periods => integer()();
  TextColumn get accountMonth => text().nullable()(); // 如 "2026-09"
  IntColumn get time => integer()();
  IntColumn get yimuInstalmentId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 预算
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get type => text()(); // expense|income
  TextColumn get periodType => text()(); // month|year|custom
  IntColumn get amount => integer()();
  IntColumn get startTime => integer().nullable()();
  IntColumn get endTime => integer().nullable()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get yimuBudgetId => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 导入 ID 映射（幂等核心；三家共用，provider 区分）
@TableIndex(name: 'idx_mappings_provider', columns: {#provider, #entityType})
class ImportMappings extends Table {
  TextColumn get id => text()();
  TextColumn get provider => text()(); // yimu|zhouhu|qianji
  TextColumn get entityType => text()(); // book|account|category|tag|bill|...
  TextColumn get sourceId => text()(); // 第三方业务 ID（原样字符串）
  TextColumn get targetId => text()(); // XuPurse UUID
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{provider, entityType, sourceId}];
}
