import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../tokens/design_tokens.dart';
import 'xp_snack.dart';

/// 手动调账弹窗（算法二）：输入目标余额 → 产生调账账单 + MANUAL 快照。
class AdjustSheet extends ConsumerStatefulWidget {
  const AdjustSheet({super.key, required this.account});

  final Account account;

  static Future<void> show(BuildContext context, Account account) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AdjustSheet(account: account),
    );
  }

  @override
  ConsumerState<AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends ConsumerState<AdjustSheet> {
  final _balanceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int? get _newBalance => parseYuanInput(_balanceCtrl.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final diff = _newBalance == null
        ? null
        : _newBalance! - widget.account.currentBalance;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '调账 · ${widget.account.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '当前余额 ${formatYuan(widget.account.currentBalance)}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)
                .tabular,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _balanceCtrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: '目标余额',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)
                .tabular,
            onChanged: (_) => setState(() {}),
          ),
          if (diff != null && diff != 0) ...[
            const SizedBox(height: 8),
            Text(
              '调整差额：${diff > 0 ? '+' : '-'}${formatYuan(diff.abs())}（将生成一笔调账账单）',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(
                    color: diff > 0
                        ? XpSemanticColors.income
                        : XpSemanticColors.expense,
                    fontWeight: FontWeight.w600,
                  )
                  .tabular,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '确认调账'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final target = _newBalance;
    if (target == null) {
      _toast('请输入有效金额');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(accountServiceProvider)
          .setBalance(widget.account.id, target, note: _noteCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _toast('调账失败：$e');
      }
    }
  }

  void _toast(String msg) {
    showXpSnack(context, msg);
  }
}
