import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/account_name.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/currency_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';

/// 账户管理页：多选账户 → 合并（可重命名主账户）/ 批量改币种。
class AccountManagePage extends ConsumerStatefulWidget {
  const AccountManagePage({super.key});

  @override
  ConsumerState<AccountManagePage> createState() => _AccountManagePageState();
}

class _AccountManagePageState extends ConsumerState<AccountManagePage>
    with XpPageScaffold<AccountManagePage> {
  final Set<String> _selected = {};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    return buildXpScaffold(
      appBar: AppBar(title: const Text('账户管理')),
      // 整页骨架:账户流未就绪时以骨架呈现
      loading: accountsAsync.isLoading,
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
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Center(child: Text('加载失败：$e')),
              data: (accounts) {
                if (accounts.isEmpty) {
                  return const Center(child: Text('还没有账户'));
                }
                // 名称匹配度高的账户排前面（疑似重复优先），方便观察与合并。
                final sorted = _sortedBySimilarity(accounts);
                final suspicious = <String, bool>{
                  for (final a in sorted) a.id: _maxSimilarity(sorted, a) > 0.4,
                };
                // 总余额小计（展示用,不做币种折算）
                final totalBalance = accounts.fold<int>(
                  0,
                  (s, a) => s + a.currentBalance,
                );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    // 总余额小计行
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '共 ${accounts.length} 个账户',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const Spacer(),
                          Text(
                            '余额合计 ¥${formatYuan(totalBalance)}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w600)
                                .tabular,
                          ),
                        ],
                      ),
                    ),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          for (var i = 0; i < sorted.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 56,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            _AccountCheckRow(
                              account: sorted[i],
                              checked: _selected.contains(sorted[i].id),
                              suspicious: suspicious[sorted[i].id] == true,
                              busy: _busy,
                              onToggle: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(sorted[i].id);
                                } else {
                                  _selected.remove(sorted[i].id);
                                }
                              }),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
                        icon: const AppIcon(icon: Icons.currency_exchange),
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

  /// 合并弹窗：默认选中「最后活跃时间」最新的账户为保留方（按数据时间戳判断
  /// 最新状态，而非让用户盲选）；展示各账户最后活跃时间；两方余额均非 0 且
  /// 活跃时间接近时二次确认，防止误合并两个真实账户。
  Future<void> _merge() async {
    final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
    final selected = accounts.where((a) => _selected.contains(a.id)).toList();
    if (selected.length < 2) return;

    final service = ref.read(accountServiceProvider);
    final lastActive = await service.lastActiveTimes(selected.map((a) => a.id));
    if (!mounted) return;
    // 默认保留最后活跃时间最新的一方（平手时保留原顺序第一个）
    String? targetId = selected.first.id;
    var best = lastActive[targetId] ?? 0;
    for (final a in selected) {
      final t = lastActive[a.id] ?? 0;
      if (t > best) {
        best = t;
        targetId = a.id;
      }
    }
    final nameCtrl = TextEditingController();

    final confirmed = await showXpDialog<bool>(
      context: context,
      title: '合并账户',
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) => SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('选择保留的账户（其余账户将并入它；默认选中最后活跃最新的账户）：'),
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
                        subtitle: Text(
                          '${formatYuan(a.currentBalance)} · 最后活跃 '
                          '${_fmtActive(lastActive[a.id])}',
                        ),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('合并'),
        ),
      ],
    );
    nameCtrl.dispose();

    if (confirmed != true || !mounted) return;
    // 二次确认：保留方与任一被合并方余额均非 0 且最后活跃时间接近（30 天内），
    // 很可能是两个真实账户而非同一账户的重复数据。
    final target = selected.firstWhere((a) => a.id == targetId);
    const closeWindow = 30 * 24 * 60 * 60 * 1000; // 30 天
    final risky = selected.any(
      (a) =>
          a.id != targetId &&
          a.currentBalance != 0 &&
          target.currentBalance != 0 &&
          ((lastActive[a.id] ?? 0) - (lastActive[targetId] ?? 0)).abs() <=
              closeWindow,
    );
    if (risky) {
      final ok = await confirmXpDialog(
        context,
        title: '确认合并？',
        content:
            '保留账户与被合并账户的余额均非 0，且最后活跃时间接近（30 天内），'
            '它们可能是两个真实账户而非同一账户的重复数据。确定仍要合并吗？',
        confirmLabel: '仍要合并',
        danger: true,
      );
      if (!ok || !mounted) return;
    }

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
      showXpSnack(context, '账户合并完成');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showXpSnack(context, '合并失败：$e', error: true);
    }
  }

  static String _fmtActive(int? ms) {
    if (ms == null || ms <= 0) return '未知';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (dt.year == now.year) {
      return '${dt.month}月${dt.day}日';
    }
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  // ---------- 排序：名称匹配度高的账户优先 ----------

  /// 按「与其他账户的最大名称相似度」降序排序，疑似重复的账户排前面。
  List<Account> _sortedBySimilarity(List<Account> accounts) {
    if (accounts.length < 2) return accounts;
    final sorted = [...accounts];
    sorted.sort((x, y) {
      final sx = _maxSimilarity(sorted, x);
      final sy = _maxSimilarity(sorted, y);
      if (sx != sy) return sy.compareTo(sx);
      return x.name.compareTo(y.name);
    });
    return sorted;
  }

  /// 账户 a 与列表中其他账户的最大名称相似度（0.0 ~ 1.0）。
  double _maxSimilarity(List<Account> accounts, Account a) {
    var best = 0.0;
    for (final b in accounts) {
      if (b.id == a.id) continue;
      final s = accountNameSimilarity(a.name, b.name);
      if (s > best) best = s;
    }
    return best;
  }

  // ---------- 批量改币种 ----------

  Future<void> _changeCurrency() async {
    final codes = CurrencyService.supportedCodes;
    var code = 'CNY';
    final confirmed = await showXpDialog<String>(
      context: context,
      title: '批量修改币种',
      contentWidget: StatefulBuilder(
        builder: (ctx, setDialogState) => DropdownButtonFormField<String>(
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, code),
          child: const Text('确定'),
        ),
      ],
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
      showXpSnack(context, '已将 $count 个账户改为 $confirmed');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showXpSnack(context, '修改失败：$e', error: true);
    }
  }
}

/// 账户勾选行：复选框 + 头像 + 名称/副标题。
class _AccountCheckRow extends StatelessWidget {
  const _AccountCheckRow({
    required this.account,
    required this.checked,
    required this.suspicious,
    required this.busy,
    required this.onToggle,
  });

  final Account account;
  final bool checked;
  final bool suspicious;
  final bool busy;
  final ValueChanged<bool?> onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: checked,
      onChanged: busy ? null : onToggle,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(account.name),
      subtitle: Text(
        '${formatYuan(account.currentBalance)} · ${account.currency}'
        '${suspicious ? ' · 疑似重复' : ''}'
        '${account.remark != null && account.remark!.isNotEmpty ? ' · ${account.remark}' : ''}',
      ),
      secondary: CircleAvatar(
        backgroundColor: hexToColor(account.color).withValues(alpha: 0.15),
        foregroundColor: hexToColor(account.color),
        child: AppIcon(name: account.icon, size: 20),
      ),
    );
  }
}
