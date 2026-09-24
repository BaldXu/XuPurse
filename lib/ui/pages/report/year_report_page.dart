import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/amount.dart';
import '../../../data/database/app_database.dart';
import '../../layout/xp_page_scaffold_mixin.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_skeleton.dart';
import '../statistics/stats_shared.dart';
import 'report_providers.dart';
import 'report_widgets.dart';

/// 年报告详情页。
///
/// 分区：
/// 1. 年度概览：记录收入 / 记录支出 / 结余 / 储蓄率 / 月均支出 / 手动调整次数
/// 2. 资产变动：年初 → 年末 + 资产变动差额（资产实际变动 − 记录结余）
/// 3. 月度收支：12 个月收支双柱
/// 4. 支出构成：一级分类 Top5 环形图
///
/// 数据来源：年度汇总读缓存表 [yearReportsProvider]（口径见 [ReportRepository]），
/// 月度/分类明细按年实时查询 [yearDetailProvider]（两者口径一致，均为「排除
/// 调账与不计入收支」）。
class YearReportPage extends ConsumerStatefulWidget {
  const YearReportPage({super.key, required this.year});

  final int year;

  @override
  ConsumerState<YearReportPage> createState() => _YearReportPageState();
}

class _YearReportPageState extends ConsumerState<YearReportPage>
    with XpPageScaffold<YearReportPage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: Text('${widget.year} 年报告')),
      buildBody: _buildBody,
    );
  }

  Widget _buildBody(BuildContext context) {
    final reportsAsync = ref.watch(yearReportsProvider);
    return reportsAsync.when(
      loading: () => const XpSkeletonList(),
      error: (e, _) => XpErrorState(
        message: '$e',
        actionLabel: '重试',
        onAction: () => ref.invalidate(yearReportsProvider),
      ),
      data: (reports) {
        YearReport? report;
        for (final r in reports) {
          if (r.year == widget.year) {
            report = r;
            break;
          }
        }
        if (report == null) {
          return XpEmptyState(
            icon: Icons.insights_outlined,
            title: '${widget.year} 年暂无记录',
          );
        }
        final reportData = report;
        return ref
            .watch(yearDetailProvider(widget.year))
            .when(
              loading: () => const XpSkeletonList(),
              error: (e, _) => XpErrorState(
                message: '$e',
                actionLabel: '重试',
                onAction: () => ref.invalidate(yearDetailProvider(widget.year)),
              ),
              data: (detail) => _buildContent(context, reportData, detail),
            );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    YearReport report,
    YearDetail detail,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.l,
        XpSpacing.l,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _OverviewCard(report: report),
        const SizedBox(height: XpSpacing.l),
        _AssetChangeCard(report: report),
        const SizedBox(height: XpSpacing.l),
        _MonthlyCard(report: report, monthly: detail.monthly),
        const SizedBox(height: XpSpacing.l),
        _CategoryCard(detail: detail),
        const SizedBox(height: XpSpacing.l),
        const ReportFootnote(
          '口径说明：收入 / 支出不含转账、手动调整余额产生的调账账单，'
          '以及标记为「不计入收支」的账单。外币账户按当前汇率折算。',
        ),
      ],
    );
  }
}

