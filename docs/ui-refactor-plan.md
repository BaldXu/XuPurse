# XuPurse UI 全面重构计划

> 设计依据：[designDirection.md](designDirection.md)（Bright Luminous Minimalism · 克莱因蓝）
> 图例：`[ ]` 未开始 · `[~]` 进行中 · `[x]` 已完成
> 状态：阶段 0/1/2 已闭环（2026-09-20 ~ 09-22），阶段 3 整体验收待做；最新进度见 [memory.md](./memory.md)。

---

## 一、目标（来自需求确认）

1. **加载体验**：所有页面进入时先显示加载动画（骨架屏），数据就绪后**淡入**内容，消除"白屏/跳变/掉帧"观感。
2. **基类统一**：页面基类、卡片基类承担统一能力——预测性返回、懒加载、进入/退出动画、按压微交互。
3. **布局自由度**：各页布局、层级关系全部允许重构，标准 = 漂亮 + 易用。
4. **主题收敛**：删除现有 9 个彩色预设主题，只保留一个按当前设计（克莱因蓝）做的预设主题；暗色预设同步改为克莱因蓝暗色版。

---

## 二、阶段 0：全局基建（先行，全部页面依赖）

### 0.1 主题收敛 `[x]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | `presetThemes` 只留 `preset_klein`（删除 green/blue/purple/red/orange/teal/olive/graphite），色值与 design_tokens 对齐（背景 `#F7F8F6`、卡片白、seed `#002FA7`） | `[x]` |
| 2 | `darkThemePreset` 改为克莱因蓝暗色变体（seed 换 klein，fromSeed 暗色派生自动提亮 primary、中性色带蓝灰调，避免纯黑） | `[x]` |
| 3 | 旧持久化 `currentId` 兜底迁移：确认 `ThemeState.build` 的 valid 检查回退到 `presetThemes.first`（= klein）后真机验证 | `[x]` |
| 4 | `theme_settings_page` 预设区改造：单预设展示；用户自建主题（`user_*`）机制暂保留不动（顺带修正「保存为预设主题」误导文案） | `[x]` |

- 涉及：`lib/state/theme_provider.dart`、`lib/ui/pages/theme_settings_page.dart`
- 验收：系统暗/亮切换正常；老用户升级后主题自动落到克莱因蓝；主题设置页无残留旧预设。

### 0.2 加载态 + 淡入（骨架屏体系）`[x]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | 新增 `XpSkeleton` 组件：圆角块脉冲呼吸动画（opacity 循环，尊重 reduce-motion / animationsEnabled）；提供 `box` / `line` / `circle` 原语与 `XpSkeletonList`（模拟列表卡）预设 | `[x]` |
| 2 | 升级 `XpAsyncView.xpWhen`：loading 分支由 `XpLoading` 转圈改为**骨架屏参数**（各页可传自己的骨架，缺省用通用列表骨架）；data 分支包 `AnimatedSwitcher`（Fade 240ms easeOut）实现就绪淡入 | `[x]` |
| 3 | `XpPageScaffold` 增加整页骨架快捷能力：`loading: true` 时 body 换 `XpSkeletonPage`（标题+卡片+列表，整组呼吸），完成后与内容淡入切换 | `[x]` |
| 4 | 首帧性能配合：骨架 const 构造；淡入只包一层（`_Pulse` 单 Opacity），避免整树 opacity 重建 | `[x]` |
| 5 | 存量迁移：statistics_page 7 处 FutureBuilder 换骨架 + `_xpFadeGate` 淡入门；首页 loading 换列表骨架；`XpLoading` 删除 | `[x]` |

- 涉及：新增 `lib/ui/widgets/xp_skeleton.dart`、`lib/ui/layout/xp_async_view_mixin.dart`、`lib/ui/layout/xp_page_scaffold_mixin.dart`
- 验收：冷启动进统计/资产页不再白屏转圈，而是骨架→内容淡入；DevTools 无明显掉帧。

