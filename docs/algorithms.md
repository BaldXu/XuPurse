# 重要算法实现说明

> 状态：📚 继承自 cent-xyx，算法思路已在上一代验证。本文给出各关键算法的输入、输出、步骤与复杂度，供 Flutter 重写直接落地。

## 目录

- [算法一：余额变动联动](#算法一余额变动联动)
- [算法二：手动调账](#算法二手动调账)
- [算法三：余额重算](#算法三余额重算)
- [算法四：总资产计算与汇率折算](#算法四总资产计算与汇率折算)
- [算法五：资产趋势计算（快照 + 二分查找）](#算法五资产趋势计算快照--二分查找)
- [算法六：增量存储（Stash / dense）](#算法六增量存储stash--dense)
- [算法七：第三方导入 diff 与幂等](#算法七第三方导入-diff-与幂等)
- [算法八：同名账户合并检测](#算法八同名账户合并检测)

---

## 算法一：余额变动联动

**触发**：账单 新增 / 修改 / 删除。

**输入**：账单 `Bill`、账户表 `accounts`。

**核心**：`getAccountDelta(bill, amount)` 计算对主账户（`accountId`）的余额增量：

```
expense  → -amount
transfer → extra.yimuTransferDirection == "out" ? -amount : +amount
income   → +amount
```

**步骤**：

1. 对 `accountId`：
   - 若账单为 expense：`balance -= amount`
   - 若为 transfer：按方向减/加
   - 若为 income：`balance += amount`
2. 对 `incomeAccountId`（转账转入账户）：始终 `balance += amount`
3. 创建对应类型快照（EXPENSE / INCOME / TRANSFER_OUT / TRANSFER_IN）。
4. 删除 / 修改时先「反向应用」旧账单影响，再「正向应用」新账单影响。

**跨币种**：先按 `bill.currency`（记账币种）→ 账户币种换算后再变动余额。

**批量化**：批量账单处理时，先汇总所有账户的净变化 `Map<accountId, delta>`，再一次性写库 + 批量建快照。

**注意**：快照 `billId` 必须与最终落库的账单 ID 一致（先定 ID 后写库）。

---

## 算法二：手动调账

**入口**：`setAccountBalance(accountId, newBalance, note?)`。

**步骤**：

1. 读当前 `currentBalance`。
2. 计算 `diff = newBalance - currentBalance`。
3. 若 `diff == 0`：直接返回，不产生任何记录。
4. 若 `diff != 0`：
   - 生成调账账单：
     - `type = diff > 0 ? income : expense`
     - `categoryId = diff > 0 ? balance_adjustment_income : balance_adjustment_expense`
     - `amount = abs(diff)`
     - `extra.isAdjustment = true`
   - 更新 `currentBalance = newBalance`。
   - 生成 MANUAL(5) 快照。

**设计意图**：保留调整历史，让流水完整可追溯；调账账单在余额重算中被排除。

---

## 算法三：余额重算

**入口**：`recalculateAllBalances()`（危险操作）。

**步骤**：

1. 所有账户重置：`currentBalance = initialBalance`。
2. 遍历**全部非调账、非第三方导入**账单：
   - `accountId`：按算法一累加增量。
   - `incomeAccountId`：`balance += amount`。
3. 覆盖写入所有账户余额。

**跳过规则**：

```
跳过条件：
  bill.extra.isAdjustment == true   // 调账账单
  bill.extra.isYimu == true         // 一木导入账单（currentBalance 以第三方权威值为准）
  bill.extra.isZhouhu == true
  bill.extra.isQianji == true
```

**警示**：会覆盖所有手动矫正，仅用于刚导入大量历史数据或数据异常时。

---

## 算法四：总资产计算与汇率折算

**公式**（以 CNY 为锚）：

```
rate[code] = code 对 CNY 的汇率（可被 currencyOverrides 覆盖）
convert(amount, from, to) = amount * rate[to] / rate[from]
```

**总资产**：

```
totalAssets = Σ convert(account.currentBalance, account.currency, baseCurrency)
              over accounts 满足：
                enabled
                （!bookId || bookId == currentBookId）
                类别为 fund
                OR (类别为 debt/record 且 includeInAssets == true)
```

**坑**：汇率公式曾写反（`baseRate / jsonRate`），导致 100 USD 被算成 13.79 CNY。重写必须用 `rate[to] / rate[from]`。

---

## 算法五：资产趋势计算（快照 + 二分查找）

**输入**：有效快照、资产账户、时间范围 `[start, end]`、粒度（day/week/month）。

**步骤**：

1. **粒度 key**：
   - day → 当天 0 点
   - week → 本周周一 0 点
   - month → 当月最后一天 23:59:59.999（展示月末余额）
2. 对每个资产账户：
   - 按时间升序排列其有效快照。
   - 额外加入 `start` 之前最近一条快照（作为期初值）。
3. 收集范围内所有时间 key（`start`/`end` 也生成点），升序排序。
4. 对每个时间 key，对每个账户**二分查找**「最后一条 `timestamp <= key`」的快照，取其余额折算后求和。

**复杂度**：`O(A × K × log S)`，其中 A=账户数、K=时间点数、S=单账户快照数。相比「每点全量遍历」（O(n²)）显著优化，避免大数据量卡顿。

**统计口径**：
- 期间变化 = 期末总资产 − 期初总资产
- 最高/最低 = 期间各时间点总资产的极值（并纳入当前值）
- 平均存款/支出/收入 = 各自合计 / 时间单位数

**高级统计**：
- 最大回撤：遍历趋势序列维护峰值，`drawdown = peak - current` 取最大，百分比 = 最大回撤 / 峰值。
- 波动率：相邻点日收益率的标准差。
- 涨跌次数：相邻点余额升/降计数。

---

## 算法六：增量存储（Stash / dense）

> 上一代核心存储抽象（`StashBucket`），Flutter 版可简化为「数据库直接落库 + 备份导出」，但了解其思路有助于设计同步/导入。此处保留说明。

**四类存储**：

| 名称 | 内容 |
|------|------|
| `__stashes` | 操作日志（update / delete / meta） |
| `__items` | 完整数据快照（合并 stash 后的结果） |
| `__meta` | GlobalMeta |
| `__config` | 本地额外配置 |

**写入流程 `batch(actions)`**：

1. 为每个 action 补 `id`（uuid）与 `timestamp`。
2. 若含 meta 更新：先读当前 meta，计算 **diff**（`diffMeta(prev, current)`）后再存，减小体积。
3. 与历史 stash 合并后 **dense**（`denseStashes`）：对同一目标 ID（账单 id / `_meta`）只保留最新一条 action。
4. 清空旧 stash，写入 dense 后的新 stash。
5. `applyStash`：把 update 批量写 items、delete 批量删 items。

**读取**：`getMeta()` = 远端 meta 叠加最新一条 meta stash 的 diff（`mergeMeta`）。

**覆盖模式（overlap）**：清空 items 后重写，用于「导入覆盖」场景（如首次第三方导入）。

> 核心价值：每次只保存增量，同步时只需传差异；dense 保证同 ID 只留最新，避免体积膨胀。

---

## 算法七：第三方导入 diff 与幂等

**目标**：同一 `.db` 文件重复导入不产生重复数据，且能识别新增/删除/变更。

**输入**：解析后的第三方数据、持久化 ID 映射（`yimuMapping` 等）、现有 GlobalMeta。

**步骤**：

1. **映射**：第三方表行 → XuPurse 实体，金额 `*10000`；为每个第三方业务 ID 生成/复用 UUID，写入映射表。
2. **diff**：基于映射比较当前文件与上次导入：
   - `presentIds` = 本次文件所有业务 ID 集合
   - 映射中存在但本次不在 → 判定删除（仅覆盖模式生效）
   - 映射中不存在 → 新增
   - 存在且内容变更 → 更新
3. **预览**：展示新增/更新/删除统计，用户确认。
4. **写入**：
   - GlobalMeta 一次写入（含映射、账户、分类、标签、预算、快照、扩展实体）。
   - 账单批量写入（`extra` 打来源标记，不触发余额自动加减）。
   - 以第三方权威余额覆盖 `currentBalance`。

**幂等保证**：映射表持久化在账本 meta 中，重复导入按 `billid / assetid / categoryid...` 命中已有 UUID，改为更新而非新增。

---

## 算法八：同名账户合并检测

**输入**：现有账户列表、本次导入的新账户列表、现有账单、新账单。

**步骤**：

1. **归一化名称**：`normalizeAccountName`（去空格、括号、卡号尾号、大小写等），按归一化名分组。
2. 组内两两配对（现有 × 新），判断时间冲突：
   - 计算每个账户关联账单的时间范围 `[minTime, maxTime]`。
   - 新旧时间范围**重叠** → `hasConflict = true`（不可自动合并）。
3. 生成候选：
   - `source` = 更新时间更早的一方，`target` = 更新更晚的一方。
   - `autoMerge = !hasConflict`。
4. 用户确认后：
   - 合并映射 `source.id → target.id`。
   - 替换账单 `accountId` / `incomeAccountId`、快照 `accountId`、meta 中 transfers/lends/reimbursements/instalments 的账户引用。
   - 删除源账户，保留目标账户余额与初始余额。

**作用**：解决「第三方软件里叫『支付宝』、XuPurse 里也叫『支付宝』」但实际是同一账户的重复问题。
