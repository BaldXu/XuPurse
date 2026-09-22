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
- **预测性返回已移除**（用户决策）：后经 Zoom → 轻量淡入 → 最终定型 Cupertino 滑动（见 §3-F）

**D. 图标包切换（aba521b，2026-09-21）**

- 新增 `iconPackProvider` 全局开关：`简约`（Material Icons）/ `Twitter 表情`（twemoji 彩色 SVG），持久化 `ui_icon_pack`
- `lib/core/utils/twemoji_icons.dart`：twemoji SVG 注册表 + `materialEmojiNames`（Material 图标 ↔ 语义名映射）；pubspec 引入 `colorful_iconify_flutter` + `flutter_svg`
- `AppIcon` 统一业务图标组件（lib/ui/widgets/app_icon.dart）：分类/账户图标一律走它，twemoji 未覆盖的名称回退简约图标；切换后所有订阅方自动重建 → 整 App 刷新
- 新增 `icon_settings_page.dart` 图标选择页；趋势页图表卡片化（102 行改动）；32 文件全站适配

**E. 卡片/FAB/弹窗真实磨砂 + 主题持久化修复（e7ba072 + 70b1a67，2026-09-21）**

- `FrostedState` 拆为**总开关 + 3 子项**：`appBar`/`card`/`sheet`，默认 appBar=true、card=false、sheet=false（旧单开关无损迁移）；总开关关闭时子项全部失效
- 卡片磨砂：`XpCard._frostCard` = ClipPath(G2) + BackdropFilter σ10 + 白 α0.55，内部 Card 置透明防双层白；FAB 磨砂（`XpFab._frostFab`）共享同参数保证视觉统一
- 弹窗磨砂：`showXpSheet` 重做（σ10 · 白 α0.7；遮罩 = 全屏高斯模糊 σ10 + 黑 α0.35）；内容**滑入动画结束后懒构建 + 淡入**；拖拽手柄下拉关闭；heightFactor 0.85
- 主题持久化 JSON 升 **v3**（新增 `sheetColor`），`_sanitizeTheme` 背景/卡色/弹窗色亮度兜底（保存拦截 + 读取兜底双保险）；新增主题设置页外观分区（动画开关/卡片样式/卡片圆角/磨砂分区）
- 新增测试：theme_persistence / theme_settings / xp_sheet / main_shell_fab

**F. 转场动画最终定型（3eddc0c + 6bc3bc1，2026-09-21）**

> 背景：用户反馈旧转场老闪屏，连做三轮全部被否，最后回到「不做动画」路线。历史与理由已写进 theme.dart / lazy_indexed_stack.dart 注释，**严禁再改回**。
> 注意：被否范围 = Tab 切换动画（位移轮播/交叉淡化/fade-through）与整页 Opacity 类方案。2026-09-21 第二轮决策重写 push/pop 为 iOS 拆层结构（§4 第二波 B1），Tab 切换仍保持瞬时，不冲突。

- **页面 push/pop**：`CupertinoPageTransitionsBuilder`（纯 Transform 滑动 + 旧页视差，整页**零 Opacity**，对磨砂 BackdropFilter 与快照均无负担）；`animationsEnabled=false` 时走自研 `_ZeroTransitionPageTransitionsBuilder`（零时长）
- **一级页 Tab 切换**：`LazyIndexedStack` 改为**瞬时切换**（无内容动画，Material 3 NavigationBar 标准行为）——此前 位移轮播（移一小段突切）/ 交叉淡化（两页半透明叠印重影闪屏）/ fade-through（近白屏闪一帧 + 磨砂层每帧重算抖动）全部废弃
- **日期选择补进出场**：`showXpDatePicker` / `showXpDateRangePicker`（淡入 + 上移 4%，替代裸 showDatePicker 弱转场）
- `buildXpScaffold` 移除内容级 XpEntrance 叠加（避免与路由转场双重动画）；XpEntrance 保留给特殊页面自用
- 转场选型备忘：Zoom（M3 默认）toImage 快照在 Impeller/Vulkan 阻塞 UI 线程；PredictiveBack 磨砂铺开时已移除；FadeForwards 本质仍交叉淡化且 800ms 更长

**验证状态**：`flutter analyze` 0 问题；`flutter test` 99 用例全过（上轮为 91）。工作区干净，最新提交 `6bc3bc1`。

## 4. 下一步待办（按优先级）

> 2026-09-21 第二轮重构调研结论（三路并行：性能卡顿 / 设计一致性 / 闪屏缺陷），详见下方「第二轮重构工作清单」。当前代码健康：analyze 0 + test 99 过。