### 0.3 页面基类升级（进入动画 + 预测性返回 + 懒加载）`[x]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | **预测性返回**：theme.dart 的 `PageTransitionsTheme` Android 分支改用 `PredictiveBackPageTransitionsBuilder`（Flutter 3.35 原生支持）；`animationsEnabled=false` 时仍走 `_ZeroTransition`；其余平台保持 Zoom | `[x]` |
| 2 | AndroidManifest 开启 `android:enableOnBackInvokedCallback="true"`（预测性返回手势的系统开关） | `[x]` |
| 3 | **进入动画**：页面基类提供统一「内容淡入 + 上移 8dp」进场（`XpMotion.page` 400ms easeOutCubic），仅首次 build 触发；尊重 animationsEnabled 与系统 reduce-motion | `[x]` |
| 4 | **懒加载 Shell**：`MainShell` 的 `IndexedStack` 改为懒挂载实现（只 build 已访问过的 tab，访问后 keep-alive），宽/窄布局共用 | `[x]` |
| 5 | **退出动画**：依赖系统转场（Predictive Back 自带），不自绘退出；弹层类走 xp_sheet 统一 | `[x]` |

- 涉及：`lib/ui/theme.dart`、`android/app/src/main/AndroidManifest.xml`、`lib/ui/layout/xp_page_scaffold_mixin.dart`、新增 `lib/ui/layout/lazy_indexed_stack.dart`、`lib/ui/pages/main_shell.dart`
- 验收：Android 15+ 侧滑返回可见预览动画；4 个 tab 首次点入才构建；页面切入有统一淡入。

### 0.4 卡片基类微交互 `[x]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | `XpCard` 支持 `onTap` 时按压缩放（0.98，`XpMotion.micro` 170ms）+ 阴影减弱，松手回弹 | `[x]` |
| 2 | InkWell ripple 与 G2 形状对齐已就绪（`_borderRadiusOf`），无需改 | `[x]` |

- 涉及：`lib/ui/widgets/xp_card.dart`
- 验收：可点卡片按下有轻微缩放反馈，松手回弹，无闪烁。

---

## 三、阶段 1：逐页重构（每页均按首页样板标准）

每页统一验收清单（完成后打勾）：

- [ ] 布局层级梳理（Hero/重点区 → 内容 → 操作），信息密度合理
- [ ] 全部走 token：无裸 TextStyle/颜色/圆角/间距；金额 tabular + 千分位
- [ ] 接入 xpWhen：骨架 loading + 淡入 + 完整空态/错误态
- [ ] 进场动画 & 预测性返回生效
- [ ] `flutter analyze` 零问题 + 真机滚动流畅

### Tab 主页面（4）

| 页面 | 改动要点 | 状态 |
|------|----------|------|
| home_page 明细 | 样板已完成；补接整页骨架 | `[x]` |
| accounts_page 资产 | 重构为「总资产 Hero（大金额 + 迷你趋势）→ 账户卡列表 → 隐藏资产入口」；账户卡用 XpCard 微交互；接骨架 | `[x]` |
| statistics_page 统计 | 最大页面（约 2200 行）：拆分文件（视图/图表组件分离）；图表区接骨架；筛选栏与首页统一；日/月/年切换风格统一；预算卡对齐 token | `[x]`（拆分+骨架完成；筛选栏/切换风格统一移至阶段2打磨） |
| mine_page 我的 | 重构为「用户卡 → 分组设置列表（XpCard 分组 + 图标色块）」；去多余装饰 | `[x]` |

### Push 二级页面（16）

