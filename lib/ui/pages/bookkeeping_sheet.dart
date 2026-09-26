import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/bill_extra.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/currency_service.dart';
import '../../state/default_account_provider.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/currency_meta.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart' show kExpenseColor, kIncomeColor;
import '../widgets/xp_card.dart';
import '../widgets/xp_param_row.dart';
import '../widgets/xp_picker_sheet.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/xp_sliding_segmented.dart';
import '../widgets/xp_snack.dart';

/// 弹窗最大高度占屏比（95%，接近全屏的记账面板）。
const double _maxHeightFactor = 0.95;

/// 数字键盘按键高度。
const double _keyHeight = 50;

/// 金额显示行高度（独立于按键高度：键盘加高后金额区不再同步放大，
/// 把更多空间让给数字键）。
const double _amountRowHeight = 44;

/// 键盘底部额外空白：内容不变，仅把键盘整体上顶约 20dp，
/// 避免数字键贴近全面屏手势区 / 底部导航。
const double _keyboardBottomSpace = 20;

/// 分类网格列数与单元格宽高比。
const int _categoryColumns = 5;
const double _categoryAspect = 0.95;

/// 备注 / 手续费内嵌输入框宽度。
const double _inlineFieldWidth = 160;

/// 分类选中态的描边宽度。
const double _cellBorderWidth = 1.5;

/// 记账弹窗：支出 / 收入 / 转账 + 数字键盘 + 二级分类 + 账户选择。
///
/// [initialBill] 非空时为编辑模式（保存走 updateBill）。
class BookkeepingSheet extends ConsumerStatefulWidget {
  const BookkeepingSheet({super.key, this.initialBill});

  final Bill? initialBill;

  static Future<void> show(BuildContext context, {Bill? bill}) {
    // 记账弹窗 95% 屏高、出场动画比通用弹层更慢（XpMotion.container），
    // 滑入/滑出用非线性曲线（easeOutCubic）。
    return showXpSheet(
      context: context,
      heightFactor: 0.95,
      transitionDuration: XpMotion.container,
      transitionCurve: Curves.easeOutCubic,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: BookkeepingSheet(initialBill: bill),
      ),
    );
  }

  @override
  ConsumerState<BookkeepingSheet> createState() => _BookkeepingSheetState();
}

