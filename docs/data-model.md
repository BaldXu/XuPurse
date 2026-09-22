# 数据模型与数据库表设计

> 状态：✅ 已实现（2026-09-17 制定，14 张表均已落地）
>
> 本文件是 XuPurse 的**数据库表设计权威文档**。设计基准：以**一木记账**为业务蓝本，完整覆盖昼虎 / 钱迹字段，保证三家第三方数据库导入**零偏差**。
>
> 配套：见 [架构说明](./architecture.md)、[重写计划](./rewrite-plan.md)。

## 1. 设计约定

### 1.1 存储结构

| 数据库 | 命名 | 内容 |
|--------|------|------|
| 全局库 | `xupurse.db` | 账本列表（books）、应用级设置 |
| 账本库 | `book-<id>.db` | 一个账本的全部业务数据（账单、账户、分类、标签、快照、业务实体、导入映射） |

- Web 端：drift 自动使用 IndexedDB 实现；Android / iOS：本地 SQLite。
- 切换账本 = 切换数据源，数据完全隔离。

### 1.2 金额单位（红线）

- **内部一律使用整数「万分之元」**：`1 元 = 10000`。
- 三方数据库原始单位为「元」（可能带小数），导入时 `numberToAmount(v) = round(v × 10000)` **无损转换**。
- UI 显示：`amount / 10000`（保留两位小数）；输入/存储：`amount × 10000`。
- 所有表金额字段为 `INTEGER`（万分之元），命名为 `_amount` 或 `balance` / `_number` 等（对齐三方语义）。

### 1.3 时间

- 一律 `INTEGER` 毫秒时间戳（`DateTime.millisecondsSinceEpoch`）。
- 一木 `recordtime` / 昼虎 `createTime` / 钱迹 `time` 均为毫秒戳，直接映射。

### 1.4 ID

- 业务主键：UUID 字符串（`TEXT`）。
- 第三方原始 ID：独立字段保留（如 `yimuAssetId`），供导入映射与追溯。

### 1.5 软删除

- 三方均有 `delete_lpcolumn`（一木）/ `disuse`（昼虎）/ `status`（钱迹）软删字段。
- 导入时**过滤**软删数据（只导入有效行），不需要在表内复刻软删标记。

## 2. 表清单总览