| 页面 | 改动要点 | 状态 |
|------|----------|------|
| search_page 搜索 | 搜索框置顶 sticky；结果复用日组卡；空结果态统一 | `[x]`（骨架+空态统一；sticky/日组卡后续打磨） |
| account_detail_page 账户详情 | 顶部账户卡 Hero（余额大金额 tabular）；流水复用日组卡；调整/快照入口卡片化 | `[x]`（Hero+流水卡+快照卡；流水为 BillTile 行） |
| account_manage_page 账户管理 | 列表卡化 + 排序视觉反馈；总余额小计行 | `[x]` |
| book_manage_page 账本管理 | 卡片化 + 当前账本标识（primary 描边） | `[x]`（骨架+卡片已有；primary 描边后续打磨） |
| category_manage_page 分类管理 | 支出/收入分段切换；列表卡化；图标色块对齐 BillTile 规范 | `[x]`（Tab 结构已达标，微调后续） |
| tag_manage_page 标签管理 | chip 流式布局（pill），管理态交互简化 | `[x]`（骨架已接） |
| ledger_manage_page 台账 | 卡片化，接骨架/空态 | `[x]` |
| budget_manage_page 预算管理 | 预算卡：进度条 primary + 语义色阈值（warning/danger）；金额 tabular | `[x]`（骨架+空态；语义阈值已有 error 分支） |
| trend_page 趋势 | 图表接骨架；配色走语义色与 primary | `[x]` |
| settings_page 设置 | 分组列表（同 mine 模式） | `[x]` |
| theme_settings_page 主题 | 主题收敛后的 UI 重做（见 0.1）；预览卡用真实 token 渲染 | `[x]`（0.1 已重做；预览卡打磨移阶段2） |
| currency_settings_page 币种 | 列表卡化 + 汇率排印规范 | `[x]` |
| data_manage_page 数据管理 | 统计信息卡 + 操作分组；危险操作用 danger 警示 | `[x]`（操作分组+danger 已有；统计信息卡后续） |
| import_page 导入 | 步骤感布局（step indicator 用 primary）；文件选择大按钮卡 | `[x]`（1·/2· 步骤标题） |
| ai_settings_page AI 设置 | 表单排印统一（label caption + 输入框 s 圆角） | `[x]`（删除确认收敛 confirmXpDialog） |
| about_page 关于 | 极简居中布局：logo + 版本 + 链接列表卡 | `[x]`（新增隐私说明卡） |

### 弹层 Sheet / 对话框（7）

| 组件 | 改动要点 | 状态 |
|------|----------|------|
| xp_sheet 基类 | `heightFactor` 0.7 → 0.8；拖拽位移与背景 blur 由同一 progress 驱动（§14）；把手样式统一 | `[x]`（已重做为分层进入：滑入 + 表面磨砂淡入） |
| bookkeeping_sheet 记账 | 金额输入大号 tabular；分类九宫格选中态统一；键盘避让顺滑 | `[x]` |
| account_form_sheet 账户表单 | 表单排印统一；颜色选择入口卡片化 | `[x]` |
| historical_snapshot_sheet 快照 | 列表卡化 + 金额 tabular | `[x]` |
| adjust_sheet 调整余额 | 数字键盘排印统一 | `[x]` |
| ai_chat_sheet AI 对话 | 气泡样式对齐卡片语言（G2 圆角） | `[x]` |
| color_picker_dialog 取色器 | 色块网格圆角统一 | `[x]` |

### 共享组件（3）

| 组件 | 改动要点 | 状态 |
|------|----------|------|
| bill_tile | 金额语义色 + tabular 已完成；subtitle 排印微调 | `[ ]` |
| xp_empty_state | 图标尺寸统一，与骨架风格一致 | `[ ]` |
| xp_snack | 圆角/位置对齐 token | `[ ]` |

---

## 四、阶段 2：动效与细节打磨 `[x]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | 全局转场复核：push/pop、sheet、dialog 三类节奏统一（micro/component/container 档位对号） | `[x]`（push=PredictiveBack/Zoom、sheet=M3 内建+container 形状、dialog=showXpDialog 限宽、snackBar 补 XpShape 圆角） |
| 2 | FAB：随路由出现/消失；按下微缩放 | `[x]`（XpFab 统一封装：Listener+AnimatedScale 0.96 micro，reduce-motion 直通；全 7 处 FAB 收口） |
| 3 | 列表项进视口轻微 stagger 淡入（仅首页与资产页试点，性能不达标则回退） | `[x]`（XpStaggerIn：仅透明度+索引差分延迟封顶 240ms；home 前 12 组、accounts 前 6 组，超限直接渲染） |
| 4 | reduce-motion / animationsEnabled=false 全链路验证 | `[x]`（逐点核查：XpEntrance/XpSkeleton._Pulse/XpCard/XpFab/XpStaggerIn 五处均双开关判断，static 关闭态直通 child） |

