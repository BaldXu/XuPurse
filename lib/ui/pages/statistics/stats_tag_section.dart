import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/amount.dart';
import '../../../data/database/app_database.dart';
import '../../../state/providers.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_skeleton.dart';
import 'stats_shared.dart';

/// 标签分区：标签支出 Top 横向条形。
class StatsTagSection extends ConsumerStatefulWidget {
  const StatsTagSection({
    super.key,
    required this.start,
    required this.end,
    this.onReady,
  });

  final int start;
  final int end;

  /// 数据加载完成（成功或失败）后的回调；统计页用它切换分区可见性。
  final VoidCallback? onReady;

  @override
  ConsumerState<StatsTagSection> createState() => _TagSectionState();
}

class _TagData {
  const _TagData({required this.sum, required this.tags});

  final List<({String tagId, int amount})> sum;
  final List<Tag> tags;
}

class _TagSectionState extends ConsumerState<StatsTagSection>
    with StatsSectionRefresh {
  late Future<_TagData> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant StatsTagSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _reload();
    }
  }

  @override
  void onDataVersionChanged() {
    _reload();
  }

  /// 触发查询并在完成（成功或失败）后通知 onReady。
  void _reload() {
    _future = _load();
    _future.then(
      (_) => widget.onReady?.call(),
      onError: (_) => widget.onReady?.call(),
    );
  }

  Future<_TagData> _load() async {
    final sum = await ref
        .read(billRepoProvider)
        .sumByTagInRange(widget.start, widget.end, BillType.expense);
    final tags = await ref.read(tagRepoProvider).getAll();
    return _TagData(sum: sum, tags: tags);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TagData>(
      future: _future,
      builder: (context, snap) => xpFadeGate(snap, () {
        if (snap.connectionState != ConnectionState.done) {
          return const XpSkeletonList();
        }
        if (snap.hasError) {
          return XpErrorState(
            message: '${snap.error}',
            actionLabel: '重试',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final d = snap.data!;
        if (d.sum.isEmpty) {
          return const XpCard(
            padding: EdgeInsets.zero,
            child: XpEmptyState(icon: Icons.label_outline, title: '本时段暂无标签支出'),
          );
        }
        final total = d.sum.fold<int>(0, (s, e) => s + e.amount);
        final sorted = [...d.sum]..sort((a, b) => b.amount.compareTo(a.amount));
        final maxAmount = sorted.first.amount;
        return ListView(
          // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
          padding: EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.l,
            XpSpacing.l,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            XpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '标签支出 Top',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: XpSpacing.m),
                  for (var i = 0; i < sorted.length; i++)
                    _TagBar(
                      color: piePalette[i % piePalette.length],
                      name: _tagName(d.tags, sorted[i].tagId),
                      amount: sorted[i].amount,
                      total: total,
                      ratio: maxAmount > 0 ? sorted[i].amount / maxAmount : 0,
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _tagName(List<Tag> tags, String id) {
    for (final t in tags) {
      if (t.id == id) return t.name;
    }
    return '未知标签';
  }
}

/// 横向条形图行：名称 + 占比条形 + 金额。
class _TagBar extends StatelessWidget {
  const _TagBar({
    required this.color,
    required this.name,
    required this.amount,
    required this.total,
    required this.ratio,
  });

  final Color color;
  final String name;
  final int amount;
  final int total;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: XpSpacing.s),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: theme.textTheme.labelMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          Text(
            '${formatYuan(amount)}'
            '（${total > 0 ? (amount / total * 100).toStringAsFixed(0) : 0}%）',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                .tabular,
          ),
        ],
      ),
    );
  }
}
