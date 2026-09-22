import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/trend_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/adjust_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_stagger_in.dart';
import '../widgets/xp_empty_state.dart';
import 'account_detail_page.dart';
import 'account_form_sheet.dart';
import 'account_manage_page.dart';
import 'trend_page.dart';

/// 资产页：总资产 Hero（大金额 + 迷你趋势）→ 资产趋势入口 → 三类账户分组卡。
///
/// 口径与 totalAssetsProvider 一致（fund 恒计入；debt/record 仅
/// includeInAssets 时计入）；迷你趋势与趋势页共用算法五。
class AccountsPage extends ConsumerStatefulWidget {
  const AccountsPage({super.key});

  @override
  ConsumerState<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends ConsumerState<AccountsPage>
    with XpPageScaffold<AccountsPage> {
  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final total = ref.watch(totalAssetsProvider).value ?? 0;
    final snapsAsync = ref.watch(snapshotsProvider);
    final textTheme = Theme.of(context).textTheme;

    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('资产'),
        actions: [
          IconButton(
            tooltip: '账户管理',
            icon: const AppIcon(icon: Icons.manage_accounts_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountManagePage()),
            ),
          ),
          IconButton(
            tooltip: '新建账户',
            icon: const Icon(Icons.add),
            onPressed: () => AccountFormSheet.show(context),
          ),
        ],
      ),
      // 整页骨架：仅「无旧数据的首载」呈现；刷新期保留旧值不算 loading
      loading: accountsAsync.isLoading && accountsAsync.value == null,
      body: accountsAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (e, _) => Center(child: Text('加载失败：$e')),
        data: (accounts) {
          final assetIds = accounts
              .where(
                (a) =>
                    a.enabled &&
                    (a.category == 'fund' ||
                        ((a.category == 'debt' || a.category == 'record') &&
                            a.includeInAssets)),
              )
              .map((a) => a.id)
              .toSet();

          final groups = <AccountCategory, List<Account>>{};
          for (final a in accounts) {
            groups
                .putIfAbsent(
                  AccountCategory.values.byName(a.category),
                  () => [],
                )
                .add(a);
          }
          final hasAny = groups.isNotEmpty;
          // stagger 组序计数器(Builder 回调闭包递增)
          var groupIndex = 0;

          return ListView(
            // 底部留出穿透导航栏的高度(extendBody 注入的 MediaQuery bottom)。
            padding: EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.xs,
              XpSpacing.l,
              32 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              // ── 总资产 Hero ──
              _TotalAssetsHero(
                total: total,
                snaps: snapsAsync.value ?? const <BalanceSnapshot>[],
                assetIds: assetIds,
                accounts: accounts,
              ),
              const SizedBox(height: XpSpacing.m),
              // ── 资产趋势入口 ──
              XpCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrendPage()),
                ),
                child: Row(
                  children: [
                    AppIcon(
                      icon: Icons.show_chart,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: XpSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('资产趋势', style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '总资产曲线与期间统计',
                            style: textTheme.bodySmall?.copyWith(
                              color: textTheme.bodySmall?.color?.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
              if (!hasAny) ...[
                const SizedBox(height: XpSpacing.xl),
                const XpEmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: '还没有账户',
                  message: '点击右上角 + 创建第一个账户',
                ),
              ] else ...[
                for (final cat in AccountCategory.values)
                  if (groups.containsKey(cat)) ...[
                    _GroupHeader(label: _categoryTitle(cat)),
                    // 每组一张卡,组内账户行共享 ripple 裁剪;stagger 按组序淡入
                    Builder(
                      builder: (context) {
                        final idx = groupIndex++;
                        final card = XpCard(
                          padding: EdgeInsets.zero,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < groups[cat]!.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 60,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                _AccountRow(account: groups[cat]![i]),
                              ],
                            ],
                          ),
                        );
                        return idx < 6
                            ? XpStaggerIn(index: idx, child: card)
                            : card;
                      },
                    ),
                  ],
              ],
            ],
          );
        },
      ),
    );
  }

  static String _categoryTitle(AccountCategory cat) => switch (cat) {
    AccountCategory.fund => '资金账户',
    AccountCategory.record => '记录账户',
    AccountCategory.debt => '债务账户',
  };
}

/// 总资产 Hero:标签 + Display 大金额(tabular) + 近 90 天迷你趋势线。
/// 口径与趋势页一致(算法五 + assetIds 过滤),无快照/单点时隐藏迷你图。
class _TotalAssetsHero extends StatelessWidget {
  const _TotalAssetsHero({
    required this.total,
    required this.snaps,
    required this.assetIds,
    required this.accounts,
  });

  final int total;
  final List<BalanceSnapshot> snaps;
  final Set<String> assetIds;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day - 90,
    ).millisecondsSinceEpoch;
    final end =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch +
        86400000;

    final points = aggregateTrendPoints(
      buildTrendPoints(
        snaps: snaps,
        assetIds: assetIds,
        accounts: accounts,
        start: start,
        end: end,
      ),
      TrendGranularity.week,
    );

    return XpCard(
      padding: const EdgeInsets.all(XpSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '总资产',
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '¥',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: XpSpacing.xs),
              Text(
                formatYuan(total),
                style: textTheme.displayLarge
                    ?.copyWith(fontWeight: FontWeight.w700)
                    .tabular,
              ),
            ],
          ),
          if (points.length >= 2) ...[
            const SizedBox(height: XpSpacing.s),
            SizedBox(height: 56, child: _MiniTrend(points: points)),
          ],
        ],
      ),
    );
  }
}

/// 近 90 天迷你趋势线:无轴无 tooltip 的 sparkline,触感提示看趋势页。
class _MiniTrend extends StatelessWidget {
  const _MiniTrend({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final values = points.map((p) => p.value / 10000).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: minV == maxV ? minV - 1 : minV,
        maxY: minV == maxV ? maxV + 1 : maxV,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}

/// 账户行:图标色块 + 名称/备注 + tabular 金额;点按进详情,长按调余额。
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = hexToColor(account.color);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AccountDetailPage(account: account)),
      ),
      onLongPress: () => AdjustSheet.show(context, account),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: XpSpacing.m,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: AppIcon(name: account.icon, size: 20),
            ),
            const SizedBox(width: XpSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: textTheme.bodyLarge),
                  if (account.remark != null && account.remark!.isNotEmpty)
                    Text(
                      account.remark!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: XpSpacing.m),
            Text(
              formatYuan(account.currentBalance),
              style: textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)
                  .tabular,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, XpSpacing.l, 4, XpSpacing.s),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
