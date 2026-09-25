import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../tokens/design_tokens.dart';
import 'app_icon.dart';
import 'xp_button.dart';
import 'xp_sheet.dart';
import 'xp_snack.dart';

/// 手动添加历史快照弹窗（模块 2.4「历史快照」）：输入时间点 + 余额 + 备注，
/// 记录该时点的余额供趋势图回溯。**不改变当前余额**。
class HistoricalSnapshotSheet extends ConsumerStatefulWidget {
  const HistoricalSnapshotSheet({super.key, required this.account});

  final Account account;

  static Future<void> show(BuildContext context, Account account) {
    return showXpSheet(
      context: context,
      heightFactor: 0.7,
      builder: (_) => HistoricalSnapshotSheet(account: account),
    );
  }

  @override
  ConsumerState<HistoricalSnapshotSheet> createState() =>
      _HistoricalSnapshotSheetState();
}

class _HistoricalSnapshotSheetState
    extends ConsumerState<HistoricalSnapshotSheet> {
  final _balanceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _time = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _balanceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showXpDatePicker(
      context: context,
      initialDate: _time,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
    );
    if (time == null || !mounted) return;
    setState(() {
      _time = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final balance = parseYuanInput(_balanceCtrl.text);
    if (balance == null) {
      _toast('请输入有效金额');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(accountServiceProvider)
          .addHistoricalSnapshot(
            accountId: widget.account.id,
            balance: balance,
            timestamp: _time.millisecondsSinceEpoch,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final m = _time.month.toString().padLeft(2, '0');
    final d = _time.day.toString().padLeft(2, '0');
    final hh = _time.hour.toString().padLeft(2, '0');
    final mm = _time.minute.toString().padLeft(2, '0');

    return Padding(
      padding: EdgeInsets.only(
        left: XpSpacing.l,
        right: XpSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '添加历史快照 · ${widget.account.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: XpSpacing.xs),
          Text(
            '记录某个时间点的账户余额，用于趋势回溯；不会改变当前余额。',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          XpButton(
            onPressed: _pickTime,
            leading: const AppIcon(icon: Icons.event, size: 18),
            child: Text('$_time.year-$m-$d $hh:$mm'),
          ),
          const SizedBox(height: XpSpacing.m),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600)
                .tabular,
            decoration: const InputDecoration(
              labelText: '该时点余额',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: XpSpacing.l),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '保存'),
          ),
        ],
      ),
    );
  }
}
