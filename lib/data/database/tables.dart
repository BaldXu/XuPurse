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
  BoolColumn get includeInAssets =>
      boolean().withDefault(const Constant(true))();
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
  BoolColumn get defaultSelect =>
      boolean().withDefault(const Constant(false))();
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

/// 账单位置（1:1，与 bills 分离：便于按城市/区县聚合做消费地图）
///
/// 坐标存原始值 + [coordSystem] 说明坐标系（WGS-84 / GCJ-02），
/// 接地图底图时再按需转换，避免入库时不可逆地改写。
@TableIndex(name: 'idx_bill_locations_city', columns: {#city})
@TableIndex(name: 'idx_bill_locations_district', columns: {#district})
class BillLocations extends Table {
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.cascade)();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();

  /// 坐标系：wgs84（GPS / IP 原始）或 gcj02（国内地图底图）。
  TextColumn get coordSystem => text().withDefault(const Constant('wgs84'))();

  /// 定位精度（米）；IP 级定位为空。
  RealColumn get accuracy => real().nullable()();

  /// 用户可见地点名（如「深圳」「公司楼下」）。
  TextColumn get name => text().nullable()();

  /// 详细地址（逆地理服务接入后才会有值）。
  TextColumn get address => text().nullable()();

  TextColumn get province => text().nullable()();
  TextColumn get city => text().nullable()();
  TextColumn get district => text().nullable()();

  /// 行政区划码（未来地图边界匹配用）。
  TextColumn get adcode => text().nullable()();

  /// 地图 POI id（未来接入地图选点时写入）。
  TextColumn get poiId => text().nullable()();

  /// 来源：ip / gps / manual / import。
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// 采集时间（位置具有时效性）。
  IntColumn get capturedAt => integer()();

  @override
  Set<Column> get primaryKey => {billId};
}

/// 消费清单（事件账本：一次旅游 / 一次装修的消费集合）
@TableIndex(name: 'idx_bill_lists_updated', columns: {#updatedAt})
class BillLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 清单内分类（只属于某个消费清单，与全局记账分类无关）
///
/// 例如一次旅行的「前期准备 / 交通 / 住宿 / 餐饮」。
@TableIndex(name: 'idx_bill_list_sections_list', columns: {#listId})
class BillListSections extends Table {
  TextColumn get id => text()();
  TextColumn get listId =>
      text().references(BillLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 清单 ↔ 明细关联（多对多；删清单或删账单都级联清理关联行）
@TableIndex(name: 'idx_bill_list_items_bill', columns: {#billId})
class BillListItems extends Table {
  TextColumn get listId =>
      text().references(BillLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get billId =>
      text().references(Bills, #id, onDelete: KeyAction.cascade)();
  IntColumn get addedAt => integer()();

  /// 清单内分类 id；null = 未分类。
  TextColumn get sectionId => text().nullable()();

  @override
  Set<Column> get primaryKey => {listId, billId};
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
  List<Set<Column>> get uniqueKeys => [
    {provider, entityType, sourceId},
  ];
}

/// 年度报告汇总缓存（账本库内，一年一行）。
///
/// 纯派生数据：全部字段都可由 bills + balance_snapshots 重算，因此不做增量
/// 维护，只在读路径按 [sourceSig] 指纹判断陈旧后**整年覆盖重算**（幂等）。
/// 金额一律万分之元。
class YearReports extends Table {
  /// 公历年（本地时区）
  IntColumn get year => integer()();

  /// 记录收入（不含调账、不含「不计入收支」账单）
  IntColumn get income => integer()();

  /// 记录支出（同上口径）
  IntColumn get expense => integer()();

  /// 调账净额（收入调账 − 支出调账；负值表示手动调低）
  IntColumn get adjustNet => integer()();

  /// 年初资产（上年 12/31 24:00 = 本年 1/1 00:00 时点；无基准时为 0）
  IntColumn get startAssets => integer()();

  /// 年末资产
  IntColumn get endAssets => integer()();

  /// 该年常规记账条数
  IntColumn get billCount => integer()();

  /// 该年调账次数
  IntColumn get adjustCount => integer()();

  /// 期初/期末是否都有可用快照基准；false 时资产变动分区降级展示
  BoolColumn get hasAssetBaseline =>
      boolean().withDefault(const Constant(false))();

  /// 重算时的全库账单指纹 `"count:maxUpdatedAt"`，与当前不一致则整年重算
  TextColumn get sourceSig => text()();

  IntColumn get computedAt => integer()();

  @override
  Set<Column> get primaryKey => {year};
}
