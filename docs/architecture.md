# 项目架构说明

> 状态：✅ 已实现（2026-09-17 制定，主体架构已落地）。本文描述 XuPurse（Flutter 重写版）的架构，数据模型与业务规则继承自 cent-xyx 的实测结论。

## 1. 项目背景

| 项 | 说明 |
|----|------|
| 项目名 | XuPurse |
| 上一代实现 | cent-xyx（React 19 + Vite 8 + Zustand + IndexedDB），基于开源项目 [Cent](https://github.com/glink25/Cent) 二次开发 |
| 重写动机 | 上代开发一个多月后，代码质量与架构可控性不满足预期，效果不佳 |
| 技术栈 | Flutter（Dart），实现 Web / Android / iOS 三端 |
| 核心卖点 | 适配一木 / 昼虎 / 钱迹三家第三方软件的 SQLite 数据库导入 |

## 2. 技术选型

| 层级 | 选型 | 说明 |
|------|------|------|
| UI 框架 | Flutter | 三端同一套代码 |
| 状态管理 | Riverpod | 替代上一代 Zustand |
| 本地存储 | drift（sqflite 包装） | Web 端自动降级为 IndexedDB 实现；替代上一代 IndexedDB + StashBucket |
| 数据库导入 | sqlite3 / sqflite_ffi + WASM | Web 端通过 WASM 加载 sql.js 兼容文件 |
| 图表 | fl_chart | 替代 ECharts |
| 多语言 | Flutter 官方 intl / ARB | 替代 react-intl |
| 图标 | colorful_iconify_flutter + flutter_svg（twemoji） | 替代 iconify mdi 语法 |
| 本地化日期 | intl 包 | 替代 dayjs |

## 2.1 范围与关键决策（2026-09-17 确认）

| 决策 | 结论 |
|------|------|
| 附加功能保留 | ✅ 局域网同步、AI 助手 / 语音记账 |
| 附加功能暂缓 | ❌ 地图可视化、周期记账（不在 v1） |
| 一木特色业务 | ✅ 完整支持（借贷 / 退款 / 报销 / 分期 / 完整转账） |
| 多币种 | ✅ 完整支持 |
| 金额单位 | **万分之元整数**（1 元 = 10000），与三方「元」无损换算 |
| 数据模型基准 | 一木记账（业务蓝本）+ 昼虎 / 钱迹字段全覆盖 |
| 旧数据 | 不迁移 cent-xyx 数据，从 0 开始 |

> 数据库表设计的权威文档见 [数据模型与表结构](./data-model.md)。

## 3. 总体分层架构

```
┌─────────────────────────────────────────────────────────┐
│  UI 层（pages / widgets / components）                  │
│  首页账单 · 搜索 · 统计 · 账户 · 趋势 · 设置             │
├─────────────────────────────────────────────────────────┤
│  状态管理层（providers / stores）                        │
│  BookProvider · LedgerProvider · AccountProvider ·      │
│  CurrencyProvider · PreferenceProvider                   │
├─────────────────────────────────────────────────────────┤
│  业务逻辑层（services / domain）                         │
│  余额计算 · 快照管理 · 调账 · 导入映射 · 汇率换算 · 趋势 │
├─────────────────────────────────────────────────────────┤
│  数据访问层（repositories）                              │
│  BookRepository · BillRepository · MetaRepository ·     │
│  ImportRepository · SyncRepository                       │
├─────────────────────────────────────────────────────────┤
│  存储层（drift / IndexedDB / SQLite）                    │
│  每个账本(Book) = 一个独立数据库（book-<id>）            │
└─────────────────────────────────────────────────────────┘
```

### 分层原则

1. **UI 层不直接访问数据库**，一律通过 Repository / Provider。
2. **业务规则集中在 Service**，例如余额变动只能通过 `AccountService`，禁止在 Widget 中直接改 `currentBalance`。
3. **金额统一用整数「万分之元」** 在业务层传递，仅 UI 层做展示转换（见代码规范）。

## 4. 核心概念

### 4.1 Book（账本）与 Ledger（账单）

| 概念 | 说明 |
|------|------|
| Book（账本） | 数据隔离的顶层单位，对应一个独立数据库 `book-<id>`。切换账本即切换数据源 |
| Ledger（流水） | 单个 Book 内的账单列表 |

> 记忆口诀：**Book 是文件夹，Ledger 是文件夹里的账单列表。**

### 4.2 账户三大类

| 类别 | 含义 | 是否计入总资产 |
|------|------|---------------|
| fund（资金账户） | 现金、银行、支付宝、微信、信用卡等 | ✅ 默认计入 |
| record（记录账户） | 公积金、投资、黄金等资产记录 | ⚠️ 可配置（`includeInAssets`） |
| debt（债务账户） | 借贷、应付款项 | ⚠️ 可配置（`includeInAssets`） |

### 4.3 余额权威值设计（核心设计理念）

- **`Account.currentBalance` 是权威值**，总资产计算直接使用它，不以账单反推。
- 用户每月初核对实际余额并手动矫正 → 系统自动生成「调账账单」（`extra.isAdjustment = true`）保留历史。
- **允许账单与余额有差异**（用户遗漏、手续费、四舍五入等），系统绝不自动"修复"用户的手动矫正。
- 「重新计算余额」是危险操作，会覆盖所有手动调整，仅用于导入大量历史数据后。

## 5. 数据模型

> **完整表结构（DDL）、字段对齐三方、导入映射规则见 [数据模型与表结构](./data-model.md)**，本节省略字段级细节，只保留核心概念。

### 5.1 存储结构

| 数据库 | 内容 |
|--------|------|
| 全局库 `xupurse.db` | 账本列表（books）、应用设置 |
| 账本库 `book-<id>.db` | 一个账本全部业务数据（每账本独立库） |

### 5.2 表清单

accounts（账户）· categories（分类）· tags / tag_groups（标签）· bills（账单）· bill_tags · balance_snapshots（余额快照）· transfers（转账扩展）· lends（借贷）· refunds（退款）· reimbursements（报销）· instalments（分期）· budgets（预算）· import_mappings（导入 ID 映射）

### 5.3 Bill（账单）

> 说明：以下为概念模型示意，字段已按表设计统一（多币种改为 `currency_code / currency_amount / base_currency` 扁平字段，转账扩展独立 `transfers` 表），**实际以 data-model.md 为准**。

```dart
class Bill {
  String id;
  BillType type;            // income | expense | transfer
  String categoryId;        // 单分类（父类或子类）
  String creatorId;
  int amount;               // 万分之元
  int time;                 // 毫秒时间戳
  String? comment;
  List<dynamic>? images;    // File 或 String(URL)
  GeoLocation? location;
  List<String>? tagIds;
  String? accountId;        // 支出 / 转出账户
  String? incomeAccountId;  // 存在即视为转账（转入账户）
  BillCurrency? currency;   // { base, target, amount } 多币种
  BillExtra? extra;         // scheduledId / isAdjustment / isYimu / isZhouhu / isQianji 等
}
```

关键规则：
- `incomeAccountId` 存在 → 该账单为**转账**：`accountId` 减少，`incomeAccountId` 增加。
- `extra.isAdjustment == true` → 调账账单，参与流水展示，但在余额重算时被排除。

### 5.2 Account（账户）

```dart
class Account {
  String id;
  String? bookId;
  String name;
  AccountCategory category;  // fund | record | debt
  AccountType type;          // alipay | wechat | bank | cash | credit | investment | other
  String? icon;
  String? color;
  int initialBalance;        // 初始余额
  int currentBalance;        // 当前余额（权威值！）
  String? currency;          // 默认 CNY
  String? remark;
  bool enabled;
  bool? includeInAssets;     // debt/record 是否计入总资产
  int? creditLimit;          // 信用额度
  String? cardCode;          // 卡号
  int? statementDate;        // 账单日
  int? repaymentDate;        // 还款日
  int? yimuAssetId;          // 一木原始 ID（导入映射）
  int? zhouhuAccountId;      // 昼虎原始 ID
  int? qianjiAssetId;        // 钱迹原始 ID
  int createdAt;
  int updatedAt;
}
```

### 5.3 BalanceSnapshot（余额快照）

```dart
class BalanceSnapshot {
  String id;
  String accountId;
  int balance;         // 快照时点余额
  int timestamp;
  String? note;
  bool? isValid;       // 关联账单被删/改时标为 false
  String? billId;      // 产生快照的账单
  int? type;           // SnapshotType 常量
  int? yimuAssetHistoryId;
}
```

快照类型常量：

| 值 | 含义 |
|----|------|
| 1 | EXPENSE 记账消费 |
| 2 | INCOME 记账收入 |
| 3 | TRANSFER_OUT 转账转出 |
| 4 | TRANSFER_IN 转账转入 |
| 5 | MANUAL 手动调整 |
| 6 | HISTORICAL 历史快照（用户手动添加的时间点） |

快照生命周期：记账/转账/调账自动创建 → 账单删除/修改时 `isValid=false` → 趋势图只读有效快照。

### 5.4 GlobalMeta（账本级元数据）

随账本存储在数据库 meta 中，包含：

```dart
class GlobalMeta {
  List<BillCategory>? categories;   // 自定义分类
  List<BillTag> tags;               // 自定义标签
  List<Account>? accounts;          // 账户列表
  List<BalanceSnapshot>? balanceSnapshots;
  String? baseCurrency;             // 本位币，默认 CNY
  List<CustomCurrency>? customCurrencies;
  Map<String, double>? currencyOverrides;  // 按账本隔离的汇率覆盖
  List<Budget>? budgets;
  List<BillFilterView>? customFilters;
  List<Transfer>? transfers;        // 一木转账
  List<Lend>? lends;                // 一木借贷
  List<Refund>? refunds;            // 一木退款
  List<Reimbursement>? reimbursements; // 一木报销
  List<Instalment>? instalments;    // 一木分期
  YimuMapping? yimuMapping;         // 一木业务 ID → UUID
  ZhouhuMapping? zhouhuMapping;
  QianjiMapping? qianjiMapping;
}
```

## 6. 目录结构（当前实际）

```
lib/
├── main.dart                 # 入口
├── main_profile.dart         # 真机性能采集入口（flutter run --profile -t lib/main_profile.dart）
├── core/                     # 通用：常量、错误、工具（金额/ID/图标/twemoji）
│   ├── constants/            # enums
│   ├── utils/                # amount / ids / bill_extra / twemoji_icons ...
│   └── errors.dart           # 领域异常体系
├── data/                     # 数据访问层
│   ├── database/             # drift 表定义、app/global 数据库、迁移、账本工厂
│   ├── repositories/         # account / bill / budget / category / ledger / snapshot / tag
│   ├── import/               # 三方解析器（yimu/zhouhu/qianji）+ 映射 + diff + ID 映射
│   ├── backup/               # 备份导出/导入（saver_io / saver_web）
│   └── seed/                 # 默认账户 / 分类种子
├── domain/                   # 业务逻辑
│   ├── services/             # account / bill / currency / trend
│   └── ai/                   # AI 助手（配置 + 服务）
├── state/                    # Riverpod providers（theme / icon_pack / providers）
└── ui/                       # 页面与组件
    ├── layout/               # 页面壳、懒挂载、异步视图、转场 mixin
    ├── pages/                # home / accounts / statistics / mine + 二级页
    ├── tokens/               # design_tokens（色/圆角/间距/动效唯一来源）
    ├── widgets/              # Xp 组件族（card/fab/sheet/skeleton/frosted_bar/...）
    └── theme.dart            # 主题装配 + XpRoute 转场
```

## 7. 与上一代（cent-xyx）的关键差异

| 维度 | cent-xyx（React） | XuPurse（Flutter） |
|------|------------------|--------------------|
| 金额单位 | 万分之元（沿用） | 万分之元（沿用） |
| 存储 | IndexedDB + StashBucket 增量 | drift / SQLite，每账本一个库 |
| 快照 | 曾存 localStorage（有 5-10MB 上限），后迁移到 meta | 直接入账本数据库 |
| 路由 | MemoryRouter（与地址栏脱钩） | Flutter 自带 Navigator |
| 状态 | Zustand 双写（localStorage + meta）易不一致 | 单一数据源（数据库），状态层只做缓存 |
| 导入 | sql.js（WASM） | sqlite3 原生 / WASM |
| 云同步 | 已剔除，仅局域网同步 | 默认本地，保留局域网同步规划 |

## 8. 设计上必须遵守的红线

1. 金额一律整数万分之元，UI 显示 `amount / 10000`，输入存储 `amount * 10000`。
2. 禁止绕过 Service 直接修改 `Account.currentBalance`。
3. 账户/快照修改后必须同步写回 GlobalMeta（单一事实来源）。
4. 调账账单必须标记 `extra.isAdjustment = true`。
5. 新增自定义分类必须 `customName = true`。
6. 一木导入后 `initialBalance` 不得参与重算累加（详见 FAQ 与算法文档）。
