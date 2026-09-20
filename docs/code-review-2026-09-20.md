# XuPurse 全局代码审核报告（2026-09-20）

> 审核范围：lib/ 全库 98 文件 3.5 万行；基线 analyze 0 / 91 测试全过。
> 分级：P1=应尽快修（正确性/数据风险） · P2=建议修（质量/一致性） · P3=记录在案（低风险/风格）。

## ✅ 已核查无问题的维度
- dispose 完整性：12 处 TextEditingController 全部有 dispose 路径（State.dispose 或 dialog await 返回后），xp_skeleton/_Pulse、xp_stagger_in 的 AnimationController 均正确释放；listenManual 订阅（stats_shared/trend_page）在 dispose close 或随 State 销毁。
- 异步安全：stagger 的 Future.delayed 回调带 mounted 防护；各 sheet 的 await 后 setState/Navigator 均有 mounted 检查；search `_AnalysisView` 用 identical() 判断 bills 引用变化，无请求风暴。
- SQL 注入面：全部 customSelect 用 Variable 占位符，无字符串拼接用户输入（account_service lastActiveTimes 的 placeholders 是自生成的 `?` 列表，安全）。
- 事务边界：mergeAccounts/setCurrencies/deleteBill/updateBill/recalculateAllBalances/adjustBalance 等多表写全部包 _db.transaction。
- 金额类型：全库 int 万分之元，无 double 混入存储层（web 端显示层转 double 仅在 fl_chart spot）。
- 统计口径：sumByType/sumByCategoryInRange/sumByTagInRange/summaryInRangeOnce/watchSummaryInRange 六处 `_excludedSql`（排除「不计入收支」）逐一核对全部在位；listByRange 也排除了；转账不会混入收支柱出（type IN 显式过滤）。
- 大列表：全库无 ListView(children:) 大列表误用；首页分页逐月加载。
- 无 print/debugPrint 残留、无 TODO/FIXME 欠账。
- domain 层纯净性：lib/domain 无 material/widgets 依赖（仅 flutter_riverpod 状态注入，属可接受）；provider 依赖图无环，最深 watch 链 3 层（totalAssetsProvider），均在合理范围。
- FutureBuilder future 存字段：全库核对（book_manage _booksFuture / search _billTagsFuture / statistics 5 分区 _future）均存 State 字段+initState/didUpdateWidget 触发，无 build 内直建。

## 🔴 P1（建议尽快修）

### P1-1 借贷/报销/退款/分期删除无确认弹窗 + 无余额联动
`lib/ui/pages/ledger_manage_page.dart:98/138/168/198`——四个业务表的删除按钮直接 `_delete(ref, table, id)`：
1. 无二次确认（误触即删，其他页面危险操作均有 confirmXpDialog）；
2. lends 表记录有 billId 关联账单，删除记录**不回滚对应账单/余额**（退款 refunds.billId 同理），用户删掉一条借贷记录后，关联账单仍在、余额不变——数据口径出现悬空。
建议：删除前 confirmXpDialog(danger)；有 billId 的记录提示「仅删除记录，关联账单不受影响」或提供「连账单一起删」选项。

### P1-2 主题对比度校验只挡新保存，存量脏主题仍在
`theme_provider.dart _loadUserThemes()`——用户已保存的过深背景主题（如截图中的「111」）依然会在下次启动加载并应用。保存拦截只是防新增。
建议：_loadUserThemes 读出后校验 background/cardColor 亮度，过深的主题置为无效（回退克莱因蓝）或提示修复。

## 🟡 P2（建议修）

### P2-1 ledger_manage_page 的 4 个 StreamProvider 缺 autoDispose
`:226/232/238/244`——_lends/_reimbursements/_refunds/_instalmentsProvider 是 push 进出的台账页专用流，离开页面后连接不释放（drift watch 持续监听）。accountBillsProvider 已是 autoDispose.family（正确样板）。
建议：改成 StreamProvider.autoDispose。

### P2-2 ledger UI 直接摸 dbProvider 删表/建流，绕过 repo/service 分层
`ledger_manage_page.dart:218-240`——`_db(ref)` helper 直接读 dbProvider 删记录、select().watch() 建流；category_manage FAB 同样 showModalBottomSheet 内嵌表单。UI 层直接操作 drift 是项目分层约定的例外（其他页面全部走 repo）。
建议：下沉 LedgerRepository（4 个 watch + delete），或至少收敛到一个 ledger_service。工程量小、收益是全库分层一致。

### P2-3 bookkeeping_sheet 编辑转账时直接查 transfers 表
`bookkeeping_sheet.dart:112`——`ref.read(dbProvider).select(...transfers)` UI 直查。同 P2-2 属分层例外。
建议：给 BillRepository 加 `transferFeeOf(billId)`。

### P2-4 search 分类下拉混入「转账」类型分类
`search_page.dart:130-133`——分类下拉直接展开 categoriesProvider 全量（含 type=transfer 的「转账/转出/转入」种子分类）。账单搜索选转账分类永远 0 结果（转账单 categoryId 语义不同），误导用户。
建议：下拉按当前 _type 过滤（或排除 transfer 类型）。

### P2-5 主题设置页暗色模式卡片是「死卡片」
theme_settings_page 暗色模式 Card 无任何交互，用户会点它期待「预览暗色」。要么给它 onTap 弹说明（当前仅系统开关生效），要么干脆做成静态展示卡并去掉可点击视觉。
建议：保持静态但去掉 Card 的 elevation 反馈暗示，或 onTap 弹 toast「跟随系统设置」。

## 🟢 P3（记录在案）

- P3-1 `currentThemeProvider` 读 platformBrightness 不响应系统切换（Provider 无监听）。实际无影响：main.dart 的 MediaQuery.of 会带 rebuild，且 Web 端暗色跟随系统本来就是弱需求。若以后要做「App 内手动暗色开关」需先解决此处。
- P3-2 `statsDataVersionProvider`（stats_shared.dart:11）的 watchAll 全表流只为 bump 版本号，每次任意账单变化触发 5 个分区全部重查——设计如此（简单可靠），账单量大后可优化为按表节流。
- P3-3 statistics 趋势分区 `_TrendSection` 与 `_TrendCompareCard` 各自 _load 各查一次 listByRange(同区间 expense)，同屏两查。数据量小无感，合并需重构数据流，暂不动。
- P3-4 XpFab disabled 态（onPressed=null）时 Listener 仍会缩放——当前 7 处调用全部恒启用，无实际影响；如未来出现动态禁用需补 `onPointerDown: widget.onPressed == null ? null : ...`。
- P3-5 about_page 用 showAboutDialog 展示隐私说明是权宜（原生对话框样式与全 App 不统一），可换 showXpDialog。
- P3-6 xp_stagger_in 的 40ms/项 × 12 = 最长 480ms 完整淡入序列，略超 XpMotion.page(400ms) 总时长感知；如觉得慢可把封顶调到 200ms。
- P3-7 statistics/stats_budget_section 用 db.customSelect 算预算区间花费——严格分层应下沉 budget_repo（同 P2-2 家族）；因 SQL 含排除「不计入收支」口径且只此一处用，暂记录不动。

## 修复优先级建议
1. P1-1（ledger 删除确认+口径说明）——用户可感知的数据风险
2. P1-2（存量脏主题兜底）——配合上次「全蓝」修复闭环
3. P2-1/2/2-3（ledger/bookkeeping 分层收敛）——一次 commit 顺带完成
4. P2-4（search 分类过滤）——一行 where 的事
