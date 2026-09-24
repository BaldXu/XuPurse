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
import 'report_providers.dart';
import 'report_widgets.dart';
import 'year_report_page.dart';

/// 总报告页（基础版）：累计数字 + 年度对比 + 年度明细。
///
/// 年份范围包含当前年份（当前年份在明细里标「进行中」，不参与「已结束年份」
/// 的说法，但数据照常计入累计）。
///
/// 数字全部来自 [yearReportsProvider]：年份汇总读缓存表，读前按数据指纹校准。
class TotalReportPage extends ConsumerStatefulWidget {
  const TotalReportPage({super.key});

  @override
  ConsumerState<TotalReportPage> createState() => _TotalReportPageState();
}

class _TotalReportPageState extends ConsumerState<TotalReportPage>
    with XpPageScaffold<TotalReportPage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('总报告')),
      buildBody: _buildBody,
    );
  }

  Widget _buildBody(BuildContext context) {
    return ref
        .watch(yearReportsProvider)
        .when(
          loading: () => const XpSkeletonList(),
          error: (e, _) => XpErrorState(
            message: '$e',
            actionLabel: '重试',
            onAction: () => ref.invalidate(yearReportsProvider),
          ),
          data: (reports) => _buildContent(context, reports),
        );
  }

  Widget _buildContent(BuildContext context, List<YearReport> reports) {
    if (reports.isEmpty) {
      return const XpEmptyState(
        icon: Icons.insights_outlined,
        title: '暂无报告数据',
        message: '有记账记录后，这里会生成累计报告',
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.l,
        XpSpacing.l,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _SummaryCard(reports: reports),
        const SizedBox(height: XpSpacing.l),
        _YearCompareCard(reports: reports),
        const SizedBox(height: XpSpacing.l),
        _YearBreakdownCard(reports: reports),
        const SizedBox(height: XpSpacing.l),
        const ReportFootnote(
          '口径说明：收入 / 支出不含转账、手动调整余额产生的调账账单，'
          '以及标记为「不计入收支」的账单；当前年份数据仍在累计中。',
        ),
      ],
    );
  }
}

