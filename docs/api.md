# API 接口文档

> 状态：🚧 规划中。XuPurse 是本地优先应用，**不存在服务端 HTTP API**；本文件定义的是内部服务层接口契约与跨端公共 API（导入、汇率、同步），并标注其与上一代 cent-xyx 实现的对应关系。

## 1. 接口总览

| 接口族 | 位置（规划） | 说明 |
|--------|--------------|------|
| 存储层接口 | `data/repositories/` | 账本、账单、元数据的 CRUD 与批量操作 |
| 导入接口 | `data/sources/` | 一木 / 昼虎 / 钱迹 数据库解析与映射 |
| 汇率接口 | `domain/services/currency_service.dart` | 汇率表查询、换算、覆盖 |
| 预测接口 | `domain/services/predict_service.dart` | 分类 / 备注预测（本地模型） |
| 同步接口 | `domain/services/sync_service.dart` | 局域网同步（P2 规划） |

> 金额约定：**所有接口入参/出参金额均为整数「万分之元」**（1 元 = 10000），除非显式标注单位。

---

## 2. 存储层接口

### 2.1 账本（Book）接口

| 方法 | 入参 | 返回 | 说明 |
|------|------|------|------|
| `fetchAllBooks()` | - | `List<Book>` | 列出全部账本 |
| `createBook(name)` | `String name` | `Book` | 新建账本（含初始化数据库） |
| `deleteBook(id)` | `String id` | `void` | 删除账本（级联删除账户/快照） |
| `switchToBook(id)` | `String id` | `void` | 切换当前数据源 |
| `getMeta(bookId)` | `String bookId` | `GlobalMeta` | 读取账本元数据 |
| `updateGlobalMeta(meta)` | `GlobalMeta` | `void` | 整体写入元数据 |

### 2.2 账单（Bill）接口

| 方法 | 说明 |
|------|------|
| `addBill(bill)` | 新增单笔（自动联动账户余额 + 创建快照） |
| `addBills(bills)` | 批量新增（批量余额变动 + 批量快照，只写一次 meta） |
| `updateBill(id, entry)` | 修改单笔（撤销旧影响 → 应用新影响 → 失效旧快照 → 建新快照） |
| `updateBills(entries)` | 批量修改 |
| `removeBill(id)` / `removeBills(ids)` | 删除（撤销余额影响 + 失效快照） |
| `refreshBillList()` | 全量刷新内存中的账单列表（大数据量走隔离层） |

> **批量化要求**：任何批量操作必须聚合后**单次写库**（一次事务/一次 meta 写入），禁止逐条 `await` 串行写，否则大数据量会卡死 UI。

### 2.3 账户（Account）接口

| 方法 | 说明 |
|------|------|
| `addAccount(data)` | 新增账户（`currentBalance = initialBalance`） |
| `updateAccount(id, data)` | 更新字段 |
| `deleteAccount(id)` | 删除（关联账单账户字段置空，不删账单） |
| `updateAccountBalance(accountId, amount)` | 增减余额（记账联动用） |
| `setAccountBalance(accountId, newBalance, note?)` | **手动调账**：计算差值、更新余额、自动生成调账账单 |
| `recalculateAllBalances()` | 重置为初始余额并按非调账账单重算（危险操作） |
| `getEnabledAccounts()` | 当前账本启用账户 |
| `getAssetAccounts()` | 计入总资产的账户 |
| `calculateTotalAssets()` | 按本位币折算的总资产 |
| `mergeAccounts(sourceId, targetId)` | 合并账户（迁移账单/快照/扩展实体） |

### 2.4 快照（BalanceSnapshot）接口

| 方法 | 说明 |
|------|------|
| `createBalanceSnapshot(accountId, note?, billId?, type?)` | 自动快照 |
| `createHistoricalSnapshot(accountId, balance, timestamp, note?)` | 历史快照（type=6） |
| `invalidateSnapshotsByBillId(billId)` | 账单删除/修改后标记快照失效 |
| `getBalanceHistory(accountId, start?, end?, includeInvalid?)` | 查询余额历史 |
| `restoreBalanceFromSnapshot(snapshot)` | 从快照恢复余额 |
| `deleteSnapshot(id)` | 删除快照 |

### 2.5 事务性要求

上一代曾出现「localStorage 与 meta 双写不一致」问题。Flutter 版规则：

1. **数据库是唯一事实来源**，状态层只读缓存。
2. 「账单 + 余额 + 快照」三者变更必须处于**同一事务**内，要么全部成功要么全部回滚。
3. meta 中 `accounts` / `balanceSnapshots` 与业务表始终一致，任何账户/快照操作同步更新 meta。

---

## 3. 导入接口

### 3.1 通用流程接口

| 方法 | 入参 | 返回 | 说明 |
|------|------|------|------|
| `previewImport(provider, file)` | 来源 + .db 文件 | `ImportPreview` | 解析 → 映射 → 差异计算，返回预览 |
| `importFromProvider(data, overlap)` | 预览确认后的数据 | `void` | 写入账本 |

`ImportPreview` 结构：