## 五、阶段 3：整体验收 `[ ]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | `flutter analyze` 全库零问题 | `[x]` |
| 2 | 真机（23127PN0CC）全页面走查：亮/暗两套主题 | `[ ]` |
| 3 | 性能：DevTools 帧率检查，滚动/转场无明显 jank | `[ ]`（真机 profile 基线已采集，60Hz 下动画可稳定满帧） |
| 4 | 预测性返回：Android 15+ 真机验证侧滑预览 | `[-]` 已移除（用户决策，转场定型为 Cupertino 滑动） |
| 5 | 主题迁移：清除/保留 SharedPreferences 两种场景均落到克莱因蓝 | `[x]`（theme_persistence 测试覆盖） |

---

## 六、执行顺序与依赖

```
0.1 主题收敛 ─┐
0.2 骨架淡入 ─┼→ 0.3 基类/转场/懒加载 → 0.4 卡片微交互
              ┘            ↓
                阶段 1 逐页重构（Tab 主页 → 常用二级页 → 低频设置页 → 弹层）
                       ↓
                阶段 2 动效打磨 → 阶段 3 整体验收
```

- 基建（阶段 0）全部落地前不批量改页面，避免每页返工。
- 每完成一页真机热重载验收一次；每完成一组（Tab/二级/弹层）跑一次全库 analyze。

## 七、进度日志

