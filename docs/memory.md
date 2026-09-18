# 项目记忆（Handoff Memory）

> 最后更新：2026-09-18
> 用途：跨会话 / 跨设备继续开发本项目时的上下文速记。详细设计见 `rewrite-plan.md` / `data-model.md` / `algorithms.md`。

## 1. 项目是什么

XuPurse —— 用 Flutter 从 0 重写 cent-xyx 的记账软件（三端 Web / Android / iOS）。
- 技术栈：Flutter + Riverpod + drift + fl_chart + intl + uuid + archive
- 金额单位：**万分之元整数**（1 元 = 10000），仅 UI 层转换，杜绝数量级 bug
- 核心卖点：一木 / 昼虎 / 钱迹 `.db` 文件高保真导入（已全部完成）
- 数据库：每账本一个库 `book-<id>`，全局库存 `books`；结构变更一律走 migration
- 当前版本：`pubspec.yaml` 0.1.0+1；SDK `^3.9.2`

## 2. 路线图现状（对齐 rewrite-plan.md）

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 0 | 工程与数据层（14 张表 / 迁移 / Repository） | ✅ |
| Phase 1 | 记账闭环（记账/转账/调账/趋势）+ 账户管理 | ✅（账户合并、调账、历史快照均有） |
| Phase 2 | 分类 / 标签 / 预算 / 多币种 | ✅ |
| Phase 3 | 统计 / 搜索 / 搜索结果分析 | ✅（统计页刚重构，见 §3） |
| Phase 4 | 特色业务：借贷/报销/退款/分期 | 逻辑✅；UI 为只读列表+删除（ledger_manage_page.dart） |
| Phase 5 | 三家导入 + 预览 + 覆盖/增量 + 账户合并 | ✅（核心价值，已完成） |
| Phase 6 | AI 助手 / 语音记账 | ❌ 未开始 |
| Phase 7 | 局域网同步 | ❌ 未开始 |
| Phase 8 | i18n / 主题 / 备份 / 三端打包 | 进行中：备份✅、主题✅（theme_settings_page + color_picker_dialog）、i18n ❌、打包 ❌ |

> 注意：`rewrite-plan.md` 里的复选框落后于代码实际进度，以代码为准。

## 3. 最近一次改动（本次会话）

**A. 统计页重构**：[lib/ui/pages/statistics_page.dart](lib/ui/pages/statistics_page.dart)

用户反馈原统计页太简易，重构为「侧边栏分区 + 日期范围下拉」：

- **自适应布局**：宽度 ≥640px 左侧 NavigationRail 常驻；窄屏自动切为顶部横向滑动 ChoiceChip Tab
- **日期范围下拉**（AppBar bottom 常驻）：
  - 预设：本月 / 上月 / 本年 / 去年 / 最近一周
  - 自定义：`showDateRangePicker`，**下界 = 最早账单时间**（`minBillTime()`），上界 = 今天
  - 显示实际起止日期小字；全部分区共用同一范围
- **5 个分区**：
  1. 总览：收支/结余 KPI + 环比对比卡（与等长上期对比）+ 日均
  2. 分类：支出占比 + 收入占比（两张大饼图，Top5+其他）
  3. 趋势：支出柱状图，粒度随范围自适应（≤14 天按日 / ≤62 天按周 / 其余按月）
  4. 预算：预算执行进度（原逻辑迁移）
  5. 标签：标签支出 Top 横向条形图（新增）
- 用户确认「本期先做」的分区：**总览 / 分类 / 标签**；趋势 / 预算为既有内容迁移；**账户 / 高级分区未做**（可后续补）

**数据层新增**：[lib/data/repositories/bill_repository.dart](lib/data/repositories/bill_repository.dart)
- `minBillTime()`：最早账单时间（毫秒，无账单返回 null）
- `sumByTagInRange(start, end, type)`：JOIN bill_tags 按标签汇总金额

**验证状态**：`flutter analyze` 0 问题；`flutter test` 91 个用例全过。

**B. 搜索偏少 Bug 修复**：[lib/ui/pages/search_page.dart](lib/ui/pages/search_page.dart)
- 现象：首页明细右上角搜索关键词（如「碧蓝航线」）结果明显偏少
- 根因：关键词只匹配备注 + 叶子分类名；**标签完全没参与搜索**，父分类名也不匹配
- 修复：关键词同时匹配 备注 / 叶子分类名 / 父分类名 / 标签名；新增 `_allBillTagsProvider`（revision 联动）一次性取账单-标签关联

## 4. 下一步待办（按优先级）

1. **人工验证统计页**：`flutter run -d chrome` 看下宽/窄屏两种形态、5 个分区、日历自定义范围
2. 统计页可选补充：账户分区（余额构成/收支排行）、高级分区（最大回撤/波动率/储蓄率，口径见 algorithms.md 算法五）
3. 特色业务 UI 补全（借贷/报销/退款/分期目前只有只读列表+删除，见 ledger_manage_page.dart）
4. Phase 6 AI 助手 / 语音记账（本地分类预测参考 cent-xyx `linear-predict`）
5. Phase 7 局域网同步（参考 cent-xyx `sync-server.js`）
6. Phase 8 i18n 中英词条（**必须先读下方 i18n 规则**）、三端打包、全量回归

## 5. 必须遵守的约定

### git 操作（用户规则）
- **严禁 AI 主动 git commit / git push**；push 只能用户自己做
- 用户允许的 commit 是**一次性**许可，每次都要重新授权

### i18n 词条（用户规则，Phase 8 开工前必读）
- 各语言词条数量必须一致；不一致要主动排查
- **原词条不可动**（翻译公司已翻译，一个字、一个空格都不能改）
- 改文案 = **新增词条**：原 key 加 `V2` 后缀（再改加 V3…），追加在文件最底部
- 占位符 `{{ }}` / `[[ ]]` 内部内容不翻译、不改动

### 架构约定（rewrite-plan.md §2）
- 数据库是唯一事实来源，Riverpod 只做只读缓存
- 账单 + 账户余额 + 快照同一事务；快照 billId 先定后写
- 导入幂等（ID 映射 + diff）；导入账单打来源标记，重算时跳过
- 以用户输入的账户余额为权威（不强制与账单一致）

## 6. 关键文件索引

| 文件 | 说明 |
|------|------|
| docs/rewrite-plan.md | 总路线图（分阶段，带验收标准） |
| docs/data-model.md | 14 张表权威设计 |
| docs/algorithms.md | 算法一~八（余额联动/调账/重算/总资产/趋势/导入/合并） |
| docs/changelog.md | 版本变更记录 |
| lib/ui/pages/statistics_page.dart | 统计页（本次重构） |
| lib/ui/pages/ledger_manage_page.dart | 特色业务（借贷/报销/退款/分期）只读列表 |
| lib/ui/pages/theme_settings_page.dart | 主题/深色模式（含 color_picker_dialog.dart 取色器） |
| lib/data/repositories/bill_repository.dart | 账单查询（新增 minBillTime / sumByTagInRange） |
| lib/state/providers.dart | 全局 Provider 清单 |
| lib/domain/services/trend_service.dart | 资产趋势（算法五，快照+二分） |

## 7. 近期提交参考（git log 风格）

- `fix: 趋势页近 30/90 天期初锚点缺失导致数据失真`（算法五期初锚点）
- `feat: 导入预览弹窗 + 覆盖/增量模式（Phase 5 收尾）`
- `feat: 多币种记账闭环 + 统计搜索分析（Phase 1/2/3 收尾）`
- 本次统计页重构尚未提交（等用户授权 commit）