/// 累计概览：全部年份的收支 + 累计资产变动 + 年限 / 年均支出 / 手动调整次数。
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.reports});

  /// 全部年度报告（年份倒序，含当前年份）。
  final List<YearReport> reports;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    var income = 0;
    var expense = 0;
    var bills = 0;
    var adjusts = 0;
    for (final r in reports) {
      income += r.income;
      expense += r.expense;
      bills += r.billCount;
      adjusts += r.adjustCount;
    }
    // 累计资产变动 = 最新年末资产 − 最早期初资产（逐年年末 = 下一年年初，首尾相消）。
    final latest = reports.first;
    final earliest = reports.last;
    final assetDelta = latest.endAssets - earliest.startAssets;

    // 年份升序，用于跨度和年均计算。
    final ascending = reports.reversed.toList();
    final span = ascending.length == 1
        ? '${ascending.first.year} 年'
        : '${ascending.first.year} 年 - ${ascending.last.year} 年';

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportSectionTitle(title: '累计概览', subtitle: '$span · 共 $bills 笔记账'),
          const SizedBox(height: XpSpacing.l),
          Row(
            children: [
              Expanded(
                child: ReportMetricCell(
                  label: '累计收入',
                  value: formatYuan(income),
                  valueColor: XpSemanticColors.income,
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '累计支出',
                  value: formatYuan(expense),
                  valueColor: XpSemanticColors.expense,
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '累计资产变动',
                  value: signedYuan(assetDelta),
                  valueColor: deltaColor(context, assetDelta),
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
                child: ReportMetricCell(
                  label: '记录年限',
                  value: '${ascending.length} 年',
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '年均支出',
                  value: formatYuan(expense ~/ ascending.length),
                ),
              ),
              Expanded(
                child: ReportMetricCell(label: '手动调整', value: '$adjusts 次'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 年度对比：每年「支出 / 收入」双柱（年份升序）。
class _YearCompareCard extends StatelessWidget {
  const _YearCompareCard({required this.reports});

  final List<YearReport> reports;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final years = reports.reversed.toList();

    final groups = <BarChartGroupData>[
      for (var i = 0; i < years.length; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 2,
          barRods: [
            BarChartRodData(
              toY: years[i].expense.toDouble(),
              color: XpSemanticColors.expense,
              width: 6,
            ),
            BarChartRodData(
              toY: years[i].income.toDouble(),
              color: XpSemanticColors.income,
              width: 6,
            ),
          ],
        ),
    ];

    // 资产变动最高的年份（仅看有资产基准的年份；用于卡片底部小结）。
    YearReport? best;
    for (final r in years) {
      if (!r.hasAssetBaseline) continue;
      if (best == null ||
          r.endAssets - r.startAssets > best.endAssets - best.startAssets) {
        best = r;
      }
    }

    return XpCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSectionTitle(title: '年度对比', subtitle: '每年记账收入与支出对照'),
          const SizedBox(height: XpSpacing.m),
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
                      // 年份多时抽稀标签，避免文字重叠。
                      interval: (years.length / 8).ceil().toDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= years.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${years[i].year}',
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
                      if (i < 0 || i >= years.length) return null;
                      final r = years[i];
                      final assetDelta = r.endAssets - r.startAssets;
                      return BarTooltipItem(
                        '${r.year} 年\n支出 ¥ ${formatYuan(r.expense)}'
                        '\n收入 ¥ ${formatYuan(r.income)}'
                        '\n资产变动 ${r.hasAssetBaseline ? signedYuan(assetDelta) : '—'}',
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
          if (best != null)
            Text(
              '资产变动最高：${best.year} 年 '
              '${signedYuan(best.endAssets - best.startAssets)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 年度明细：每年一行，点击进入该年年报告。
class _YearBreakdownCard extends StatelessWidget {
  const _YearBreakdownCard({required this.reports});

  /// 年份倒序（含当前年份）。
  final List<YearReport> reports;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thisYear = DateTime.now().year;

    return XpCard(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.l,
        XpSpacing.l,
        XpSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ReportSectionTitle(title: '年度明细', subtitle: '点击查看该年报告'),
          const SizedBox(height: XpSpacing.xs),
          for (var i = 0; i < reports.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            _YearRow(report: reports[i], ongoing: reports[i].year == thisYear),
          ],
        ],
      ),
    );
  }
}

/// 单个年份行：年份 + 笔数 + 资产变动 / 收支摘要。
class _YearRow extends StatelessWidget {
  const _YearRow({required this.report, required this.ongoing});

  final YearReport report;

  /// 是否为当前进行中的年份。
  final bool ongoing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    // 右侧主数值：资产变动（年末 − 年初），更贴合个人实际资产变化；
    // 缺少期初/期末快照时无法计算，显示占位。
    final assetDelta = report.endAssets - report.startAssets;
    final hasBaseline = report.hasAssetBaseline;

    return InkWell(
      onTap: () => Navigator.of(
        context,
      ).push(XpRoute(builder: (_) => YearReportPage(year: report.year))),
      borderRadius: BorderRadius.circular(XpRadius.c),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: XpSpacing.m),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${report.year} 年',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (ongoing) ...[
                        const SizedBox(width: XpSpacing.s),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: XpSpacing.s,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(XpRadius.pill),
                          ),
                          child: Text(
                            '进行中',
                            style: textTheme.labelSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: XpSpacing.xs),
                  Text(
                    '${report.billCount} 笔记录'
                    '${report.adjustCount > 0 ? ' · ${report.adjustCount} 次手动调整' : ''}',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasBaseline ? signedYuan(assetDelta) : '—',
                  style: textTheme.titleSmall
                      ?.copyWith(
                        color: hasBaseline
                            ? deltaColor(context, assetDelta)
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      )
                      .tabular,
                ),
                const SizedBox(height: XpSpacing.xs),
                Text(
                  '收 ${formatYuan(report.income)} · 支 ${formatYuan(report.expense)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: XpSpacing.xs),
            Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
