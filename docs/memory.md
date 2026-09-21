# 项目记忆（Handoff Memory）

> 最后更新：2026-09-21
> 用途：跨会话 / 跨设备继续开发本项目时的上下文速记。详细设计见 `rewrite-plan.md` / `data-model.md` / `algorithms.md` / `ui-refactor-plan.md`。

## 1. 项目是什么

XuPurse —— 用 Flutter 从 0 重写 cent-xyx 的记账软件（三端 Web / Android / iOS）。
- 技术栈：Flutter + Riverpod + drift + fl_chart + intl + uuid + archive
- 金额单位：**万分之元整数**（1 元 = 10000），仅 UI 层转换，杜绝数量级 bug
- 核心卖点：一木 / 昼虎 / 钱迹 `.db` 文件高保真导入（已全部完成）
- 数据库：每账本一个库 `book-<id>`，全局库存 `books`；结构变更一律走 migration
- 当前版本：`pubspec.yaml` 0.1.0+1；SDK `^3.9.2`
- 真机：小米 23127PN0CC（adb id 会变，用 `adb devices` 确认）

## 2. 路线图现状（对齐 rewrite-plan.md）

| 阶段 | 内容 | 状态 |
|------|------|------|
| Phase 0 | 工程与数据层（14 张表 / 迁移 / Repository） | ✅ |
| Phase 1 | 记账闭环（记账/转账/调账/趋势）+ 账户管理 | ✅（账户合并、调账、历史快照均有） |
| Phase 2 | 分类 / 标签 / 预算 / 多币种 | ✅ |
| Phase 3 | 统计 / 搜索 / 搜索结果分析 | ✅（统计页已拆分 statistics/ 子目录 6 文件） |
| Phase 4 | 特色业务：借贷/报销/退款/分期 | 逻辑✅；UI 只读列表 + 删除（已加确认弹窗） |
| Phase 5 | 三家导入 + 预览 + 覆盖/增量 + 账户合并 | ✅（核心价值，已完成） |
| Phase 6 | AI 助手 / 语音记账 | ❌ 未开始 |
| Phase 7 | 局域网同步 | ❌ 未开始 |
| Phase 8 | i18n / 主题 / 备份 / 三端打包 | 备份✅、主题✅（已收敛克莱因蓝）、i18n ❌、打包进行中（release 装机验证） |
| UI 重构 | ui-refactor-plan.md 四阶段 | 阶段 0/1/2 ✅；阶段 3 整体验收 ❌ |

> 注意：`rewrite-plan.md` 与 `ui-refactor-plan.md` 里的复选框都落后于代码实际进度，以代码 + git log 为准。

## 3. 最近改动（2026-09-20 ~ 09-21，UI 全面重构 + 审核修复）

**A. UI 全面重构**（计划 [ui-refactor-plan.md](ui-refactor-plan.md)，设计依据 [designDirection.md](designDirection.md)「Bright Luminous Minimalism · 克莱因蓝」）

- **阶段 0 全局基建 ✅**：
  - 0.1 主题收敛：`presetThemes` 只剩克莱因蓝（背景 `#F7F8F6`、seed `#002FA7`），暗色预设换 klein seed 派生；旧主题 id 兜底回退
  - 0.2 骨架屏体系：新增 `xp_skeleton.dart`（box/line/circle + XpSkeletonList/XpSkeletonPage，1400ms 呼吸）；`xpWhen` loading 缺省换骨架 + AnimatedSwitcher 240ms 淡入；`buildXpScaffold` 支持 `loading:`；`XpLoading` 已删除
  - 0.3 页面基类：Android 转场 `PredictiveBackPageTransitionsBuilder` + manifest `enableOnBackInvokedCallback`；公开 `XpEntrance`（淡入+上移 8dp）；`LazyIndexedStack` 懒挂载 4 tab
  - 0.4 XpCard 按压缩放 0.98 微交互