### 第二轮重构工作清单（v2，2026-09-21 修订）

> 用户决策：调研产出的**降级类方案全部作废**（弹窗动画期降级 / 转场期降级 / 主题切换去动画 / σ 对砍）。动效全保留，掉帧根因是「结构没写对」不是「效果做不到」——按成熟设计重写实现。Tab 切换保持瞬时（§3-F 被否史不涉及 push/pop）。

**阶段 0：量化基线 ✅（2026-09-21 真机 profile 采集完成）**
- 工具：`lib/main_profile.dart`（`flutter run --profile -t lib/main_profile.dart`，程序化复现场景各 3 轮，FrameTiming 首跑 vs 复跑定性；main.dart 增全局 `appNavigatorKey` 仅供采集导航）
- 设备：小米 23127PN0CC / Android 16 / 有效 60Hz（预算 16.7ms）
- **结论：4 个窗口全部是「持续掉帧」，无 shader 一次性特征**（3 轮数据几乎一致）：
  - 主题页 push：avg 16-20ms，p95 35-48ms，worst 49-68ms，27 帧中 6-10 帧超 17ms；rasterAvg ~12ms 占预算 72% → **磨砂栏逐帧重算主导**（B1 假设成立）
  - 主题页 pop：同上，rasterAvg 10-12ms，worst 45-59ms
  - 弹窗打开：avg 19-22ms，p95 44-53ms，worst 62-68ms；**build+raster 双高**（buildWorst 37-56ms = 弹窗整棵树首帧懒构建；rasterAvg 13-15ms = 全屏 σ10 每帧重算）→ B2 的「提前构建 + 模糊到位后淡入」两个拆分都必要
  - 弹窗关闭（**新发现，最严重**）：仅 6-8 帧/窗口，totalAvg 26-43ms，**buildAvg 13-18ms 纯 build 瓶颈** —— 关闭动画期有昂贵重建（待定位：疑似 home 层重建或 sheet 内部 per-frame rebuild），B2 需补「关闭路径」排查
- 第一波 P3/P4/P7 已在本轮采集前修复完毕（analyze 0 问题，99 测试全过），不影响上述卡顿定性（卡顿路径与闪屏路径不重叠）

**第一波：闪屏纯 bug 修复 ✅（2026-09-21，随阶段 0 一并完成）**
- P3 loading 口径 ✅：home / accounts / account_manage 裸 `isLoading` → 改 `isLoading && value == null`（与 xp_async_view_mixin._branchOf 口径一致）
- P4 整页骨架切换与 XpStaggerIn 互斥 ✅：buildXpScaffold 的 AnimatedSwitcher 自定义 transitionBuilder——骨架淡入淡出、真实内容不加壳级透明度过渡（内容自己的 stagger 是唯一入场动画）
- P7 bookkeeping ✅：金额显示抽 ValueListenableBuilder 局部刷新（按键不再整页 setState）；默认分类选中移出 build（`_ensureDefaultCategory`，initState listenManual fireImmediately + 切换类型时调用）

**第二波：动效重做（保留动效，按 iOS 成熟设计重写实现）**
- B1 转场拆层 ✅（2026-09-22，theme + 页面壳）：iOS push 原生结构 = **栏静止 + 内容区滑动**
  - 实现：theme.dart 新增 `XpPageTransitionsBuilder`（route 级**零移动**，替换 Cupertino 整页滑动，旧页无视差）；页面壳 `XpRouteBar`（栏静止，**严禁 opacity/移动动画**——透明度动画包磨砂栏 = 每帧重算模糊快照，初版 FadeTransition 实测 raster 尖刺 20ms 后移除）+ `XpRouteBody`（内容 SlideTransition + ClipRect 限制在栏下，内容不侵入栏采样区 → 转场全程零模糊重算）
  - 复测（120Hz 基准，预算 8.3ms，`>1budget`/`>2budget` 为自适应超预算帧数）：push rasterAvg 14.1-20.1 → **14.7-16.0**（栏淡入版首帧模糊尖刺消除），>2budget 11→8；pop 12.4-16.5
  - **重要发现（设备刷新率）**：该机为动态刷新率（peak 120），采集期间从 60Hz 自动切到 120Hz 导致数据不可比。已把 harness 阈值改为 `budget=1000/refreshRate` 自适应（`>1budget`/`>2budget`）。**120Hz 下该设备任何全屏动画 raster 基础成本 10-12ms 已超 8.3ms 预算（物理无法满帧）**；60Hz（16.7ms 预算）下动画可稳定满帧。adb 无法锁定小米刷新率（settings 写入被忽略），已清理写入项。**建议用户日常使用 60Hz**
  - 残余 raster 12-16ms = 内容区滑动整块重绘（Impeller `enable_impeller_raster_cache:0`，无纹理缓存），属设备/引擎级限制，非结构问题
