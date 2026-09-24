import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/amount.dart';
import '../../../data/database/app_database.dart';
import '../../layout/xp_page_scaffold_mixin.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_skeleton.dart';
import 'report_providers.dart';
import 'report_widgets.dart';
import 'total_report_page.dart';
import 'year_report_page.dart';

/// 报告汇总列表页：顶部固定「总报告」，下方按年份倒序列出已结束年份。
///
/// 当前年份不单列（数据未结束，只在总报告里体现），与需求一致。
/// 全部数字来自 [yearReportsProvider]（读前按数据指纹校准缓存）。
class ReportListPage extends ConsumerStatefulWidget {
  const ReportListPage({super.key});

  @override
  ConsumerState<ReportListPage> createState() => _ReportListPageState();
}

class _ReportListPageState extends ConsumerState<ReportListPage>
    with XpPageScaffold<ReportListPage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('报告汇总')),
      // buildBody：push 转场期间只出骨架，转场结束后才订阅 provider
      // （缓存校准 + 聚合查询不抢转场帧）。
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
          data: (reports) => _buildList(context, reports),
        );
  }

  Widget _buildList(BuildContext context, List<YearReport> reports) {
    final thisYear = DateTime.now().year;
    final years = [
      for (final r in reports)
        if (r.year < thisYear) r,
    ];

    return ListView(
      padding: EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.l,
        XpSpacing.l,
        32 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _TotalReportCard(reports: reports),
        const SizedBox(height: XpSpacing.l),
        if (years.isEmpty)
          const XpEmptyState(
            icon: Icons.insights_outlined,
            title: '暂无已结束年份的报告',
            message: '完成一个完整年份的记账后，这里会生成该年度的报告',
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(
              left: XpSpacing.xs,
              bottom: XpSpacing.s,
            ),
            child: Text(
              '年度报告',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          for (var i = 0; i < years.length; i++) ...[
            if (i > 0) const SizedBox(height: XpSpacing.m),
            _YearReportCard(
              report: years[i],
              onTap: () => _push(YearReportPage(year: years[i].year)),
            ),
          ],
        ],
      ],
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(XpRoute(builder: (_) => page));
  }
}

/// 顶部固定「总报告」入口：全部年份累计收支概览。
class _TotalReportCard extends StatelessWidget {
  const _TotalReportCard({required this.reports});

  /// 全部年度报告（年份倒序，含当前年份）。
  final List<YearReport> reports;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    var income = 0;
    var expense = 0;
    for (final r in reports) {
      income += r.income;
      expense += r.expense;
    }
    final balance = income - expense;
    final span = reports.isEmpty
        ? '暂无记录'
        : reports.length == 1
        ? '${reports.first.year} 年'
        : '${reports.last.year} - ${reports.first.year} · ${reports.length} 个年份';

    return XpCard(
      onTap: () => Navigator.of(
        context,
      ).push(XpRoute(builder: (_) => const TotalReportPage())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TintedIcon(Icons.summarize_outlined, color: scheme.primary),
              const SizedBox(width: XpSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '总报告',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      span,
                      style: textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
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
                  label: '累计结余',
                  value: signedYuan(balance),
                  valueColor: deltaColor(context, balance),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单年报告入口卡：年份 + 收支结余摘要 + 记账条数。
class _YearReportCard extends StatelessWidget {
  const _YearReportCard({required this.report, required this.onTap});

  final YearReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final balance = report.income - report.expense;

    return XpCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${report.year}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: XpSpacing.xs),
              Text(
                '年',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          Row(
            children: [
              Expanded(
                child: ReportMetricCell(
                  label: '收入',
                  value: formatYuan(report.income),
                  valueColor: XpSemanticColors.income,
                ),
              ),
              Expanded(
                child: ReportMetricCell(
                  label: '支出',
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
          Text(
            '${report.billCount} 笔记录'
            '${report.adjustCount > 0 ? ' · ${report.adjustCount} 次手动调整' : ''}',
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 图标色块（primary 低透明度圆角底 + 前景图标）。
///
/// 图标经 [AppIcon] 渲染，跟随用户所选图标风格（简约 / Twitter 表情）。
class _TintedIcon extends StatelessWidget {
  const _TintedIcon(this.icon, {required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(XpRadius.c),
      ),
      child: AppIcon(icon: icon, size: 20, color: color),
    );
  }
}
