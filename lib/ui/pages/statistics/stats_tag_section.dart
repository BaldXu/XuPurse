import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/amount.dart';
import '../../../data/database/app_database.dart';
import '../../../state/providers.dart';
import '../../widgets/xp_skeleton.dart';
import 'stats_shared.dart';

/// 标签分区：标签支出 Top 横向条形。
class StatsTagSection extends ConsumerStatefulWidget {
  const StatsTagSection({super.key, required this.start, required this.end});

  final int start;
  final int end;

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
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant StatsTagSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) {
      _future = _load();
    }
  }

  @override
  void onDataVersionChanged() {
    _future = _load();
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
          return Center(child: Text('加载失败：${snap.error}'));
        }
        final d = snap.data!;
        if (d.sum.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('本时段暂无标签支出')),
            ),
          );
        }
        final total = d.sum.fold<int>(0, (s, e) => s + e.amount);
        final sorted = [...d.sum]..sort((a, b) => b.amount.compareTo(a.amount));
        final maxAmount = sorted.first.amount;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '标签支出 Top',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
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
          const SizedBox(width: 8),
          SizedBox(
            width: 64,
            child: Text(
              name,
              style: const TextStyle(fontSize: 12),
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
          const SizedBox(width: 8),
          Text(
            '${formatYuan(amount)}'
            '（${total > 0 ? (amount / total * 100).toStringAsFixed(0) : 0}%）',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
