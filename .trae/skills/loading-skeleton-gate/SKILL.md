---
name: loading-skeleton-gate
description: 处理页面转场卡顿的「加载骨架门」，转场期间只渲染骨架、重内容延后构建或延后启动。当用户说某页面进入会卡、要给页面开加载骨架门或开开关时使用。不用于非转场原因导致的性能问题。
---

# 加载骨架门

「加载骨架门」是本项目对**一类页面性能优化**的统一叫法：push 转场动画进行期间，页面只渲染轻量骨架，重内容（重 widget 树 / 耗时任务）挡在门外，动画零抢帧；转场 completed 后再构建真实内容或启动任务。用户感知为「内容晚半秒左右显示」，而不是「转场卡顿」。

用户不会区分具体是哪一档门，**统一说「加载骨架门」**即可，由你判断该开哪一档。典型话术：

> 页面 X 进去会卡，帮我开加载骨架门。

## 先判断病根，再选开关

| 病根 | 现象 | 开关 |
| --- | --- | --- |
| 首帧构建重 | 静态卡片多、列表长、图表重，数据本身是同步/已缓冲的 | 构建门 |
| 进页面即启动耗时任务 | initState 里就跑 DB 聚合、遍历大量账单、生成摘要 | 任务门 |

两者可以叠加：页面既首帧重、initState 又有耗时任务时，两个都上。

**判定方法**：读页面 initState/build。initState 里直接调 `_load()` / 启动异步计算且该计算对账本做大量 DB 聚合 → 任务门；只是 `ref.watch` 数据、构建 `ListView`/`Column`/大量卡片 → 构建门。

## 开关一：构建门（`buildBody`）

适用首帧构建昂贵的页面。把 `body:` 换成 `buildBody: (_) => ...`，基类自动在转场期间出整页骨架。

```dart
return buildXpScaffold(
  appBar: appBar,
  buildBody: (_) => ListView(...), // 原 body 的 widget 原样搬进来
);
```

要点：

- 只改参数名，widget 树不动；外层 `PopScope` 等包裹保持原样。
- 原有 `loading:` 条件保留不动（两者是「首载骨架」与「转场骨架」两个语义，可共存）。
- 不要写 `if (!xpPushSettled) return buildXpScaffold(loading: true);` 手写短路——那是老写法，已全部收敛到 `buildBody`。

## 开关二：任务门（`xpRunWhenSettled`）

适用「进页面就要拉数据/算摘要」的页面。把 initState 里的耗时调用换成 `xpRunWhenSettled(...)`，任务推迟到转场 completed 后执行。

```dart
@override
void initState() {
  super.initState();
  // 摘要生成对账本做大量 DB 聚合，转场期间同步启动会抢主线程掉帧；
  // 推迟到转场 completed 后再执行（基类 xpRunWhenSettled）。
  xpRunWhenSettled(_load);
}
```

只换调用点，`_load` 本体不动。

## 实现位置

全部逻辑在 [xp_page_scaffold_mixin.dart](file:///Users/hookii/Desktop/code/project/xyx/XuPurse/lib/ui/layout/xp_page_scaffold_mixin.dart) 的 `XpPageScaffold` mixin：`buildBody` 参数 + `xpPushSettled` 门 + `xpRunWhenSettled`。页面侧只做最小声明，不要复制逻辑到页面里。

## 已开通清单

改动页面时保持与本清单一致的写法，新增页面追加在此。

构建门：theme_settings_page、trend_page、search_page、ai_scope_page、ai_scope_help_page、ai_help_page、account_manage_page、account_detail_page、report/report_list_page、report/total_report_page、report/year_report_page。

任务门：ai_scope_preview_page。

## 三个必须知道的陷阱

改动 `xpPushSettled` / `xpRunWhenSettled` 相关逻辑时注意，现有实现已处理，不要退化：

1. **首帧 offstage**：ModalRoute 首帧为 Hero 定位而 offstage 构建，此刻 `route.animation` 代理是 `kAlwaysCompleteAnimation`（status=completed），但真实转场刚起步。必须判 `route.offstage` 提前返回 false，否则骨架门形同虚设。
2. **动画已 completed 的补查**：挂 listener 时动画可能早已 completed，事件不会重发，需补查 `anim.status == AnimationStatus.completed`，否则骨架/任务永远等不到。
3. **`ModalRoute.of` 不能在 initState 同步调用**（依赖 InheritedWidget 查询），`xpRunWhenSettled` 内部已用 `addPostFrameCallback` 推迟。

## 边界

- 弹窗（showXpSheet / showGeneralDialog）的骨架门是另一套 `XpSettleGate`，目前只有 `xpEnterSettled`，**不要为它加任务门**，等有「弹窗一打开就算数据」的实际场景再补。
- `xpFirstSettled` 是无路由转场的 tab 常驻页用的首帧门，与加载骨架门不是同一场景。
- 不要主动扩大改动范围，按用户点名的页面逐个开。

## 验证

改完跑：

```bash
flutter analyze lib/ui/pages/<改动文件>.dart
```

要求 `No issues found!`。
