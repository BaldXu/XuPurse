import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/bill_extra.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/currency_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/xp_snack.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_skeleton.dart';
import '../widgets/app_icon.dart';
import '../widgets/bill_tile.dart' show kExpenseColor, kIncomeColor;
import '../tokens/design_tokens.dart';

/// 记账弹窗：支出 / 收入 / 转账 + 数字键盘 + 二级分类 + 账户选择。
///
/// [initialBill] 非空时为编辑模式（保存走 updateBill）。
class BookkeepingSheet extends ConsumerStatefulWidget {
  const BookkeepingSheet({super.key, this.initialBill});

  final Bill? initialBill;

  static Future<void> show(BuildContext context, {Bill? bill}) {
    return showXpSheet(
      context: context,
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
    // 默认分类兜底：分类流就绪时补选（原逻辑写在 build 内，已移出）
    ref.listenManual(
      categoriesProvider,
      (_, __) => _ensureDefaultCategory(),
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

  /// 编辑模式：回填账单标签（避免保存时清空原标签）。
  Future<void> _loadTags() async {
    final bill = widget.initialBill;
    if (bill == null) return;
    final ids = await ref.read(billRepoProvider).tagIdsOf(bill.id);
    if (mounted) setState(() => _tagIds.addAll(ids));
  }

  /// 当前账户币种（无账户或未命中按 CNY 兜底）。
  String _accountCurrencyOf(String? id) {
    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    for (final a in accounts) {
      if (a.id == id) return a.currency;
    }
    return 'CNY';
  }

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
          next = '$cur'
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabs(scheme),
          const Divider(height: 1),
          // 分类/转账主体 + 明细设置都在滚动区内，键盘固定底部，
          // 内容多时可滑动，避免挤压显得局促。
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: XpSpacing.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_type == BillType.transfer)
                    _buildTransferBody(scheme)
                  else
                    _buildCategoryBody(),
                  const Divider(height: 1),
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

  Widget _buildTabs(ColorScheme scheme) {
    return SegmentedButton<BillType>(
      segments: const [
        ButtonSegment(
          value: BillType.expense,
          label: Text('支出'),
          icon: AppIcon(icon: Icons.south_west),
        ),
        ButtonSegment(
          value: BillType.income,
          label: Text('收入'),
          icon: AppIcon(icon: Icons.north_east),
        ),
        ButtonSegment(
          value: BillType.transfer,
          label: Text('转账'),
          icon: AppIcon(icon: Icons.swap_horiz),
        ),
      ],
      selected: {_type},
      onSelectionChanged: (s) => setState(() {
        _type = s.first;
        _parentId = null;
        _subId = null;
        _ensureDefaultCategory();
      }),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: XpSpacing.m,
        vertical: XpSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: parents.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final c = parents[i];
              final selected = _parentId == c.id;
              return _CategoryCell(
                category: c,
                selected: selected,
                accent: accent,
                onTap: () => setState(() {
                  _parentId = c.id;
                  final subs = childrenOf[c.id] ?? const [];
                  _subId = subs.isEmpty ? c.id : null;
                }),
              );
            },
          ),
          if (childrenOf[_parentId]?.isNotEmpty == true)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: XpSpacing.s),
                    child: ChoiceChip(
                      label: const Text('全部'),
                      selected: _subId == _parentId,
                      onSelected: (_) => setState(() => _subId = _parentId),
                    ),
                  ),
                  for (final sub in childrenOf[_parentId]!)
                    Padding(
                      padding: const EdgeInsets.only(right: XpSpacing.s),
                      child: ChoiceChip(
                        label: Text(sub.name),
                        selected: _subId == sub.id,
                        onSelected: (_) => setState(() => _subId = sub.id),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 转账主体：转出/转入账户选择 + 手续费
  Widget _buildTransferBody(ColorScheme scheme) {
    final accountsAsync = ref.watch(accountsProvider);
    if (accountsAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(XpSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }
    final accounts = accountsAsync.value ?? const <Account>[];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: XpSpacing.l,
        vertical: XpSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AccountPicker(
            label: '转出账户',
            accounts: accounts,
            selectedId: _accountId,
            onChanged: (id) => setState(() => _accountId = id),
          ),
          const SizedBox(height: XpSpacing.s),
          const Center(child: Icon(Icons.south)),
          const SizedBox(height: XpSpacing.s),
          _AccountPicker(
            label: '转入账户',
            accounts: accounts,
            selectedId: _incomeAccountId,
            onChanged: (id) => setState(() => _incomeAccountId = id),
          ),
          const SizedBox(height: XpSpacing.s),
          TextField(
            controller: _feeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: '手续费（元，可选；到账金额 = 转出金额 - 手续费）',
              prefixIcon: Icon(Icons.percent),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 明细设置区：账户 + 币种 + 标签 + 备注 + 日期 + 不计入收支。
  Widget _buildSettingsSection(ColorScheme scheme) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_type != BillType.transfer) ...[
            _AccountPicker(
              label: '账户',
              accounts: accounts,
              selectedId: _accountId,
              onChanged: (id) => setState(() {
                _accountId = id;
                // 切换账户后回到跟随账户币种
                if (_type != BillType.transfer) _currencyCode = null;
              }),
            ),
            const SizedBox(height: 10),
          ],
          _buildCurrencyRow(),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildTagRow(tags),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: '备注（可选）',
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const AppIcon(icon: Icons.today, size: 18),
                label: Text(DateFormat('M月d日').format(_date)),
              ),
            ],
          ),
          if (_type != BillType.transfer) ...[
            const SizedBox(height: XpSpacing.xs),
            _buildExcludeToggle(scheme),
          ],
        ],
      ),
    );
  }

  /// 「不计入收支」开关：仅记流水与余额，不参与收入/支出统计。
  Widget _buildExcludeToggle(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: XpSpacing.xs),
      child: Row(
        children: [
          AppIcon(
            icon: Icons.visibility_off_outlined,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('不计入收支', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '仅记录流水与余额，不计入收支统计',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _excludeFromStats,
            onChanged: (v) => setState(() => _excludeFromStats = v),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  /// 记账币种选择（null = 跟随账户币种）。
  Widget _buildCurrencyRow() {
    final accCur = _accountCurrencyOf(_accountId);
    final selected = _effectiveCurrency;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '记账币种（账户 $accCur${selected == accCur ? '' : ' · 当前 $selected'}）',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: XpSpacing.xs),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final code in CurrencyService.supportedCodes)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(code),
                    selected: selected == code,
                    onSelected: (_) => setState(() {
                      _currencyCode = code == accCur ? null : code;
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 标签行（含 preferCurrency 的标签选中后自动切换记账币种）。
  Widget _buildTagRow(List<Tag> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: XpSpacing.xs),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final tag in tags)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      tag.name,
                      style: tag.preferCurrency != null
                          ? TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            )
                          : null,
                    ),
                    selected: _tagIds.contains(tag.id),
                    onSelected: (v) => setState(() {
                      if (v) {
                        _tagIds.add(tag.id);
                        if (tag.preferCurrency != null &&
                            tag.preferCurrency!.isNotEmpty) {
                          _currencyCode = tag.preferCurrency!;
                        }
                      } else {
                        _tagIds.remove(tag.id);
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildKeyboard(ColorScheme scheme) {
    // 大号金额输入:Display 32 + tabular 等宽数字,输入时不跳动
    final amountStyle = Theme.of(
      context,
    ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w700);
    final accCur = _accountCurrencyOf(_accountId);
    final billCur = _effectiveCurrency;
    // 金额显示区局部刷新：按键只重建这里（P7）
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.m,
        0,
        XpSpacing.m,
        XpSpacing.m,
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
                    height: 48,
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
                    height: 18,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        converted == null
                            ? ''
                            : '≈ $accCur ${formatYuan(converted)}',
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
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    for (final row in [
                      ['7', '8', '9'],
                      ['4', '5', '6'],
                      ['1', '2', '3'],
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

const double _keyHeight = 48;

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
        padding: const EdgeInsets.all(XpSpacing.xs),
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// 分类单元格
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
    final color = selected
        ? accent
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(XpSpacing.s),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.18) : null,
              shape: BoxShape.circle,
              // 选中态:主题色描边强化,与主题色图标呼应
              border: selected ? Border.all(color: accent, width: 1.5) : null,
            ),
            child: AppIcon(name: category.icon, size: 24, color: color),
          ),
          const SizedBox(height: XpSpacing.xs),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: selected ? accent : null,
              fontWeight: selected ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// 账户选择（横滑 chips）
class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.label,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
  });

  final String label;
  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: XpSpacing.xs),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final acc in accounts)
                Padding(
                  padding: const EdgeInsets.only(right: XpSpacing.s),
                  child: ChoiceChip(
                    avatar: AppIcon(
                      name: acc.icon,
                      size: 16,
                      color: hexToColor(acc.color),
                    ),
                    label: Text(acc.name),
                    selected: selectedId == acc.id,
                    onSelected: (_) => onChanged(acc.id),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
