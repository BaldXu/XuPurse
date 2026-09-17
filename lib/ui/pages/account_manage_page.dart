import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/icons.dart';
import '../../domain/services/currency_service.dart';
import '../../state/providers.dart';

/// 账户管理页：多选账户 → 合并（可重命名主账户）/ 批量改币种。
class AccountManagePage extends ConsumerStatefulWidget {
  const AccountManagePage({super.key});

  @override
  ConsumerState<AccountManagePage> createState() => _AccountManagePageState();
}

class _AccountManagePageState extends ConsumerState<AccountManagePage> {
  final Set<String> _selected = {};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('账户管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '勾选账户后可「合并」或「批量改币种」。合并时保留其中一个账户，'
              '其余账户的账单/快照等全部转入保留账户。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: accountsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(child: Text('还没有账户'));
                }
                return ListView.builder(
                  itemCount: accounts.length,
                  itemBuilder: (context, i) {
                    final a = accounts[i];
                    final checked = _selected.contains(a.id);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: _busy
                          ? null
                          : (v) => setState(() {
                              if (v == true) {
                                _selected.add(a.id);
                              } else {
                                _selected.remove(a.id);
                              }
                            }),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(a.name),
                      subtitle: Text(
                        '${formatYuan(a.currentBalance)} · ${a.currency}'
                        '${a.remark != null && a.remark!.isNotEmpty ? ' · ${a.remark}' : ''}',
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: hexToColor(
                          a.color,
                        ).withValues(alpha: 0.15),
                        foregroundColor: hexToColor(a.color),
                        child: Icon(resolveIcon(a.icon), size: 20),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selected.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy || _selected.length < 2
                            ? null
                            : _merge,
                        icon: const Icon(Icons.merge_type),
                        label: Text('合并（${_selected.length}）'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _changeCurrency,
                        icon: const Icon(Icons.currency_exchange),
                        label: const Text('改币种'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------- 合并 ----------

  Future<void> _merge() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
    final selected = accounts.where((a) => _selected.contains(a.id)).toList();
    if (selected.length < 2) return;

    String? targetId = selected.first.id;
    final nameCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('合并账户'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择保留的账户（其余账户将并入它）：'),
                const SizedBox(height: 8),
                RadioGroup<String>(
                  groupValue: targetId,
                  onChanged: (v) => setDialogState(() => targetId = v),
                  child: Column(
                    children: [
                      for (final a in selected)
                        RadioListTile<String>(
                          value: a.id,
                          title: Text(a.name),
                          dense: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '合并后名称（可选，留空保留原名）',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '合并后余额以保留账户为准；被合并账户的账单、快照等将全部转移。',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('合并'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final sourceIds = _selected.where((id) => id != targetId).toList();
      await ref
          .read(accountServiceProvider)
          .mergeAccounts(
            targetId: targetId!,
            sourceIds: sourceIds,
            newName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selected.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('账户合并完成')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('合并失败：$e')));
    }
  }

  // ---------- 批量改币种 ----------

  Future<void> _changeCurrency() async {
    final codes = CurrencyService.supportedCodes;
    var code = 'CNY';
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('批量修改币种'),
          content: DropdownButtonFormField<String>(
            initialValue: code,
            decoration: const InputDecoration(
              labelText: '币种',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final c in codes) DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setDialogState(() => code = v ?? code),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, code),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == null || !mounted) return;
    final count = _selected.length;
    setState(() => _busy = true);
    try {
      await ref
          .read(accountServiceProvider)
          .setCurrencies(_selected.toList(), confirmed);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _selected.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已将 $count 个账户改为 $confirmed')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('修改失败：$e')));
    }
  }
}