/// 年度概览：记录收支 + 结余 + 储蓄率 + 月均支出 + 手动调整次数。
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.report});

  final YearReport report;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final balance = report.income - report.expense;
    final savingRate = report.income > 0
        ? '${(balance / report.income * 100).toStringAsFixed(0)}%'
        : '—';

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionTitle(
            title: '年度概览',
            subtitle: '${report.year} 年 · 共 ${report.billCount} 笔记账',
          ),
          const SizedBox(height: XpSpacing.l),
          Row(
            children: [
              Expanded(
                child: ReportMetricCell(
                  label: '总收入',
                  value: formatYuan(report.income),
                  valueColor: XpSemanticColors.income,
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '总支出',
                  value: formatYuan(report.expense),
                  valueColor: XpSemanticColors.expense,
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '结余',
                  value: signedYuan(balance),
                  valueColor: deltaColor(context, balance),
                ),
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          Divider(height: 1, color: scheme.outlineVariant),
          const SizedBox(height: XpSpacing.m),
          Row(
            children: [
              Expanded(
                child: ReportMetricCell(label: '储蓄率', value: savingRate),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '月均支出',
                  value: formatYuan(report.expense ~/ 12),
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '手动调整',
                  value: '${report.adjustCount} 次',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 资产变动：年初 / 年末资产 + 资产变动差额。
///
/// 资产变动差额 = 资产实际变动 − 记录结余，即「没有体现在记账里的资产变化」，
/// 通常来自手动调整余额或未记录的收入 / 支出。
class _AssetChangeCard extends StatelessWidget {
  const _AssetChangeCard({required this.report});

  final YearReport report;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (!report.hasAssetBaseline) {
      return XpCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ReportSectionTitle(title: '资产变动'),
            const SizedBox(height: XpSpacing.s),
            Text(
              '该年缺少期初或期末的资产快照，暂无法计算资产变动。'
              '（调整账户余额时会自动记录资产快照）',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final assetDelta = report.endAssets - report.startAssets;
    final balance = report.income - report.expense;
    final gap = assetDelta - balance;

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSectionTitle(
            title: '资产变动',
            subtitle: '年初到年末的资产增长与记账结余的对照',
          ),
          const SizedBox(height: XpSpacing.l),
          Row(
            children: [
              _SideValue(
                label: '年初资产',
                value: formatYuan(report.startAssets),
                alignment: CrossAxisAlignment.start,
              ),
              Expanded(
                child: Icon(
                  Icons.arrow_right_alt,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              _SideValue(
                label: '年末资产',
                value: formatYuan(report.endAssets),
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.l),
          Row(
            children: [
              Expanded(
                child: ReportMetricCell(
                  label: '资产变动',
                  value: signedYuan(assetDelta),
                  valueColor: deltaColor(context, assetDelta),
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '记录结余',
                  value: signedYuan(balance),
                  valueColor: deltaColor(context, balance),
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '资产变动差额',
                  value: signedYuan(gap),
                  valueColor: deltaColor(context, gap),
                  caption: report.adjustCount > 0
                      ? '含手动调整 ${signedYuan(report.adjustNet)}'
                      : null,
                ),
              ),
            ],
          ),
          const ReportFootnote(
            '「资产变动差额」= 资产实际变动 − 记录结余，'
            '即没有记进账本的那部分资产变化，通常来自手动调整余额或漏记的收支；'
            '外币账户按当前汇率折算，金额可能略有偏差。',
          ),
        ],
      ),
    );
  }
}

/// 左侧 / 右侧对齐的「标签 + 金额」纵向组合。
class _SideValue extends StatelessWidget {
  const _SideValue({
    required this.label,
    required this.value,
    required this.alignment,
  });

  final String label;
  final String value;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: XpSpacing.xs),
        Text(
          value,
          style: textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)
              .tabular,
        ),
      ],
    );
  }
}

/// 月度收支：12 个月「支出 / 收入」双柱。
class _MonthlyCard extends StatelessWidget {
  const _MonthlyCard({required this.report, required this.monthly});

  final YearReport report;
  final List<({int month, int income, int expense})> monthly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (report.billCount == 0) {
      return const XpCard(
        padding: EdgeInsets.zero,
        child: XpEmptyState(icon: Icons.bar_chart, title: '该年暂无收支记录'),
      );
    }

    final groups = <BarChartGroupData>[
      for (var i = 0; i < monthly.length; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 2,
          barRods: [
            BarChartRodData(
              toY: monthly[i].expense.toDouble(),
              color: XpSemanticColors.expense,
              width: 5,
            ),
            BarChartRodData(
              toY: monthly[i].income.toDouble(),
              color: XpSemanticColors.income,
              width: 5,
            ),
          ],
        ),
    ];

    // 支出最高的月份（用于卡片底部小结）。
    var peak = monthly.first;
    for (final m in monthly) {
      if (m.expense > peak.expense) peak = m;
    }

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSectionTitle(title: '月度收支'),
          const SizedBox(height: XpSpacing.s),
          Row(
            children: [
              _Dot(color: XpSemanticColors.expense, label: '支出'),
              const SizedBox(width: XpSpacing.m),
              _Dot(color: XpSemanticColors.income, label: '收入'),
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                barGroups: groups,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= monthly.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${monthly[i].month}',
                            style: theme.textTheme.labelSmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipBorder: BorderSide(color: scheme.outline),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final i = group.x.toInt();
                      if (i < 0 || i >= monthly.length) return null;
                      final m = monthly[i];
                      return BarTooltipItem(
                        '${m.month} 月\n支出 ¥ ${formatYuan(m.expense)}'
                        '\n收入 ¥ ${formatYuan(m.income)}',
                        TextStyle(
                          color: scheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: XpSpacing.xs),
          if (peak.expense > 0)
            Text(
              '支出最高：${peak.month} 月 ¥ ${formatYuan(peak.expense)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 支出构成：一级分类 Top5 环形图 + 图例。
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.detail});

  final YearDetail detail;

  @override
  Widget build(BuildContext context) {
    final sorted = detail.topLevelSum();
    if (sorted.isEmpty) {
      return const XpCard(
        padding: EdgeInsets.zero,
        child: XpEmptyState(icon: Icons.pie_chart_outline, title: '该年暂无支出'),
      );
    }
    final total = sorted.fold<int>(0, (s, e) => s + e.amount);
    final top5 = sorted.take(5).toList();
    final otherAmount = total - top5.fold<int>(0, (s, e) => s + e.amount);

    final sections = <PieChartSectionData>[
      for (var i = 0; i < top5.length; i++)
        PieChartSectionData(
          value: top5[i].amount.toDouble(),
          title: '${(top5[i].amount / total * 100).toStringAsFixed(0)}%',
          color: piePalette[i % piePalette.length],
          radius: 52,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      if (otherAmount > 0)
        PieChartSectionData(
          value: otherAmount.toDouble(),
          title: '${(otherAmount / total * 100).toStringAsFixed(0)}%',
          color: piePalette[5],
          radius: 52,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
        ),
    ];

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionTitle(
            title: '支出构成',
            subtitle: '全年支出 ¥ ${formatYuan(total)}',
          ),
          const SizedBox(height: XpSpacing.m),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                  ),
                ),
              ),
              const SizedBox(width: XpSpacing.l),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < top5.length; i++)
                      _legend(
                        context,
                        piePalette[i % piePalette.length],
                        top5[i].name,
                        top5[i].amount,
                        total,
                      ),
                    if (otherAmount > 0)
                      _legend(context, piePalette[5], '其他', otherAmount, total),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(
    BuildContext context,
    Color color,
    String name,
    int amount,
    int total,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: XpSpacing.s),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${formatYuan(amount)}（${(amount / total * 100).toStringAsFixed(0)}%）',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 图例圆点 + 文案。
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: XpSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