- **阶段 1 逐页重构 ✅**：Tab 4 页（home 整页骨架 / accounts 总资产 Hero+迷你趋势 / statistics 拆分 6 文件 / mine 用户卡+三分组）+ 二级页 16/16 全部完成（骨架、空态、进场、token 化）
- **阶段 2 动效打磨 ✅**：转场三类复核、`XpFab` 统一 FAB（0.96 微缩放）、`XpStaggerIn` 列表淡入试点（home 前 12 组 / accounts 前 6 组，超限直渲染）、reduce-motion / animationsEnabled 双开关五处全链路核查
- **弹层七件套排印统一**（350b216）：`xp_sheet` heightFactor 0.7→0.8；bookkeeping 金额 Display32 tabular + 分类格选中态主题色描边；adjust/snapshot/account_form 键盘避让+tabular；ai_chat 气泡 G2 圆角；color_picker 圆角对齐 token
- **阶段 3 整体验收 ❌**：见 §4 待办

**B. 代码审核 P1/P2 修复**（bb688c0，报告 [code-review-2026-09-20.md](code-review-2026-09-20.md)，P1/P2 清零，P3 记录在案）

- P1-1 ledger 四表删除加 `confirmXpDialog(danger)`，明示仅删记录不动账单余额
- P1-2 `_loadUserThemes` 读取时亮度兜底（过深背景/卡色置 null），与保存校验双保险，防「全蓝糊」
- P2-1 ledger 4 个 StreamProvider 改 autoDispose
- P2-2/3 新增 [ledger_repository.dart](lib/data/repositories/ledger_repository.dart)（4 watch + 4 delete）；BillRepository 加 `transferFeeOf`；UI 不再直摸 dbProvider
- P2-4 search 分类下拉排除 transfer 类型
- P2-5 主题页暗色模式卡加 onTap 说明

**C. 磨砂玻璃全面铺开 + 切换动画重做**（2026-09-21，真机 debug 已装）

- **切换动画重做**：`lazy_indexed_stack.dart` 改纯位移「轮播式」（新页 7% 侧入 + 旧页同向滑出，300ms easeOutCubic，无 Opacity）——修掉重影（BackdropFilter 处于 saveLayer 内的混合异常）；包裹结构恒定（每页恒 `IgnorePointer > SlideTransition`），修复 Element 重建导致的 State 丢失 / XpEntrance 重播
- **磨砂组件升级**：`xp_frosted_bar.dart` 用官方 `BackdropFilter.grouped` + `BlendMode.src`（多栏共享一次引擎模糊、防 saveLayer 混合异常）；底色改**固定白色** alpha 0.65（不随主题色）；新增 `XpFrostedShell`（AppBarTheme 覆盖透明背景，包装任意 AppBar）；`XpFrostedAppBar` 已删除
- **全页面磨砂**：`buildXpScaffold` 删 `frostedAppBar` 参数，改为读全局磨砂开关自动包壳（17+4 页零改动）；一级页 AppBar 全部换回普通 `AppBar`
- **全局开关**：`frostedGlassProvider`（默认开，SharedPreferences `ui_frosted_glass`，main 预热）；`MainShell` 外包 `BackdropGroup`（固定 BackdropKey），底部栏磨砂开 = extendBody+白色磨砂、关 = 原生；主题外观页新增独立「磨砂玻璃」分区 Switch
- **预测性返回已移除**（用户决策）：theme.dart Android 回 Zoom 转场

**验证状态**：上轮提交时 `flutter analyze` 0 问题；`flutter test` 91 用例全过。

## 4. 下一步待办（按优先级）

1. **阶段 3 整体验收**（ui-refactor-plan §五）：analyze 全库零问题 → 真机亮/暗两套全页走查（含磨砂开关两态）→ DevTools 帧率 → 主题迁移清除/保留双场景；暗色模式下白色磨砂的可读性待用户反馈（固定白色为用户明确要求）
2. 弹层/共享组件剩余微调（xp_sheet 拖拽-blur 同一 progress 驱动、bill_tile subtitle、xp_empty_state 图标尺寸、xp_snack 对齐 token——部分随迁移已达标，以代码为准）
3. 特色业务 UI 补全（借贷/报销/退款/分期编辑表单）
4. Phase 6 AI 助手 / 语音记账（本地分类预测参考 cent-xyx `linear-predict`）
5. Phase 7 局域网同步（参考 cent-xyx `sync-server.js`）
6. Phase 8 i18n 中英词条（**必须先读 §5 规则**）、三端打包
7. `docs/changelog.md` 严重落后（还停在 v0.1.0 规划态），建议补记一版