- B2 弹窗分层进入 ✅（2026-09-22，xp_sheet 重写）：iOS present sheet 原生结构 = 遮罩只变暗（无模糊）+ sheet 滑入 + 表面磨砂到位后淡入
  - 实现：删全屏 σ10 BackdropFilter；滑入改 SlideTransition + 磨砂改 FadeTransition（渲染属性零 rebuild）；内容首帧即构建（屏外构建成本不可见，消动画末帧懒构建尖刺）；磨砂只作用弹窗表面（ClipPath 内 BackdropFilter σ10 + 白 α0.7），滑入完成淡入 / **关闭或下拉瞬间归零**（淡出期间每帧绘制模糊 + sheet 移动采样区每帧变 = 关闭掉帧元凶）；sheet 外包 RepaintBoundary
  - 复测数据（60Hz 采集）：关闭 buildAvg **13-18ms → 1.4-2.3ms**（不再逐帧重建整树）、totalAvg 26-43 → 19-28、帧数 6-8 → 11-13；打开 rasterAvg 13-15 → 10.7-11.3（全屏模糊移除）。剩余 raster 13-18ms 为设备基础开销（普通页面 pop 也 ~12ms；`enable_impeller_raster_cache:0` 该机 Impeller 缓存关闭，RepaintBoundary 不产生纹理复用）
- B3 主题切换保动画 ✅（2026-09-22，theme + main）：200ms lerp 确认是 MaterialApp 内建 `AnimatedTheme`（`themeAnimationDuration`，非自建）；lerp 期间 rebuild/模糊重算是 SDK 结构，保动画前提下不可拆
  - 实现：① `buildAppTheme` **输入缓存**（theme identity + animOn + cardFrosted 为 key，亮/暗各一槽）——AnimatedTheme 按「ThemeData 实例是否变化」决定是否触发 lerp + 全树 rebuild，实例相同直接短路；此前每次 XuPurseApp.build 都新建实例（fromSeed 全量构建），**磨砂子项开关等无关 provider 波动也被当成主题切换触发假 lerp + 假 rebuild**，缓存后无关波动零成本、真切换一次构建。② `themeAnimationCurve: XpMotion.easeOut`（原 SDK 默认 easeInOut），与全站 motion token 统一
  - 「重页面首帧 const 化」收敛 lerp 期间 rebuild 构建成本 → 移第三波设计语言统一（与裸 Card 治理同批做）
- B4 磨砂正确性 ✅（2026-09-22，xp_card + xp_fab）：卡片/FAB 磨砂三缺陷全修，按压期间**零模糊重算**
  - ① `_frostCard`/`_frostFab` 补 `BackdropFilter.grouped` + `BlendMode.src`（对齐栏级 XpFrostedContainer；src 防御父级 saveLayer 混合异常；一级页有 BackdropGroup 祖先时栏/卡共享一次引擎模糊）
  - ② 每卡 `RepaintBoundary`（仅磨砂分支，非磨砂不包避免图层膨胀）：按压/ripple 重绘不波及其他卡
  - ③ **按压 AnimatedScale 移入模糊层内**（原结构模糊层被缩放 → 采样区每帧变 → 每帧重算）：改为磨砂表面固定在最外层、内容层在其内缩放——视觉等同（iOS 卡片按压：内容微缩、表面不动），采样区恒定
- 转场骨架短路 ✅（2026-09-22，mixin + theme_settings/trend 两页接入）：重页面（静态重 Card / fl_chart）转场期间只渲染轻量骨架（随内容区滑入），route animation completed 后再构建重内容；`xpPushSettled` getter + `_xpRouteAnim` 状态监听
  - **单测先暴露的逻辑漏洞（已修）**：挂 statusListener 前动画可能**早已 completed**（初始路由/MaterialApp home 直渲首帧即 1.0 paused，completed 事件已发过不重发）→ 骨架永远等不到 completed 常驻 → 页面卡死 loading（骨架脉冲无限循环，pumpAndSettle 超时，theme_settings_test 6 用例挂）。修复：挂 listener 后补查一次 `anim.status == completed` 直接置 settled。push 场景（dismissed 起步）不受影响