class _BookkeepingSheetState extends ConsumerState<BookkeepingSheet>
    with XpSettleGate<BookkeepingSheet> {
  late BillType _type;
  // 金额局部刷新：键盘按键只更新 notifier + 金额显示区，不再整页 setState
  final ValueNotifier<String> _amountText = ValueNotifier('');
  String? _parentId;
  String? _subId;
  String? _accountId;
  String? _incomeAccountId;
  final _feeController = TextEditingController();
  DateTime _date = DateTime.now();
  final _commentController = TextEditingController();
  final Set<String> _tagIds = {};

  /// 不计入收支：仅记流水与余额，不参与收入/支出统计。
  bool _excludeFromStats = false;

  /// 记账币种（[CurrencyService.supportedCodes]；null = 跟随账户币种）。
  String? _currencyCode;

  bool get _isEdit => widget.initialBill != null;

  @override
  void initState() {
    super.initState();
    final bill = widget.initialBill;
    _type = bill == null ? BillType.expense : BillType.values.byName(bill.type);
    // 分类 / 账户流就绪时补选默认项（原逻辑写在 build 内，已移出）
    ref.listenManual(
      categoriesProvider,
      (_, __) => _ensureDefaultCategory(),
      fireImmediately: true,
    );
    ref.listenManual(
      accountsProvider,
      (_, __) => _ensureDefaultAccount(),
      fireImmediately: true,
    );
    if (bill != null) {
      // 外币账单编辑时显示原外币金额（保存时按当前汇率重新换算）
      _amountText.value =
          bill.currencyCode != null && bill.currencyAmount != null
          ? formatYuan(bill.currencyAmount!)
          : formatYuan(bill.amount);
      _parentId = bill.categoryId;
      _accountId = bill.accountId;
      _incomeAccountId = bill.incomeAccountId;
      _commentController.text = bill.comment ?? '';
      _date = DateTime.fromMillisecondsSinceEpoch(bill.time);
      _currencyCode = bill.currencyCode;
      _excludeFromStats = BillExtra.fromJson(bill.extra).excludeFromStats;
      if (bill.type == BillType.transfer.name) _loadTransferFee();
      _loadTags();
    }
  }

  /// 无选中时兜底默认分类（从 build 内移出，避免构建期间写状态）。
  void _ensureDefaultCategory() {
    if (_parentId != null) return;
    final all = ref.read(categoriesProvider).valueOrNull ?? const <Category>[];
    if (_type == BillType.transfer) {
      // 转账：不展示分类选择，兜底直接用转账一级分类（而非误落到收入分类），
      // 与导入 mapper 的 fallbackCategoryId(transfer, ['transfer']) 一致。
      final transfer = all.firstWhere(
        (c) => c.type == BillType.transfer.name && c.parentId == null,
        orElse: () => const Category(
          id: '',
          name: '',
          type: '',
          customName: false,
          defaultSelect: false,
          sort: 0,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      if (transfer.id.isNotEmpty) _parentId = transfer.id;
      return;
    }
    final type = _type == BillType.expense ? BillType.expense : BillType.income;
    final parents = all
        .where((c) => c.type == type.name && c.parentId == null)
        .toList();
    if (parents.isEmpty) return;
    final def = all.firstWhere(
      (c) => c.type == type.name && c.defaultSelect,
      orElse: () => parents.first,
    );
    _parentId = def.id;
    // 一级分类没有子分类时直接视为已选中，保存时无需再点
    final hasSubs = all.any((c) => c.type == type.name && c.parentId == def.id);
    if (!hasSubs) _subId = def.id;
  }

  /// 无选中时兜底默认账户：优先用「设置 - 默认账户」里的偏好，
  /// 未设置或账户已不在当前账本时取第一个可用账户（见 docs/modules.md）。
  void _ensureDefaultAccount() {
    // 转账的转出 / 转入需用户显式选择，不做兜底
    if (_type == BillType.transfer) return;
    if (_accountOf(_accountId) != null) return;
    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    if (accounts.isEmpty) return;
    final prefs = ref.read(defaultAccountProvider);
    final preferred = _type == BillType.expense
        ? prefs.expenseAccountId
        : prefs.incomeAccountId;
    _accountId = _accountOf(preferred)?.id ?? accounts.first.id;
    // 账户变化后回到跟随账户币种
    _currencyCode = null;
  }

  /// 编辑模式：回填账单标签（避免保存时清空原标签）。
  Future<void> _loadTags() async {
    final bill = widget.initialBill;
    if (bill == null) return;
    final ids = await ref.read(billRepoProvider).tagIdsOf(bill.id);
    if (mounted) setState(() => _tagIds.addAll(ids));
  }

  /// 按 id 取账户；未命中返回 null。
  Account? _accountOf(String? id) {
    if (id == null) return null;
    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// 当前账户币种（无账户或未命中按 CNY 兜底）。
  String _accountCurrencyOf(String? id) => _accountOf(id)?.currency ?? 'CNY';

  /// 记账币种（未显式选择时跟随账户币种）。
  String get _effectiveCurrency =>
      _currencyCode ?? _accountCurrencyOf(_accountId);

  /// 编辑转账账单时，从 Transfers 表回填手续费（避免编辑后丢失原手续费）。
  Future<void> _loadTransferFee() async {
    final bill = widget.initialBill;
    if (bill == null) return;
    final fee = await ref.read(billRepoProvider).transferFeeOf(bill.id);
    if (fee != null && mounted) {
      setState(() => _feeController.text = formatYuan(fee));
    }
  }

  @override
  void dispose() {
    _amountText.dispose();
    _commentController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  // ---------- 输入 ----------

  void _append(String ch) {
    final cur = _amountText.value;
    String next = cur;
    if (ch == '.') {
      if (!cur.contains('.')) {
        next = cur.isEmpty ? '0.' : '$cur.';
      }
    } else if (ch == '00') {
      if (cur.isNotEmpty && cur != '0' && !cur.contains('.')) {
        // 与单数字键一致受 9 位整数上限约束（cur 无小数点时 length 即整数位数）。
        if (cur.length + 2 <= 9) {
          next =
              '$cur'
              '00';
        }
      }
    } else {
      // 数字
      final intPart = cur.split('.').first;
      if (cur.contains('.')) {
        final frac = cur.split('.')[1];
        if (frac.length < 2) next = cur + ch; // 最多两位小数
      } else if (intPart.length < 9) {
        next = cur == '0' ? ch : cur + ch;
      }
    }
    if (next != cur) _amountText.value = next;
  }

  void _backspace() {
    final cur = _amountText.value;
    if (cur.isNotEmpty) _amountText.value = cur.substring(0, cur.length - 1);
  }

  void _clear() => _amountText.value = '';

  // ---------- 选择 ----------

  /// 账户选择面板；[income] 为 true 时改的是转入账户。
  Future<void> _pickAccount({required bool income}) async {
    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    if (accounts.isEmpty) {
      _toast('暂无可用账户');
      return;
    }
    final choice = await showAccountPickerSheet(
      context: context,
      accounts: accounts,
      selectedId: income ? _incomeAccountId : _accountId,
      title: switch ((_type, income)) {
        (BillType.transfer, false) => '转出账户',
        (BillType.transfer, true) => '转入账户',
        _ => '账户',
      },
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (income) {
        _incomeAccountId = choice.value;
      } else {
        _accountId = choice.value;
        // 切换账户后回到跟随账户币种
        _currencyCode = null;
      }
    });
  }

  /// 记账币种面板（首项「跟随账户」回传 null）。
  Future<void> _pickCurrency() async {
    final accountCurrency = _accountCurrencyOf(_accountId);
    final choice = await showCurrencyPickerSheet(
      context: context,
      accountCurrency: accountCurrency,
      currentCode: _currencyCode,
    );
    if (choice == null || !mounted) return;
    setState(() {
      // 选到与账户币种一致时等价于「跟随账户」，归一化成 null
      _currencyCode = choice.value == accountCurrency ? null : choice.value;
    });
  }

  /// 标签多选面板（新选中的标签若带优先币种，同步记账币种）。
  Future<void> _pickTags() async {
    final tags = ref.read(tagsProvider).valueOrNull ?? const <Tag>[];
    if (tags.isEmpty) return;
    final picked = await showTagPickerSheet(
      context: context,
      tags: tags,
      selectedIds: _tagIds,
    );
    if (picked == null || !mounted) return;
    setState(() {
      final added = picked.difference(_tagIds);
      _tagIds
        ..clear()
        ..addAll(picked);
      for (final tag in tags) {
        if (!added.contains(tag.id)) continue;
        final prefer = tag.preferCurrency;
        if (prefer != null && prefer.isNotEmpty) {
          _currencyCode = prefer;
          break;
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showXpDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ---------- 保存 ----------

  Future<void> _save() async {
    final amountInput = parseYuanInput(_amountText.value);
    if (amountInput == null || amountInput <= 0) {
      _toast('请输入有效金额');
      return;
    }
    final categoryId = _subId ?? _parentId;
    if (categoryId == null) {
      _toast('请选择分类');
      return;
    }
    if (_type != BillType.transfer && _accountId == null) {
      _toast('请选择账户');
      return;
    }
    if (_type == BillType.transfer) {
      if (_accountId == null || _incomeAccountId == null) {
        _toast('请选择转出与转入账户');
        return;
      }
      if (_accountId == _incomeAccountId) {
        _toast('转出与转入账户不能相同');
        return;
      }
    }
    final time = DateTime(
      _date.year,
      _date.month,
      _date.day,
      DateTime.now().hour,
      DateTime.now().minute,
    ).millisecondsSinceEpoch;

    // ---- 多币种：输入币种 → 账户币种换算 ----
    final rates = ref.read(currencyServiceProvider);
    final billCur = _effectiveCurrency;
    final base = ref.read(baseCurrencyProvider).value ?? 'CNY';
    var amount = amountInput;
    int? transferToAmount;
    String? currencyCode;
    int? currencyAmount;
    if (_type == BillType.transfer) {
      final fromCur = _accountCurrencyOf(_accountId);
      final toCur = _accountCurrencyOf(_incomeAccountId);
      final feeText = _feeController.text.trim();
      final feeInput = feeText.isEmpty ? 0 : (parseYuanInput(feeText) ?? 0);
      // 转出金额与手续费先换算到转出账户币种，再换算到转入账户币种作为到账金额
      final amountFrom = billCur == fromCur
          ? amountInput
          : convertAmount(amountInput, billCur, fromCur, rates);
      final feeFrom = billCur == fromCur
          ? feeInput
          : convertAmount(feeInput, billCur, fromCur, rates);
      final netFrom = (amountFrom - feeFrom).clamp(0, amountFrom);
      amount = amountFrom;
      transferToAmount = fromCur == toCur
          ? netFrom
          : convertAmount(netFrom, fromCur, toCur, rates);
      if (billCur != fromCur) {
        currencyCode = billCur;
        currencyAmount = amountInput;
      }
    } else {
      final fromCur = _accountCurrencyOf(_accountId);
      if (billCur != fromCur) {
        currencyCode = billCur;
        currencyAmount = amountInput;
        amount = convertAmount(amountInput, billCur, fromCur, rates);
      }
    }

    try {
      final billService = ref.read(billServiceProvider);
      if (_isEdit) {
        await billService.updateBill(
          widget.initialBill!.id,
          type: _type,
          categoryId: categoryId,
          amount: amount,
          accountId: _accountId,
          incomeAccountId: _incomeAccountId,
          time: time,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          tagIds: _tagIds.toList(),
          extra: _buildExtra(),
          transferToAmount: transferToAmount,
          currencyCode: currencyCode,
          currencyAmount: currencyAmount,
          baseCurrency: currencyCode == null ? null : base,
          // 编辑外币账单时用户改回「跟随账户币种」= 显式清空外币标记
          // （currencyCode 传 null 本身被 updateBill 的 ?? old 保留，需单独通知）。
          clearCurrency:
              currencyCode == null && widget.initialBill!.currencyCode != null,
        );
      } else {
        await billService.addBill(
          type: _type,
          categoryId: categoryId,
          amount: amount,
          accountId: _accountId,
          incomeAccountId: _incomeAccountId,
          time: time,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          tagIds: _tagIds.toList(),
          extra: _buildExtra(),
          transferToAmount: transferToAmount,
          currencyCode: currencyCode,
          currencyAmount: currencyAmount,
          baseCurrency: currencyCode == null ? null : base,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _toast('保存失败：$e');
    }
  }

  /// 组装扩展字段：编辑时保留原来源标记（isYimu 等）与业务关联字段，
  /// 仅覆盖「不计入收支」开关，避免保存后丢导入标记。
  BillExtra _buildExtra() {
    final old = widget.initialBill == null
        ? const BillExtra()
        : BillExtra.fromJson(widget.initialBill!.extra);
    return BillExtra(
      isAdjustment: old.isAdjustment,
      isYimu: old.isYimu,
      isZhouhu: old.isZhouhu,
      isQianji: old.isQianji,
      excludeFromStats: _excludeFromStats,
      other: old.other,
    );
  }

  void _toast(String msg) {
    showXpSnack(context, msg);
  }

  // ---------- 构建 ----------

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 滑入动画期间只渲染骨架：分类网格 / 账户 / 标签 / 键盘整树首帧构建
    // 会撞上 sheet 滑入动画抢帧；route animation completed 后首次构建
    // 真实内容（XpSettleGate 骨架门）。
    if (!xpEnterSettled) {
      return const XpSkeletonPage();
    }
    final isTransfer = _type == BillType.transfer;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * _maxHeightFactor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTypeTabs(),
          const Divider(height: 1),
          // 分类/转账主体 + 明细参数行都在滚动区内，键盘固定底部，
          // 内容多时可滑动，避免挤压显得局促。
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: XpSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isTransfer) ...[
                    _buildCategoryBody(),
                    const SizedBox(height: XpSpacing.m),
                  ],
                  _buildSettingsSection(scheme),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildKeyboard(scheme),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.s,
        XpSpacing.l,
        XpSpacing.m,
      ),
      child: XpSlidingSegmented<BillType>(
        items: const [
          XpSegmentedItem(
            value: BillType.expense,
            label: '支出',
            icon: Icons.south_west,
          ),
          XpSegmentedItem(
            value: BillType.income,
            label: '收入',
            icon: Icons.north_east,
          ),
          XpSegmentedItem(
            value: BillType.transfer,
            label: '转账',
            icon: Icons.swap_horiz,
          ),
        ],
        selected: _type,
        onChanged: (t) => setState(() {
          _type = t;
          _parentId = null;
          _subId = null;
          _ensureDefaultCategory();
          _ensureDefaultAccount();
        }),
      ),
    );
  }

  /// 分类网格（一级分类；有子分类时选中后展开二级行）
  Widget _buildCategoryBody() {
    final type = _type == BillType.expense ? BillType.expense : BillType.income;
    final categoriesAsync = ref.watch(categoriesProvider);
    if (categoriesAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(XpSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final all = categoriesAsync.value ?? const <Category>[];
    final parents = all
        .where((c) => c.type == type.name && c.parentId == null)
        .toList();
    final childrenOf = <String, List<Category>>{};
    for (final c in all) {
      if (c.type != type.name || c.parentId == null) continue;
      childrenOf.putIfAbsent(c.parentId!, () => []).add(c);
    }
    final accent = _type == BillType.expense ? kExpenseColor : kIncomeColor;
    // 逐行构建分类网格：点击带子分类的一级分类后，展开区紧贴该行下方
    // 「裂开」插入（AnimatedSize 平滑撑开），子分类以同列数网格呈现。
    final rows = <Widget>[];
    for (var i = 0; i < parents.length; i += _categoryColumns) {
      final end = i + _categoryColumns < parents.length
          ? i + _categoryColumns
          : parents.length;
      final rowParents = parents.sublist(i, end);
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in rowParents)
              Expanded(
                child: AspectRatio(
                  aspectRatio: _categoryAspect,
                  child: _CategoryCell(
                    category: c,
                    selected: _parentId == c.id,
                    accent: accent,
                    onTap: () => setState(() {
                      _parentId = c.id;
                      final subs = childrenOf[c.id] ?? const [];
                      _subId = subs.isEmpty ? c.id : null;
                    }),
                  ),
                ),
              ),
            // 末行不足 5 列时空位补齐，保持网格对齐
            for (var j = rowParents.length; j < _categoryColumns; j++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      final subs = childrenOf[_parentId] ?? const [];
      if (subs.isNotEmpty && rowParents.any((c) => c.id == _parentId)) {
        rows.add(_buildSubCategoryPanel(subs, accent));
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }

  /// 二级分类展开区：紧贴选中行下方插入，5 列网格 + 首项「全部」。
  Widget _buildSubCategoryPanel(List<Category> subs, Color accent) {
    return AnimatedSize(
      duration: XpMotion.component,
      curve: XpMotion.easeOut,
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: XpSpacing.s),
        child: Container(
          padding: const EdgeInsets.all(XpSpacing.m),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(XpRadius.s),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _categoryColumns,
              childAspectRatio: _categoryAspect,
              mainAxisSpacing: XpSpacing.s,
            ),
            itemCount: subs.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return _SubCategoryCell(
                  icon: Icons.all_inclusive,
                  label: '全部',
                  selected: _subId == null || _subId == _parentId,
                  accent: accent,
                  onTap: () => setState(() => _subId = _parentId),
                );
              }
              final sub = subs[i - 1];
              return _SubCategoryCell(
                iconName: sub.icon,
                label: sub.name,
                selected: _subId == sub.id,
                accent: accent,
                onTap: () => setState(() => _subId = sub.id),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 明细参数区：账户 / 币种 / 标签 / 日期 / 备注（转账为转出 / 转入 / 手续费）。
  ///
  /// 全部走统一样式的 [XpParamRow]，值折叠展示，点击展开二级选择面板。
  Widget _buildSettingsSection(ColorScheme scheme) {
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final isTransfer = _type == BillType.transfer;
    final accountCurrency = _accountCurrencyOf(_accountId);

    final rows = <Widget>[];
    void add(Widget row) {
      if (rows.isNotEmpty) {
        rows.add(
          const XpParamDivider(indent: kXpParamDividerIndentWithLeading),
        );
      }
      rows.add(row);
    }

    if (isTransfer) {
      add(
        XpParamRow(
          leadingIcon: Icons.south_west,
          label: '转出账户',
          value: _accountOf(_accountId)?.name ?? '未选择',
          onTap: () => _pickAccount(income: false),
        ),
      );
      add(
        XpParamRow(
          leadingIcon: Icons.north_east,
          label: '转入账户',
          value: _accountOf(_incomeAccountId)?.name ?? '未选择',
          onTap: () => _pickAccount(income: true),
        ),
      );
      add(
        XpParamRow(
          leadingIcon: Icons.percent,
          label: '手续费',
          subtitle: '到账金额 = 转出金额 − 手续费',
          showChevron: false,
          valueWidget: _inlineField(
            controller: _feeController,
            hint: '0.00',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      );
    } else {
      add(
        XpParamRow(
          leadingIcon: Icons.account_balance_wallet_outlined,
          label: '账户',
          value: _accountOf(_accountId)?.name ?? '未选择',
          onTap: () => _pickAccount(income: false),
        ),
      );
    }

    add(
      XpParamRow(
        leadingIcon: Icons.currency_exchange,
        label: '记账币种',
        subtitle: _currencyCode == null ? '跟随账户币种' : '账户币种 $accountCurrency',
        value:
            '${XpCurrencyMetaConfig.flagOf(_effectiveCurrency)} '
            '$_effectiveCurrency',
        onTap: _pickCurrency,
      ),
    );

    if (tags.isNotEmpty) {
      add(
        XpParamRow(
          leadingIcon: Icons.label_outline,
          label: '标签',
          value: _tagSummary(tags),
          onTap: _pickTags,
        ),
      );
    }

    add(
      XpParamRow(
        leadingIcon: Icons.event_outlined,
        label: '日期',
        value: DateFormat('M月d日').format(_date),
        onTap: _pickDate,
      ),
    );

    add(
      XpParamRow(
        leadingIcon: Icons.edit_note,
        label: '备注',
        showChevron: false,
        valueWidget: _inlineField(controller: _commentController, hint: '可选'),
      ),
    );

    if (!isTransfer) {
      add(
        XpParamRow(
          leadingIcon: Icons.visibility_off_outlined,
          label: '不计入收支',
          subtitle: '仅记录流水与余额，不计入统计',
          showChevron: false,
          onTap: () => setState(() => _excludeFromStats = !_excludeFromStats),
          valueWidget: Switch(
            value: _excludeFromStats,
            onChanged: (v) => setState(() => _excludeFromStats = v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            0,
            XpSpacing.l,
            XpSpacing.s,
          ),
          child: Text(
            '明细信息',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
          child: XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            ),
          ),
        ),
      ],
    );
  }

  /// 已选标签摘要（未选择时给出占位文案）。
  String _tagSummary(List<Tag> tags) {
    if (_tagIds.isEmpty) return '未选择';
    final names = tags
        .where((t) => _tagIds.contains(t.id))
        .map((t) => t.name)
        .toList();
    return names.isEmpty ? '未选择' : names.join('、');
  }

  /// 参数行内嵌输入框（右对齐、无边框），如备注 / 手续费。
  Widget _inlineField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: _inlineFieldWidth,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.right,
        style: textTheme.bodyLarge,
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard(ColorScheme scheme) {
    // 大号金额输入:Display 32 + tabular 等宽数字,输入时不跳动
    final amountStyle = Theme.of(
      context,
    ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700);
    final accCur = _accountCurrencyOf(_accountId);
    final billCur = _effectiveCurrency;
    // 金额显示区局部刷新：按键只重建这里（P7）
    return Padding(
      // 左右保持 12；底部留白 = 8 + [_keyboardBottomSpace]，键盘整体
      // 上顶约 20dp（内容不变）。
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.m,
        XpSpacing.s,
        XpSpacing.m,
        XpSpacing.s + _keyboardBottomSpace,
      ),
      child: Column(
        children: [
          ValueListenableBuilder<String>(
            valueListenable: _amountText,
            builder: (context, text, _) {
              final input = parseYuanInput(text);
              final converted = billCur != accCur && input != null
                  ? convertAmount(
                      input,
                      billCur,
                      accCur,
                      ref.read(currencyServiceProvider),
                    )
                  : null;
              return Column(
                children: [
                  SizedBox(
                    height: _amountRowHeight,
                    child: Row(
                      children: [
                        Text(
                          billCur == 'CNY' ? '¥' : billCur,
                          style: amountStyle?.copyWith(color: scheme.primary),
                        ),
                        const SizedBox(width: XpSpacing.s),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: SingleChildScrollView(
                              reverse: true,
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                text.isEmpty ? '0' : text,
                                style: amountStyle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    // 换算行收窄（16→8），把空间让给数字键。
                    height: XpSpacing.s,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        converted == null
                            ? ''
                            : '≈ $accCur ${formatYuan(converted)}',
                        maxLines: 1,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: XpSpacing.s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (final row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                      ['.', '0', '00'],
                    ])
                      Row(
                        children: [
                          for (final key in row)
                            Expanded(
                              child: _KeyButton(
                                label: key,
                                onTap: () => _append(key),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    _KeyButton(label: '⌫', onTap: _backspace),
                    _KeyButton(label: 'C', onTap: _clear),
                    SizedBox(
                      height: 2 * _keyHeight,
                      child: Padding(
                        padding: const EdgeInsets.all(XpSpacing.xs),
                        child: FilledButton(
                          onPressed: _save,
                          child: Text(_isEdit ? '更新' : '保存'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 数字键盘按键
class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _keyHeight,
      child: Padding(
        // 竖向内边距收窄（4→2），把高度让给键面本身，数字键更好点按。
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.xs,
          vertical: 2,
        ),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: XpTextStyles.h3.tabular,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// 一级分类单元格
class _CategoryCell extends StatelessWidget {
  const _CategoryCell({
    required this.category,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CategoryCellView(
      iconName: category.icon,
      label: category.name,
      selected: selected,
      accent: accent,
      onTap: onTap,
    );
  }
}

/// 二级分类展开区单元格（「全部」用 Material 图标，子分类用图标包）。
class _SubCategoryCell extends StatelessWidget {
  const _SubCategoryCell({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.iconName,
    this.icon,
  });

  final String? iconName;
  final IconData? icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _CategoryCellView(
      iconName: iconName,
      iconData: icon,
      label: label,
      selected: selected,
      accent: accent,
      onTap: onTap,
    );
  }
}

/// 分类单元格公共视图：圆形图标 + 名称，选中态主题色描边。
class _CategoryCellView extends StatelessWidget {
  const _CategoryCellView({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.iconName,
    this.iconData,
  });

  final String? iconName;
  final IconData? iconData;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? accent
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(XpRadius.c),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(XpSpacing.s),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.18) : null,
              shape: BoxShape.circle,
              // 选中态:主题色描边强化,与主题色图标呼应
              border: selected
                  ? Border.all(color: accent, width: _cellBorderWidth)
                  : null,
            ),
            child: iconName != null
                ? AppIcon(name: iconName!, size: 24, color: color)
                : AppIcon(icon: iconData!, size: 24, color: color),
          ),
          const SizedBox(height: XpSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: XpTextStyles.caption.copyWith(
              color: selected ? accent : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