```dart
class ImportPreview {
  Map<String, int> parsedSummary;   // 各表行数统计
  GlobalMeta meta;                  // 映射后的账户/分类/标签/预算/扩展实体
  List<Bill> bills;                 // 映射后的账单
  List<BalanceSnapshot> snapshots;  // 映射后的快照
  ImportDiff diff;                  // 新增/删除/变更统计（基于 ID 映射）
  List<AccountMergeCandidate> accountMergeCandidates; // 同名账户合并候选
}
```

### 3.2 差异计算（ImportDiff）

`diff` 基于持久化的 ID 映射表（`yimuMapping` / `zhouhuMapping` / `qianjiMapping`），比较当前导入文件与上次导入的差异：

| 项 | 说明 |
|----|------|
| `created` | 新出现的业务 ID |
| `updated` | 已存在但内容变更 |
| `deleted` | 本次文件已不存在的 ID（可选，仅覆盖模式生效） |

**作用**：同一文件重复导入不产生重复数据。

### 3.3 各来源入参约束

| 来源 | 文件类型 | 解析依赖 | 覆盖模式 |
|------|---------|----------|---------|
| 一木 | `Custom.db` | SQLite（原生 / WASM） | 支持 |
| 昼虎 | 任意 SQLite db | 同上 | 支持 |
| 钱迹 | 任意 SQLite db | 同上 | 支持 |

> Web 端依赖 WASM 加载 SQLite；必须显式提供 wasm 文件路径，避免静态资源服务器返回 HTML 导致 "wasm magic word" 错误。

---

## 4. 汇率接口

### 4.1 汇率表

内置汇率数据（等价于上一代 `exchange-rates.json`），锚定货币为 CNY。

```dart
class ExchangeRateService {
  double? getRate(String currencyCode);      // 该货币对 CNY 的汇率
  int convert(int amount, String from, String to); // 万分之元换算
  Color getCurrencyColor(String code);        // 币种展示色
}
```

### 4.2 换算公式

```
convert(amount, from, to) = amount * rate[to] / rate[from]
```

> 上一代曾因公式写反导致 100 USD 被算成约 13.79 CNY（正确应为约 725 CNY）。重写时必须使用上述公式并以 CNY 为锚。

### 4.3 手动覆盖

- `currencyOverrides: Map<String, double>` 按账本持久化。
- 覆盖值优先于内置汇率表，但不影响币种展示色。
- 覆盖后需刷新依赖汇率的展示（总资产、趋势、账单换算）。

---

## 5. 预测接口（本地模型）

| 方法 | 说明 |
|------|------|
| `learn(bills, timeRange)` | 用新增账单增量训练线性回归模型 |
| `predict(target, time)` | 按时间预测：`category`（分类）或 `comment`（备注） |
| `getPredictMeta()` / `clear()` | 模型元信息 / 清空模型 |

预测入口：新建账单时（记账界面），读取 `predict().category[0]` 推荐分类。

---

## 6. 同步接口（局域网，P2 规划）

> 上一代实现为 Express 服务（`sync-server.js`，局域网 IP 广播 + HTTP 增量同步）。Flutter 版接口预留：

| 方法 | 说明 |
|------|------|
| `startSyncServer()` | 启动局域网服务 |
| `syncPull(remoteUrl)` | 从远端拉取增量 |
| `syncPush(remoteUrl)` | 向远端推送增量 |
| `onSyncProgress(callback)` | 同步进度回调 |

---

## 7. 第三方数据库 Schema 参考

各来源解析所需的表结构在重写时参照上一代 parser 实现，关键表汇总：

### 7.1 一木（Custom.db）

| 表 | 关键字段 |
|----|---------|
| asset | assetid, assetname, assettype, assetnumber, currency, bookid, intototalasset, delete_lpcolumn |
| parentcategory / childcategory | categoryid, categoryname, categorytype, parentcategoryid |
| bill | billid, billtype, cost, recordtime, assetid, parentcategoryid, childcategoryid, remark |
| bill_tags | bill_id, tags |
| transfer | transferid, fromassetid, toassetid, cost, tocost, servicecharge, time |
| lend | lendid, type, assetid, repaymentassetid, number, interest, billid |
| assethistory | assethistoryid, assetid, currentnum, changenum, time |
| budget | budgetid, budgetname, year, month, num, type, starttime, endtime |
| refund / reimbursement / instalment | 关联 billid / assetid 的结构 |

### 7.2 昼虎

| 表 | 关键字段 |
|----|---------|
| account_book | id, name, icon |
| account | id, name, accountType, currencyCode, balance, notProperty, disuse |
| category | id, name, type, accountBookId |
| bill | id, billType, accountId, transferToId, categoryId, money, createTime |
| account_change_log | id, accountId, billId, change, type, createTime |
| budget | id, name, periodType, defaultAmount, startTime, endTime |

### 7.3 钱迹

| 表 | 关键字段 |
|----|---------|
| account_book | bookId, name, type, userId |
| account | id, name, type(1=资产 5=债务), stype, money, currency, extra, loanInfo |
| category | id, name, type(0=支出 1=收入), parentId, level |
| bill | billid, time, type(0=支出 1=收入 2=转账 7=债权债务), money, assetId, fromId, targetId, categoryId, extra |