## 5. 必须遵守的约定

### git 操作（用户规则）
- **严禁 AI 主动 git commit / git push**；push 只能用户自己做
- 用户允许的 commit 是**一次性**许可，每次都要重新授权

### i18n 词条（用户规则，Phase 8 开工前必读）
- 各语言词条数量必须一致；不一致要主动排查
- **原词条不可动**（翻译公司已翻译，一个字、一个空格都不能改）
- 改文案 = **新增词条**：原 key 加 `V2` 后缀（再改加 V3…），追加在文件最底部
- 占位符 `{{ }}` / `[[ ]]` 内部内容不翻译、不改动

### 架构约定（rewrite-plan.md §2 + 审核后强化）
- 数据库是唯一事实来源，Riverpod 只做只读缓存
- **UI 不直摸 dbProvider**，写操作走 repository（ledger_repository 已补齐）
- 账单 + 账户余额 + 快照同一事务；快照 billId 先定后写
- 导入幂等（ID 映射 + diff）；导入账单打来源标记，重算时跳过
- 以用户输入的账户余额为权威（不强制与账单一致）
- 自定义主题背景/卡色必须过亮度校验（保存拦截 + 读取兜底）

## 6. 关键文件索引

| 文件 | 说明 |
|------|------|
| docs/rewrite-plan.md | 总路线图（分阶段，带验收标准） |
| docs/ui-refactor-plan.md | UI 重构计划 + 进度日志（阶段 0/1/2 已闭环） |
| docs/designDirection.md | 设计方向（克莱因蓝 · Bright Luminous Minimalism） |
| docs/data-model.md | 14 张表权威设计 |
| docs/algorithms.md | 算法一~八（余额联动/调账/重算/总资产/趋势/导入/合并） |
| docs/code-review-2026-09-20.md | 全库审核报告（P1/P2 已修，P3 在案） |
| lib/ui/tokens/design_tokens.dart | 设计 token 唯一来源（色/圆角/间距/动效档位） |
| lib/ui/theme.dart | 主题装配 + PageTransitionsTheme |
| lib/ui/layout/xp_page_scaffold_mixin.dart | 页面壳 + XpEntrance 进场动画 |
| lib/ui/layout/xp_async_view_mixin.dart | xpWhen：骨架 loading + 淡入 |
| lib/ui/widgets/ | Xp 组件族：xp_card / xp_fab / xp_skeleton / xp_stagger_in / xp_sheet / xp_snack / xp_empty_state |
| lib/state/theme_provider.dart | 主题状态（含亮度校验双保险） |
| lib/data/repositories/bill_repository.dart | 账单查询（minBillTime / sumByTagInRange / transferFeeOf） |
| lib/data/repositories/ledger_repository.dart | 借贷/报销/退款/分期 watch + delete |
| lib/state/providers.dart | 全局 Provider 清单 |
| lib/ui/pages/statistics/ | 统计页拆分后 5 分区 + stats_shared |

## 7. 近期提交参考（git log 风格）

- `fix:代码审核P1/P2修复:台账删除确认+脏主题兜底+分层收敛+分类过滤`
- `feat:阶段2动效打磨:转场复核+XpFab微缩放+stagger淡入试点+reduce-motion链路核查`
- `fix:主题页暗色预设独立分区+自定义背景深度校验;弹层七件套排印统一`
- `feat:阶段1逐页重构:Tab四页+二级页16页全部完成`
- `feat:卡片基类微交互` / `ui：页面基类升级——预测性返回+进场动画+懒挂载` / `ui：克莱因蓝主题收敛+骨架屏淡入`