| 表 | 说明 | 核心来源 |
|----|------|---------|
| [books](#21-books) | 账本（全局库） | 自研 |
| [accounts](#22-accounts) | 账户（三类） | 一木 asset + 钱迹 account |
| [categories](#23-categories) | 分类（两级） | 一木 parentcategory/childcategory |
| [tags](#24-tags--tag_groups) | 标签 + 分组 | 一木 tag |
| [bills](#25-bills) | 账单（收支/转账） | 一木 bill + 昼虎 bill + 钱迹 bill |
| [bill_tags](#26-bill_tags) | 账单-标签关联 | 一木 bill_tags |
| [balance_snapshots](#27-balance_snapshots) | 余额快照 | 一木 assethistory + 昼虎 account_change_log |
| [transfers](#28-transfers) | 转账扩展（手续费/到账） | 一木 transfer |
| [lends](#29-lends) | 借贷 | 一木 lend |
| [refunds](#210-refunds) | 退款 | 一木 refund + 钱迹 refund 字段 |
| [reimbursements](#211-reimbursements) | 报销 | 一木 reimbursement + 钱迹报销字段 |
| [instalments](#212-instalments) | 分期 | 一木 instalment |
| [budgets](#213-budgets) | 预算 | 一木 budget + 昼虎 budget |
| [import_mappings](#214-import_mappings) | 导入 ID 映射（幂等核心） | 自研 |

---

## 2.1 books（账本 · 全局库）

```sql
CREATE TABLE books (
  id            TEXT PRIMARY KEY,          -- 账本 ID（UUID）
  name          TEXT NOT NULL,             -- 账本名称
  base_currency TEXT NOT NULL DEFAULT 'CNY', -- 本位币
  remark        TEXT,
  created_at    INTEGER NOT NULL,          -- 毫秒时间戳
  updated_at    INTEGER NOT NULL
);
```

设计要点：每个账本对应一个独立数据库 `book-<id>.db`；`base_currency` 决定总资产折算目标。

## 2.2 accounts（账户）

```sql
CREATE TABLE accounts (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,             -- 账户名称（同账本内唯一）
  category        TEXT NOT NULL,             -- fund | record | debt（三大类）
  type            TEXT NOT NULL,             -- alipay|wechat|bank|cash|credit|investment|other
  icon            TEXT,                      -- 图标标识
  color           TEXT,
  initial_balance INTEGER NOT NULL DEFAULT 0,  -- 初始余额（万分之元）
  current_balance INTEGER NOT NULL DEFAULT 0,  -- 当前余额（万分之元，权威值！）
  currency        TEXT NOT NULL DEFAULT 'CNY', -- 账户币种
  include_in_assets INTEGER NOT NULL DEFAULT 1, -- debt/record 是否计入总资产
  credit_limit    INTEGER,                   -- 信用额度（万分之元，信用卡）
  card_code       TEXT,                      -- 卡号（信用卡/储蓄卡）
  statement_date  INTEGER,                   -- 账单日（1-31）
  repayment_date  INTEGER,                   -- 还款日（1-31）
  remark          TEXT,
  enabled         INTEGER NOT NULL DEFAULT 1,  -- 是否启用
  -- 第三方原始 ID（导入映射与追溯）
  yimu_asset_id    INTEGER,                  -- 一木 asset.assetid
  zhouhu_account_id INTEGER,                 -- 昼虎 account.id
  qianji_asset_id  INTEGER,                  -- 钱迹 account.id
  created_at      INTEGER NOT NULL,
  updated_at      INTEGER NOT NULL
);
CREATE INDEX idx_accounts_category ON accounts(category, enabled);
```

字段对齐：

| XuPurse | 一木 | 昼虎 | 钱迹 |
|---------|------|------|------|
| category | assettype(3=record, 6=debt, 其他=fund) | - | type(1=资产, 5=债务) |
| type | asseticon 推断 | accountType | stype |
| current_balance | assetnumber（权威） | balance | money |
| include_in_assets | intototalasset | notProperty(取反) | type(1=计入) |
| credit_limit | totalquota | - | loanInfo |
| currency | currency | currencyCode | currency |

## 2.3 categories（分类）

```sql
CREATE TABLE categories (
  id             TEXT PRIMARY KEY,
  type           TEXT NOT NULL,          -- income | expense（分类方向）
  name           TEXT NOT NULL,
  icon           TEXT,
  color          TEXT,
  parent_id      TEXT,                   -- 父分类 ID；空 = 一级分类
  custom_name    INTEGER NOT NULL DEFAULT 0, -- 用户自定义分类 = 1
  default_select INTEGER NOT NULL DEFAULT 0, -- 默认选中子类
  sort           INTEGER NOT NULL DEFAULT 0,
  created_at     INTEGER NOT NULL,
  updated_at     INTEGER NOT NULL
);
CREATE INDEX idx_categories_parent ON categories(parent_id);
```

字段对齐：

| XuPurse | 一木 | 昼虎 | 钱迹 |
|---------|------|------|------|
| type | categorytype | type | type(0=支出 1=收入) |
| parent_id | childcategory.parentcategoryid | - | parentId(-1=顶级) |

内置保留分类：`balance_adjustment_income`（调账收入）、`balance_adjustment_expense`（调账支出）。

## 2.4 tags / tag_groups（标签）

```sql
CREATE TABLE tags (
  id             TEXT PRIMARY KEY,
  name           TEXT NOT NULL,
  color          TEXT,
  group_id       TEXT,                  -- 关联 tag_groups.id
  prefer_currency TEXT,                 -- 选中该标签自动切换记账币种
  sort           INTEGER NOT NULL DEFAULT 0,
  created_at     INTEGER NOT NULL,
  updated_at     INTEGER NOT NULL
);

CREATE TABLE tag_groups (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  sort       INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);
```

字段对齐：一木 `tag`（parenttagid → group_id）。

## 2.5 bills（账单 · 核心表）

```sql
CREATE TABLE bills (
  id               TEXT PRIMARY KEY,
  type             TEXT NOT NULL,       -- income | expense | transfer
  category_id      TEXT NOT NULL,       -- 关联 categories.id
  amount           INTEGER NOT NULL,    -- 金额（万分之元，恒为正数）
  account_id       TEXT,                -- 支出/收入/转出账户
  income_account_id TEXT,               -- 存在即视为转账（转入账户）
  time             INTEGER NOT NULL,    -- 账单发生时间（毫秒）
  comment          TEXT,
  location_lat     REAL,
  location_lng     REAL,
  images           TEXT,                -- JSON 数组（URL 或 base64）
  -- 多币种：记账当时的币种与金额
  currency_code    TEXT,                -- 记账时选择的币种（目标币种）
  currency_amount  INTEGER,             -- 记账时填写的金额（该币种，万分之元）
  base_currency    TEXT,                -- 记账时本位币
  -- 扩展
  extra            TEXT,                -- JSON：scheduledId/isAdjustment/来源标记/一木原字段等
  creator_id       TEXT,
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL
);
CREATE INDEX idx_bills_time ON bills(time DESC);
CREATE INDEX idx_bills_account ON bills(account_id);
CREATE INDEX idx_bills_category ON bills(category_id);
```

### 记账语义

| type | account_id | income_account_id | 余额影响 |
|------|-----------|-------------------|---------|
| expense | 扣款账户 | 空 | account_id −= amount |
| income | 入账账户 | 空 | account_id += amount |
| transfer | 转出账户 | 转入账户 | account_id −= amount；income_account_id += amount |

### 多币种语义

- `currency_code` 非空且 ≠ 账户币种时：`amount` 为**账户币种换算后**金额，`currency_amount` 为用户输入的原始外币金额，`currency_code` 为其币种。
- 展示时用当前汇率换算，追溯时用 `currency_amount` + 记账当时汇率（`currency_amount / amount`）。

### extra JSON 约定（对齐三方）

```jsonc
{
  "isAdjustment": true,          // 调账账单（重算时跳过）
  "isYimu": true,                // 一木导入（重算/校验跳过）
  "isZhouhu": true,              // 昼虎导入
  "isQianji": true,              // 钱迹导入
  "yimuTransferDirection": "out", // 一木转账方向
  "notInBudget": true,           // 不计入预算
  "notInTotal": true,            // 不计入统计
  "reimbursementId": "uuid",     // 关联报销
  "refundId": "uuid",            // 关联退款
  "instalmentId": "uuid",        // 关联分期
  "yimuBillId": 123              // 一木 billid 冗余（快速追溯）
}
```

## 2.6 bill_tags（账单-标签关联）

```sql
CREATE TABLE bill_tags (
  bill_id TEXT NOT NULL,
  tag_id  TEXT NOT NULL,
  PRIMARY KEY (bill_id, tag_id)
);
CREATE INDEX idx_bill_tags_tag ON bill_tags(tag_id);
```

对齐：一木 `bill_tags(bill_id, tags)`，tags 为逗号分隔，导入时拆分。

## 2.7 balance_snapshots（余额快照）

```sql
CREATE TABLE balance_snapshots (
  id           TEXT PRIMARY KEY,
  account_id   TEXT NOT NULL,
  balance      INTEGER NOT NULL,       -- 该时点余额（万分之元）
  timestamp    INTEGER NOT NULL,       -- 快照时点（毫秒）
  note         TEXT,
  is_valid     INTEGER NOT NULL DEFAULT 1, -- 关联账单被删/改后置 0
  bill_id      TEXT,                   -- 产生快照的账单
  type         INTEGER NOT NULL,       -- 1消费 2收入 3转出 4转入 5手动 6历史
  -- 第三方原始 ID
  yimu_asset_history_id INTEGER
);
CREATE INDEX idx_snapshots_account ON balance_snapshots(account_id, timestamp);
```

快照生命周期：记账/转账/调账自动创建 → 账单删除/修改时 `is_valid = 0` → 趋势图只读有效快照（[算法五](./algorithms.md)）。

对齐：一木 `assethistory(assetid, currentnum, changenum, time)`；昼虎 `account_change_log(accountId, change, type, createTime)`，type=3 为月度余额调整。

## 2.8 transfers（转账扩展）

> 转账的主流水存于 bills（type=transfer）；本表保留三方转账的完整字段（手续费、到账金额），**必填关联 bill**。

```sql
CREATE TABLE transfers (
  id               TEXT PRIMARY KEY,
  bill_id          TEXT NOT NULL,      -- 关联 bills.id（转账流水）
  from_account_id  TEXT NOT NULL,
  to_account_id    TEXT NOT NULL,
  amount           INTEGER NOT NULL,   -- 转出金额（万分之元）
  to_amount        INTEGER,            -- 到账金额（跨币种/手续费时不同）
  fee              INTEGER NOT NULL DEFAULT 0, -- 手续费（万分之元）
  time             INTEGER NOT NULL,
  comment          TEXT,
  yimu_transfer_id INTEGER,            -- 一木 transferid
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL
);
CREATE INDEX idx_transfers_bill ON transfers(bill_id);
```

对齐：一木 `transfer(fromassetid, toassetid, cost, tocost, servicecharge, billid)`。

## 2.9 lends（借贷）

```sql
CREATE TABLE lends (
  id               TEXT PRIMARY KEY,
  type             TEXT NOT NULL,      -- lend（借出）| collect（收回）
  account_id       TEXT NOT NULL,      -- 关联资产账户
  repayment_account_id TEXT,           -- 还款账户
  amount           INTEGER NOT NULL,   -- 金额（万分之元）
  interest         INTEGER DEFAULT 0,  -- 利息
  original_amount  INTEGER,            -- 原始币种金额
  bill_id          TEXT,               -- 关联账单
  time             INTEGER NOT NULL,
  comment          TEXT,
  yimu_lend_id     INTEGER,            -- 一木 lendid
  created_at       INTEGER NOT NULL,
  updated_at       INTEGER NOT NULL
);
```

对齐：一木 `lend(type, assetid, repaymentassetid, number, interest, billid, outtime/intime)`。

## 2.10 refunds（退款）

```sql
CREATE TABLE refunds (
  id             TEXT PRIMARY KEY,
  bill_id        TEXT NOT NULL,        -- 关联原账单
  amount         INTEGER NOT NULL,     -- 退款金额（万分之元）
  time           INTEGER NOT NULL,
  comment        TEXT,
  yimu_refund_id INTEGER,              -- 一木 refundid
  created_at     INTEGER NOT NULL,
  updated_at     INTEGER NOT NULL
);
```

对齐：一木 `refund(refundnum, billid)`；钱迹 bill.extra 中 `refundid/refundv/refundsid`。

## 2.11 reimbursements（报销）

```sql
CREATE TABLE reimbursements (
  id                     TEXT PRIMARY KEY,
  bill_id                TEXT NOT NULL,   -- 关联被报销账单
  amount                 INTEGER NOT NULL,-- 报销金额（万分之元）
  account_id             TEXT,            -- 关联资产账户（先行垫付账户）
  reimbursement_account_id TEXT,          -- 报销入账账户
  ended                  INTEGER NOT NULL DEFAULT 0, -- 是否已结束
  time                   INTEGER NOT NULL,
  comment                TEXT,
  yimu_reimbursement_id  INTEGER,
  created_at             INTEGER NOT NULL,
  updated_at             INTEGER NOT NULL
);
```

对齐：一木 `reimbursement(reimbursementnum, billid, assetid, reimbursementassetid, end)`；钱迹 bill.extra 报销字段（baoxiaov/bxsid/baoxiaoasset/baoxiaoed）。

## 2.12 instalments（分期）

```sql
CREATE TABLE instalments (
  id             TEXT PRIMARY KEY,
  bill_id        TEXT NOT NULL,        -- 关联原账单
  account_id     TEXT NOT NULL,        -- 关联扣款账户
  total_amount   INTEGER NOT NULL,     -- 总金额（万分之元）
  service_fee    INTEGER DEFAULT 0,    -- 服务费
  periods        INTEGER NOT NULL,     -- 总期数
  account_month  TEXT,                 -- 当前账期（如 "2026-09"）
  time           INTEGER NOT NULL,
  yimu_instalment_id INTEGER,
  created_at     INTEGER NOT NULL,
  updated_at     INTEGER NOT NULL
);
```

对齐：一木 `instalment(totalnumber, servicenumber, periods, accountmonth, assetid, billid)`。

## 2.13 budgets（预算）

```sql
CREATE TABLE budgets (
  id           TEXT PRIMARY KEY,
  name         TEXT NOT NULL,
  category_id  TEXT,                  -- 关联分类（空 = 总预算）
  type         TEXT NOT NULL,         -- expense | income
  period_type  TEXT NOT NULL,         -- month | year | custom
  amount       INTEGER NOT NULL,      -- 预算总额（万分之元）
  start_time   INTEGER,
  end_time     INTEGER,
  enabled      INTEGER NOT NULL DEFAULT 1,
  yimu_budget_id INTEGER,
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL
);
```

对齐：一木 `budget(budgetname, year, month, num, type, starttime, endtime, bookid)`；昼虎 `budget(periodType, defaultAmount, startTime, endTime)`。

## 2.14 import_mappings（导入 ID 映射 · 幂等核心）

```sql
CREATE TABLE import_mappings (
  id          TEXT PRIMARY KEY,
  provider    TEXT NOT NULL,          -- yimu | zhouhu | qianji
  entity_type TEXT NOT NULL,          -- book|account|category|tag|bill|transfer|lend|refund|reimbursement|instalment|snapshot|budget
  source_id   TEXT NOT NULL,          -- 第三方业务 ID（原样字符串）
  target_id   TEXT NOT NULL,          -- XuPurse UUID
  created_at  INTEGER NOT NULL,
  updated_at  INTEGER NOT NULL,
  UNIQUE(provider, entity_type, source_id)
);
CREATE INDEX idx_mappings_provider ON import_mappings(provider, entity_type);
```

**作用**：
- 同一 `.db` 重复导入 → 命中映射 → 更新而非新增（幂等）。
- diff 计算：本次文件业务 ID 集合 vs 映射集合 → 识别新增 / 删除 / 变更（[算法七](./algorithms.md)）。
- 三家共用一张表，`provider` 区分。

## 3. 导入映射规则速查

| 一木表 → XuPurse | 关键映射 |
|------------------|---------|
| asset → accounts | assetnumber→current_balance；assettype→category；intototalasset→include_in_assets |
| parentcategory/childcategory → categories | parentcategoryid→parent_id |
| tag → tags | parenttagid→group_id |
| bill → bills | billtype(1=收入)→type；cost→amount（×10000）；billid→extra.yimuBillId |
| bill_tags → bill_tags | 拆分逗号 tags |
| transfer → transfers + bills | 转账流水 + 扩展 |
| lend → lends | type、number→amount、interest |
| assethistory → balance_snapshots | currentnum→balance |
| budget → budgets | year/month/num→amount |
| refund/reimbursement/instalment → 对应表 | 直映 |
| accountbook → books | bookname→name（映射 target_id） |

| 昼虎表 → XuPurse | 关键映射 |
|------------------|---------|
| account → accounts | balance→current_balance；notProperty→include_in_assets 取反；disuse 过滤 |
| category → categories | type 映射收支方向 |
| bill → bills | billType；money→amount；transferToId→转账 |
| account_change_log → balance_snapshots | change 累加得余额；type=3 为调账快照 |
| budget → budgets | defaultAmount→amount；periodType→period_type |

| 钱迹表 → XuPurse | 关键映射 |
|------------------|---------|
| account → accounts | type(1资产/5债务)→category；money→current_balance；stype→type |
| category → categories | type(0支出/1收入)；parentId→parent_id |
| bill → bills | type(0支出/1收入/2转账/7债权债务)；money→amount；extra 报销/退款/多币种 → 对应表或 extra JSON |

## 4. 迁移策略

- 每个账本库带 `schema_version`，drift `MigrationStrategy` 增量升级。
- **禁止**：结构变更时删库重建、静默丢字段。
- 金额/币种等全局语义变更时，提供数据修复工具（如旧数据 `×10000` 校正）。

## 5. 与 cent-xyx 的差异（为何"历史包袱小"）

| 项 | cent-xyx | XuPurse |
|----|----------|---------|
| 账户/快照存储 | GlobalMeta JSON 内嵌，随 meta 整体读写 | 独立表 + 索引 |
| 快照位置 | 曾 localStorage（5-10MB 上限） | 账本库独立表 |
| 转账 | 仅 bill.incomeAccountId | bill + transfers 扩展表（手续费/到账） |
| 借贷/报销/退款/分期 | GlobalMeta 临时 JSON | 独立表 + UI + 逻辑闭环 |
| 导入映射 | 每 provider 一个 mapping JSON | 统一 import_mappings 表 |
| 双写 | localStorage + meta 双写易不一致 | 单一数据源（数据库） |
