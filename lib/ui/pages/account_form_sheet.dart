import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/icons.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../widgets/xp_snack.dart';

/// 账户表单（新建 / 编辑）。
class AccountFormSheet extends ConsumerStatefulWidget {
  const AccountFormSheet({super.key, this.account});

  final Account? account;

  static Future<void> show(BuildContext context, {Account? account}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(account: account),
    );
  }

  @override
  ConsumerState<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<AccountFormSheet> {
  late AccountCategory _category;
  late AccountType _type;
  late bool _includeInAssets;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _initialCtrl;
  late final TextEditingController _remarkCtrl;
  String? _icon;
  bool _saving = false;

  bool get _isEdit => widget.account != null;

  /// 图标候选（账户常用子集）
  static const _iconChoices = [
    'account_balance_wallet',
    'payments',
    'savings',
    'account_balance',
    'credit_card',
    'monetization_on',
    'smartphone',
    'store',
  ];

  static const _categoryLabels = {
    AccountCategory.fund: '资金',
    AccountCategory.record: '记录',
    AccountCategory.debt: '债务',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    _category = a == null
        ? AccountCategory.fund
        : AccountCategory.values.byName(a.category);
    _type = a == null ? AccountType.bank : AccountType.values.byName(a.type);
    _includeInAssets = a?.includeInAssets ?? true;
    _nameCtrl = TextEditingController(text: a?.name ?? '');
    _initialCtrl = TextEditingController(
      text: a == null ? '' : formatYuan(a.initialBalance),
    );
    _remarkCtrl = TextEditingController(text: a?.remark ?? '');
    _icon = a?.icon;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _initialCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isEdit ? '编辑账户' : '新建账户', style: textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              autofocus: !_isEdit,
              decoration: const InputDecoration(
                labelText: '账户名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AccountCategory>(
              segments: AccountCategory.values
                  .map(
                    (c) => ButtonSegment(
                      value: c,
                      label: Text(_categoryLabels[c]!),
                    ),
                  )
                  .toList(),
              selected: {_category},
              onSelectionChanged: (s) => setState(() => _category = s.first),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: AccountType.values
                  .map(
                    (t) => ChoiceChip(
                      label: Text(t.name),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            // 图标选择
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _iconChoices
                    .map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Icon(
                            resolveIcon(key),
                            size: 20,
                            color: _icon == key
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                          selected: _icon == key,
                          onSelected: (_) => setState(() => _icon = key),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _initialCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: '初始余额（可选）',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            // fund 账户恒计入总资产（口径对齐 cent-xyx），开关仅对 debt/record 有意义
            if (_category != AccountCategory.fund) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('计入总资产'),
                value: _includeInAssets,
                onChanged: (v) => setState(() => _includeInAssets = v),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '保存中…' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('请输入账户名称');
      return;
    }
    final service = ref.read(accountServiceProvider);
    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await service.updateAccount(
          widget.account!.id,
          AccountsCompanion(
            name: Value(name),
            category: Value(_category.name),
            type: Value(_type.name),
            icon: Value(_icon),
            includeInAssets: Value(
              _category == AccountCategory.fund ? true : _includeInAssets,
            ),
            remark: Value(
              _remarkCtrl.text.trim().isEmpty ? null : _remarkCtrl.text.trim(),
            ),
          ),
        );
      } else {
        final initial = parseYuanInput(_initialCtrl.text) ?? 0;
        await service.createAccount(
          name: name,
          category: _category,
          type: _type,
          icon: _icon,
          initialBalance: initial,
          includeInAssets: _category == AccountCategory.fund
              ? true
              : _includeInAssets,
          remark: _remarkCtrl.text.trim().isEmpty
              ? null
              : _remarkCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('保存失败：$e');
      }
    }
  }

  void _toast(String msg) {
    showXpSnack(context, msg);
  }
}
