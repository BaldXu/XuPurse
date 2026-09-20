# XuPurse UI 全面重构计划

> 设计依据：[designDirection.md](designDirection.md)（Bright Luminous Minimalism · 克莱因蓝）
> 样板：首页-明细页（已完成并验收，作为其余页面的参照标准）
> 图例：`[ ]` 未开始 · `[~]` 进行中 · `[x]` 已完成
> 最后更新：2026-09-20

---

## 一、目标（来自需求确认）

1. **加载体验**：所有页面进入时先显示加载动画（骨架屏），数据就绪后**淡入**内容，消除"白屏/跳变/掉帧"观感。
2. **基类统一**：页面基类、卡片基类承担统一能力——预测性返回、懒加载、进入/退出动画、按压微交互。
3. **布局自由度**：各页布局、层级关系全部允许重构，标准 = 漂亮 + 易用。
4. **主题收敛**：删除现有 9 个彩色预设主题，只保留一个按当前设计（克莱因蓝）做的预设主题；暗色预设同步改为克莱因蓝暗色版。

---

## 二、阶段 0：全局基建（先行，全部页面依赖）

### 0.1 主题收敛 `[ ]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | `presetThemes` 只留 `preset_klein`（删除 green/blue/purple/red/orange/teal/olive/graphite），色值与 design_tokens 对齐（背景 `#F7F8F6`、卡片白、seed `#002FA7`） | `[x]` |
| 2 | `darkThemePreset` 改为克莱因蓝暗色变体（seed 换 klein，fromSeed 暗色派生自动提亮 primary、中性色带蓝灰调，避免纯黑） | `[x]` |
| 3 | 旧持久化 `currentId` 兜底迁移：确认 `ThemeState.build` 的 valid 检查回退到 `presetThemes.first`（= klein）后真机验证 | `[~]` |
| 4 | `theme_settings_page` 预设区改造：单预设展示；用户自建主题（`user_*`）机制暂保留不动（顺带修正「保存为预设主题」误导文案） | `[x]` |

- 涉及：`lib/state/theme_provider.dart`、`lib/ui/pages/theme_settings_page.dart`
- 验收：系统暗/亮切换正常；老用户升级后主题自动落到克莱因蓝；主题设置页无残留旧预设。

### 0.2 加载态 + 淡入（骨架屏体系）`[~]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | 新增 `XpSkeleton` 组件：圆角块脉冲呼吸动画（opacity 循环，尊重 reduce-motion / animationsEnabled）；提供 `box` / `line` / `circle` 原语与 `XpSkeletonList`（模拟列表卡）预设 | `[x]` |
| 2 | 升级 `XpAsyncView.xpWhen`：loading 分支由 `XpLoading` 转圈改为**骨架屏参数**（各页可传自己的骨架，缺省用通用列表骨架）；data 分支包 `AnimatedSwitcher`（Fade 240ms easeOut）实现就绪淡入 | `[x]` |
| 3 | `XpPageScaffold` 增加整页骨架快捷能力：`loading: true` 时 body 换 `XpSkeletonPage`（标题+卡片+列表，整组呼吸），完成后与内容淡入切换 | `[x]` |
| 4 | 首帧性能配合：骨架 const 构造；淡入只包一层（`_Pulse` 单 Opacity），避免整树 opacity 重建 | `[x]` |
| 5 | 存量迁移：statistics_page 7 处 FutureBuilder 换骨架 + `_xpFadeGate` 淡入门；首页 loading 换列表骨架；`XpLoading` 删除 | `[x]` |

- 涉及：新增 `lib/ui/widgets/xp_skeleton.dart`、`lib/ui/layout/xp_async_view_mixin.dart`、`lib/ui/layout/xp_page_scaffold_mixin.dart`
- 验收：冷启动进统计/资产页不再白屏转圈，而是骨架→内容淡入；DevTools 无明显掉帧。

### 0.3 页面基类升级（进入动画 + 预测性返回 + 懒加载）`[~]`

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
| home_page 明细 | 样板已完成；补接整页骨架 | `[ ]` |
| accounts_page 资产 | 重构为「总资产 Hero（大金额 + 迷你趋势）→ 账户卡列表 → 隐藏资产入口」；账户卡用 XpCard 微交互；接骨架 | `[ ]` |
| statistics_page 统计 | 最大页面（约 2200 行）：拆分文件（视图/图表组件分离）；图表区接骨架；筛选栏与首页统一；日/月/年切换风格统一；预算卡对齐 token | `[ ]` |
| mine_page 我的 | 重构为「用户卡 → 分组设置列表（XpCard 分组 + 图标色块）」；去多余装饰 | `[ ]` |