- 2026-09-20：计划建立。首页样板已完成；盘点出 4 Tab + 16 二级页 + 7 弹层 + 3 共享组件的工作面；阶段 0/1/2/3 均未开始。
- 2026-09-20：0.1 主题收敛完成（预设仅剩克莱因蓝、背景修正为 #F7F8F6、暗色预设换 klein seed、主题设置页文案修正）；analyze 零问题；已 run 到真机待用户目视确认旧主题 id 回退。
- 2026-09-20：0.2 骨架屏 + 淡入完成。新增 xp_skeleton.dart（box/line/circle 原语、XpSkeletonList、XpSkeletonPage，1400ms 呼吸、尊重 reduce-motion）；xpWhen loading 缺省换骨架 + AnimatedSwitcher 240ms 淡入（key 按 hasValue/hasError 对齐 skipLoadingOnReload，刷新不闪骨架）；buildXpScaffold 增加 loading 入口；statistics_page 7 处 FutureBuilder 迁移（`_xpFadeGate` 淡入门）+ 首页 loading 换骨架 + XpLoading 删除；analyze 零问题。真机验证因设备断连待用户重连后 run。
- 2026-09-20：0.3 页面基类升级完成。theme.dart Android 转场换 `PredictiveBackPageTransitionsBuilder`（不支持手势的设备由 SDK 回退 FadeForwards）+ manifest 开 `enableOnBackInvokedCallback`；xp_page_scaffold_mixin 抽出公开 `XpEntrance`（淡入 + 上移 8dp、XpMotion.page 400ms easeOutCubic，双开关：animationsEnabled && !disableAnimationsOf，ConsumerWidget 页面也可直接包用）；新增 LazyIndexedStack（未访问 tab 用 SizedBox.shrink 占位，访问后 keep-alive），main_shell 宽/窄布局共用；覆盖审查补迁 statistics_page、ai_settings_page（AiSettingsPage 用 XpEntrance 包裹、_AiConfigEditPage 混入 mixin），全库 18 页走 buildXpScaffold；analyze 零问题。真机验证（预测性返回 + 懒挂载）待设备重连。
- 2026-09-20（晚）：0.4 卡片微交互完成。XpCard 转 StatefulWidget，onTap 按压缩放 0.98 + 阴影减弱（AnimatedScale + TweenAnimationBuilder 同步 170ms micro），松手回弹；双开关（animationsEnabled/reduce-motion）关闭时退化为纯 InkWell；新增 onLongPress、clipBehavior 参数（分组卡列表行用）；顺手修复 theme_settings_test 4 处旧预设引用（0.1 收敛遗留）。阶段 0 全部闭环。
- 2026-09-20（晚）：阶段 1 Tab 页四页重构。home 补接整页骨架（loading: billsAsync.isLoading）；accounts 重构为总资产 Hero（Display tabular 大金额 + 近 90 天周粒度迷你趋势线，与趋势页共用算法五）→ 趋势入口 XpCard → 三类分组账户卡（组内行 Divider 缩进 60，XpCard clipBehavior 裁剪 ripple）；mine 重构为用户卡（账本名+本位币+总资产）→ 通用/偏好/关于三分组（图标 primary 色块 + chevron）+ 版本脚注；statistics 拆分为 statistics/ 子目录 6 文件（stats_shared + 5 分区），跨文件符号最小公开化（StatsSectionRefresh/xpFadeGate/StatsRangePreset 等）。
- 2026-09-20（晚·二）：阶段 1 二级页第一批（9/16）。search（双流骨架+XpEmptyState 空态）；account_detail 整页重构（账户 Hero tabular 大金额 + watchPage 按账户流水卡（新增 accountBillsProvider autoDispose.family，drift watch 响应式）+ 快照卡化 + BillTile 行点按/长按删除）；account_manage（整页骨架 + 总余额小计行 tabular + 列表卡化 _AccountCheckRow）；book_manage/budget_manage/tag_manage/ledger_manage（4 处 loading→骨架 + 空态 XpEmptyState）；trend（整页 XpSkeletonPage + 单账户卡/累计净额卡骨架，import 路径随 statistics 拆分改 stats_shared）。
- 2026-09-20（晚·三）：阶段 1 二级页第二批（7/7 收官，16/16 全部完成）。settings 入口行图标色块化（对齐 mine 页）；currency 汇率列表卡片化（primary 色块头像+Divider 缩进）；import 步骤感标题（1·选择来源 / 2·选择文件）；ai_settings 删除确认 AlertDialog→confirmXpDialog(danger)；data_manage 操作行 _TintedIcon 色块图标；about 新增隐私说明卡（showAboutDialog）。共享组件 bill_tile/xp_empty_state/xp_snack 随各页迁移已达标。analyze 0 + 91 测试过。
- 2026-09-20（晚·四）：阶段 2 动效打磨完成。全局转场复核（页面=PredictiveBack/Zoom、sheet=M3 内建 container 节奏、dialog 统一 showXpDialog、snackBar 浮起补 XpShape 圆角）；XpFab 统一 FAB（按下 0.96 微缩放，Listener+AnimatedScale micro 170ms，reduce-motion 直通，7 处收口：home/book/budget/category/tag/ai_settings）；XpStaggerIn 列表淡入试点（仅透明度、索引差分延迟 40ms/项封顶 240ms、reduce-motion 直通；home 前 12 组+accounts 前 6 组，超限直渲染——性能回退方案就位）；reduce-motion 全链路核查（XpEntrance/骨架脉冲/XpCard/XpFab/XpStaggerIn 五处双开关齐备）。analyze 0 + 91 测试过。
- 2026-09-21：代码审核 P1/P2 修复（bb688c0）+ 磨砂玻璃全面铺开 + 图标包切换（简约/Twitter 表情）+ 卡片/FAB/弹窗真实磨砂 + 主题持久化 v3。转场动画多轮被否后定型：Tab 切换瞬时、push/pop 走 Cupertino 滑动（详见 memory.md §3）。
- 2026-09-22：动效重做收官（B1 转场拆层 / B2 弹窗分层进入 / B3 主题切换保动画 / B4 卡片磨砂零重算 / 转场骨架短路 / XpRoute 400ms 统一转场）+ 第三波设计语言统一（裸 Card / 错误态 / 空态 / 间距 token 全库收口）。**阶段 0/1/2 闭环**；阶段 3 仅剩真机全页走查与 60Hz 帧率补采，待办见 memory.md §4。