- 转场时长/曲线统一（用户要求：非线性、稍慢优雅）✅（2026-09-22）：新增 `XpRoute<T>`（MaterialPageRoute 子类，mixin 文件内）——**400ms（XpMotion.page，双向同速，SDK 默认 300）+ easeOutCubic 正反向同曲线**；曲线单一来源在 route 层 `createAnimation`，XpRouteBody 不再二次包 curve（原 fastEaseInToSlowEaseOut 叠加层移除）；全库 12 处 push + main_profile 全部换 XpRoute
  - **顺手修 bug**：XpRouteBody 原不读动画开关——pageTransitionsTheme 的 zero builder 管不到壳层，animationsEnabled=false / reduce-motion 时内容区仍滑动；现 build 内自判（ProviderScope 读 animationsEnabled + MediaQuery.disableAnimationsOf），关闭时直接返回 child
- 验证状态：analyze 0 问题；test 99 全过（含修复后 theme_settings 6 用例）。web 端**未做正式 profile**：B4 收益全部是 Impeller raster 语义（web CanvasKit/Skwasm 管线不同不可迁移），转场时长/曲线为时序参数无需 profile，帧率基线权威数据只能回小米真机（60Hz）补采
- 待真机补采：① B4 按压零重算验证（卡片按压 raster）② XpRoute 400ms 转场满帧确认 ③ B3 主题切换 lerp 期间帧率

**第三波：设计语言统一（治「丑 / 漏卡片」）**——审计结论：基建（token/XpCard/页面壳）完整，问题是二级页大量「绕过基建」
- 修复优先级：statistics/ 6 分区（14+ 裸 Card 缺按压/磨砂 + KPI/排行金额漏 tabular）> trend（4 裸 Card + 裸转圈 + 裸文本空态）> theme_settings（5 裸 Card，设置分组与 mine 样板不一致）> ai_settings（全库唯一裸 Scaffold 绕开 buildXpScaffold + 残留 XpEntrance）> settings（图标色块未对齐 mine）> ai_chat_sheet（全库唯一裸 showModalBottomSheet）
- 系统性收口：错误态统一（xpWhen 已提供但页面没用）、空态三分法（有的 XpEmptyState 有的裸 Text）、间距字面量、裸 Card 全局盘点（import/account_detail/data_manage/currency/book/budget/ledger/icon_settings）

### 常规待办
1. **阶段 3 整体验收**（ui-refactor-plan §五）：analyze 全库零问题（当前已 0）→ 真机亮/暗两套全页走查（含磨砂三子项开关 × 图标包切换两态）→ DevTools 帧率 → 主题迁移清除/保留双场景；暗色模式下白色磨砂的可读性待用户反馈（固定白色为用户明确要求）
2. 弹层/共享组件剩余微调（xp_sheet 拖拽-blur 同一 progress 驱动、bill_tile subtitle、xp_empty_state 图标尺寸、xp_snack 对齐 token）
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
| lib/ui/widgets/ | Xp 组件族：xp_card / xp_fab / xp_skeleton / xp_stagger_in / xp_sheet / xp_snack / xp_empty_state / xp_frosted_bar / app_icon |
| lib/state/theme_provider.dart | 主题状态（含亮度校验双保险）+ FrostedState 磨砂三子项开关 |
| lib/state/icon_pack_provider.dart | 图标包全局开关（简约 / Twitter 表情） |
| lib/core/utils/twemoji_icons.dart | twemoji SVG 注册表 + materialEmojiNames 映射 |
| lib/data/repositories/bill_repository.dart | 账单查询（minBillTime / sumByTagInRange / transferFeeOf） |
| lib/data/repositories/ledger_repository.dart | 借贷/报销/退款/分期 watch + delete |
| lib/state/providers.dart | 全局 Provider 清单 |
| lib/ui/pages/statistics/ | 统计页拆分后 5 分区 + stats_shared |

## 7. 近期提交参考（git log 风格）

- `fix:转场动画重做` / `feat:页面转场改轻量无快照动画+日期选择补进出场动画+磨砂参数一致性`
- `feat:配置弹窗统一重构+卡片/FAB真实磨砂+主题持久化修复` / `feat:卡片磨砂玻璃效果`
- `feat:图标包切换(简约/Twitter表情)全站适配+趋势页图表卡片化`
- `fix:代码审核P1/P2修复:台账删除确认+脏主题兜底+分层收敛+分类过滤`
- `feat:阶段2动效打磨:转场复核+XpFab微缩放+stagger淡入试点+reduce-motion链路核查`
- `fix:主题页暗色预设独立分区+自定义背景深度校验;弹层七件套排印统一`
- `feat:阶段1逐页重构:Tab四页+二级页16页全部完成`
- `feat:卡片基类微交互` / `ui：页面基类升级——预测性返回+进场动画+懒挂载` / `ui：克莱因蓝主题收敛+骨架屏淡入`
