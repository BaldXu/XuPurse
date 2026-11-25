import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/amount.dart';
import '../../data/database/app_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/xp_button.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_snack.dart';

/// 时间范围筛选档位。
enum _PickerRange {
  m1('近1月', 30),
  m3('近3月', 90),
  y1('近1年', 365),
  all('全部', 0);

  const _PickerRange(this.label, this.days);

  final String label;
  final int days;
}

/// 从已有账单里挑选明细加入清单（多选，已添加的不再列出）。
class BillListPickerPage extends ConsumerStatefulWidget {
  const BillListPickerPage({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<BillListPickerPage> createState() =>
      _BillListPickerPageState();
}

class _BillListPickerPageState extends ConsumerState<BillListPickerPage>
    with XpPageScaffold<BillListPickerPage> {
  _PickerRange _range = _PickerRange.m3;
  final Set<String> _selected = {};
  Set<String> _existing = {};
  bool _adding = false;

  /// 账单流只建一次，避免每次 build 重新订阅。
  late final Stream<List<Bill>> _billsStream;

  @override
  void initState() {
    super.initState();
    _billsStream = ref.read(billRepoProvider).watchAll();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final ids = await ref
        .read(billListRepoProvider)
        .billIdsOf(widget.listId);
    if (!mounted) return;
    setState(() => _existing = ids);
  }

  bool _inRange(Bill b, int cutoff) =>
      b.type != 'transfer' &&
      !_existing.contains(b.id) &&
      b.time >= cutoff;

  int _cutoffOf(_PickerRange r) {
    if (r.days == 0) return 0;
    return DateTime.now()
        .subtract(Duration(days: r.days))
        .millisecondsSinceEpoch;
  }

  Future<void> _confirm(List<Bill> visible) async {
    if (_selected.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      await ref
          .read(billListRepoProvider)
          .addBills(widget.listId, _selected);
      if (!mounted) return;
      showXpSnack(context, '已添加 ${_selected.length} 笔');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      showXpSnack(context, '添加失败：$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final billsAsync = _billsStream;
    final categories = ref.watch(categoriesProvider).valueOrNull ??
        const <Category>[];
    final catName = {for (final c in categories) c.id: c.name};
    final cutoff = _cutoffOf(_range);

    return buildXpScaffold(
      appBar: AppBar(title: const Text('添加已有明细')),
      body: StreamBuilder<List<Bill>>(
        stream: billsAsync,
        builder: (context, snap) {
          final all = snap.data ?? const <Bill>[];
          final visible = [
            for (final b in all)
              if (_inRange(b, cutoff)) b,
          ].reversed.toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  XpSpacing.l,
                  XpSpacing.s,
                  XpSpacing.l,
                  XpSpacing.s,
                ),
                child: Row(
                  children: [
                    for (final r in _PickerRange.values)
                      Padding(
                        padding: const EdgeInsets.only(right: XpSpacing.s),
                        child: ChoiceChip(
                          label: Text(r.label),
                          selected: _range == r,
                          onSelected: (_) => setState(() => _range = r),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: visible.isEmpty
                          ? null
                          : () => setState(() {
                              final ids = {for (final b in visible) b.id};
                              if (_selected.containsAll(ids)) {
                                _selected.removeAll(ids);
                              } else {
                                _selected.addAll(ids);
                              }
                            }),
                      child: const Text('全选'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const XpEmptyState(
                        icon: Icons.inbox_outlined,
                        title: '这个范围没有可添加的账单',
                        message: '换个时间范围试试，或直接在清单里记一笔。',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: XpSpacing.s),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final b = visible[i];
                          final selected = _selected.contains(b.id);
                          final isExpense = b.type == 'expense';
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (_) => setState(() {
                              if (selected) {
                                _selected.remove(b.id);
                              } else {
                                _selected.add(b.id);
                              }
                            }),
                            title: Text(
                              _titleOf(b, catName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_dateOf(b.time)),
                            secondary: Text(
                              '${isExpense ? '-' : '+'}¥${formatYuan(b.amount)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isExpense
                                    ? scheme.error
                                    : XpSemanticColors.income,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    XpSpacing.l,
                    XpSpacing.s,
                    XpSpacing.l,
                    XpSpacing.m,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: XpButton(
                    onPressed: _selected.isEmpty || _adding
                        ? null
                        : () => _confirm(visible),
                    expand: true,
                    child: Text(
                      _adding
                          ? '添加中…'
                          : '添加 ${_selected.length} 笔',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _titleOf(Bill b, Map<String, String> catName) {
  final name = catName[b.categoryId] ?? '未分类';
  final note = b.comment?.trim();
  if (note == null || note.isEmpty) return name;
  return '$name · $note';
}

String _dateOf(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  return '${d.year}/${d.month}/${d.day} $hh:$mi';
}