### Push 二级页面（16）

| 页面 | 改动要点 | 状态 |
|------|----------|------|
| search_page 搜索 | 搜索框置顶 sticky；结果复用日组卡；空结果态统一 | `[ ]` |
| account_detail_page 账户详情 | 顶部账户卡 Hero（余额大金额 tabular）；流水复用日组卡；调整/快照入口卡片化 | `[ ]` |
| account_manage_page 账户管理 | 列表卡化 + 排序视觉反馈；总余额小计行 | `[ ]` |
| book_manage_page 账本管理 | 卡片化 + 当前账本标识（primary 描边） | `[ ]` |
| category_manage_page 分类管理 | 支出/收入分段切换；列表卡化；图标色块对齐 BillTile 规范 | `[ ]` |
| tag_manage_page 标签管理 | chip 流式布局（pill），管理态交互简化 | `[ ]` |
| ledger_manage_page 台账 | 卡片化，接骨架/空态 | `[ ]` |
| budget_manage_page 预算管理 | 预算卡：进度条 primary + 语义色阈值（warning/danger）；金额 tabular | `[ ]` |
| trend_page 趋势 | 图表接骨架；配色走语义色与 primary | `[ ]` |
| settings_page 设置 | 分组列表（同 mine 模式） | `[ ]` |
| theme_settings_page 主题 | 主题收敛后的 UI 重做（见 0.1）；预览卡用真实 token 渲染 | `[ ]` |
| currency_settings_page 币种 | 列表卡化 + 汇率排印规范 | `[ ]` |
| data_manage_page 数据管理 | 统计信息卡 + 操作分组；危险操作用 danger 警示 | `[ ]` |
| import_page 导入 | 步骤感布局（step indicator 用 primary）；文件选择大按钮卡 | `[ ]` |
| ai_settings_page AI 设置 | 表单排印统一（label caption + 输入框 s 圆角） | `[ ]` |
| about_page 关于 | 极简居中布局：logo + 版本 + 链接列表卡 | `[ ]` |

### 弹层 Sheet / 对话框（7）

| 组件 | 改动要点 | 状态 |
|------|----------|------|
| xp_sheet 基类 | `heightFactor` 0.7 → 0.8；拖拽位移与背景 blur 由同一 progress 驱动（§14）；把手样式统一 | `[ ]` |
| bookkeeping_sheet 记账 | 金额输入大号 tabular；分类九宫格选中态统一；键盘避让顺滑 | `[ ]` |
| account_form_sheet 账户表单 | 表单排印统一；颜色选择入口卡片化 | `[ ]` |
| historical_snapshot_sheet 快照 | 列表卡化 + 金额 tabular | `[ ]` |
| adjust_sheet 调整余额 | 数字键盘排印统一 | `[ ]` |
| ai_chat_sheet AI 对话 | 气泡样式对齐卡片语言（G2 圆角） | `[ ]` |
| color_picker_dialog 取色器 | 色块网格圆角统一 | `[ ]` |

### 共享组件（3）

| 组件 | 改动要点 | 状态 |
|------|----------|------|
| bill_tile | 金额语义色 + tabular 已完成；subtitle 排印微调 | `[ ]` |
| xp_empty_state | 图标尺寸统一，与骨架风格一致 | `[ ]` |
| xp_snack | 圆角/位置对齐 token | `[ ]` |

---

## 四、阶段 2：动效与细节打磨 `[ ]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | 全局转场复核：push/pop、sheet、dialog 三类节奏统一（micro/component/container 档位对号） | `[ ]` |
| 2 | FAB：随路由出现/消失；按下微缩放 | `[ ]` |
| 3 | 列表项进视口轻微 stagger 淡入（仅首页与资产页试点，性能不达标则回退） | `[ ]` |
| 4 | reduce-motion / animationsEnabled=false 全链路验证 | `[ ]` |

## 五、阶段 3：整体验收 `[ ]`

| # | 事项 | 状态 |
|---|------|------|
| 1 | `flutter analyze` 全库零问题 | `[ ]` |
| 2 | 真机（23127PN0CC）全页面走查：亮/暗两套主题 | `[ ]` |
| 3 | 性能：DevTools 帧率检查，滚动/转场无明显 jank | `[ ]` |
| 4 | 预测性返回：Android 15+ 真机验证侧滑预览 | `[ ]` |
| 5 | 主题迁移：清除/保留 SharedPreferences 两种场景均落到克莱因蓝 | `[ ]` |

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
