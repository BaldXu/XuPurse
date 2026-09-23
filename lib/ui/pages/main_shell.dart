import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../layout/breakpoints.dart';
import '../layout/lazy_indexed_stack.dart';
import '../widgets/app_icon.dart';
import '../widgets/ai_chat_sheet.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_frosted_bar.dart';
import 'accounts_page.dart';
import 'bookkeeping_sheet.dart';
import 'home_page.dart';
import 'mine_page.dart';
import 'statistics_page.dart';
import '../tokens/design_tokens.dart';

/// 主导航壳：明细 / 资产 / 统计 / 我的。
///
/// IndexedStack 保持各页状态。自适应：
/// - 窄屏（手机竖屏）：底部 NavigationBar（现状不变）；
/// - 宽屏（桌面横屏）：左侧带文字标签的宽侧栏。
///
/// 磨砂模式:底部导航栏用 XpFrostedContainer 做磨砂玻璃,AppBar 由
/// XpPageScaffold 统一包装(XpRouteBar);各磨砂面各自捕获快照。
/// 2026-09: 曾用 BackdropGroup 让栏/卡共享一次引擎模糊,Flutter 3.35
/// 上滚动/重建会整帧闪灰黑(Impeller/Skia 均复现),已移除共享归组。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _pages = [
    HomePage(),
    AccountsPage(),
    StatisticsPage(),
    MinePage(),
  ];

  static const _icons = [
    Icons.receipt_long_outlined,
    Icons.account_balance_wallet_outlined,
    Icons.pie_chart_outline,
    Icons.person_outline,
  ];

  static const _selectedIcons = [
    Icons.receipt_long,
    Icons.account_balance_wallet,
    Icons.pie_chart,
    Icons.person,
  ];

  static const _labels = ['明细', '资产', '统计', '我的'];

  /// 切换主导航 tab；进入统计页(index 2)时重置 AI 悬浮按钮高度位置。
  void _selectTab(int i) {
    if (i == 2) {
      ref.read(aiFabTopProvider.notifier).state = null;
    }
    setState(() => _index = i);
  }

  /// 明细页「记一笔」FAB。放在外层壳（而非内层页面 Scaffold）：
  /// 外层 Scaffold 会把 FAB 自动置于底部导航之上，避免被磨砂导航遮挡。
  Widget _buildFab() {
    return XpFab(
      tooltip: '记一笔',
      onPressed: () => BookkeepingSheet.show(context),
      icon: const Icon(Icons.add),
    );
  }

  /// 宽屏：左侧带文字标签的宽侧栏 + 内容区。
  Widget _buildWide() {
    return Stack(
      children: [
        Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _selectTab,
              // extended：图标 + 文字标签的宽侧栏
              labelType: NavigationRailLabelType.none,
              extended: true,
              minExtendedWidth: 168,
              leading: const Padding(
                padding: EdgeInsets.fromLTRB(
                  XpSpacing.l,
                  XpSpacing.s,
                  XpSpacing.l,
                  XpSpacing.s,
                ),
                child: Text(
                  'XuPurse',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              destinations: [
                for (var i = 0; i < _labels.length; i++)
                  NavigationRailDestination(
                    icon: AppIcon(icon: _icons[i]),
                    selectedIcon: AppIcon(icon: _selectedIcons[i]),
                    label: Text(_labels[i]),
                  ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: LazyIndexedStack(index: _index, pages: _pages),
            ),
          ],
        ),
        if (_index == 0) Positioned(right: 24, bottom: 24, child: _buildFab()),
      ],
    );
  }

  /// 窄屏：底部导航栏。磨砂开 = 白色磨砂玻璃栏 + 内容穿透栏底(extendBody);
  /// 磨砂关 = 原生不透明 NavigationBar。
  Widget _buildNarrow(bool frosted) {
    final navBar = NavigationBar(
      backgroundColor: frosted ? Colors.transparent : null,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      selectedIndex: _index,
      onDestinationSelected: _selectTab,
      destinations: [
        for (var i = 0; i < _labels.length; i++)
          NavigationDestination(
            icon: AppIcon(icon: _icons[i]),
            selectedIcon: AppIcon(icon: _selectedIcons[i]),
            label: _labels[i],
          ),
      ],
    );
    return Scaffold(
      extendBody: frosted,
      body: LazyIndexedStack(index: _index, pages: _pages),
      // 与 XpRouteBar 同款重绘隔离（xp_page_scaffold_mixin）：磨砂栏独立成
      // 图层，body 滚动/重建时不与栏共享重绘区域。
      bottomNavigationBar: frosted
          ? RepaintBoundary(child: XpFrostedContainer(child: navBar))
          : navBar,
      floatingActionButton: _index == 0 ? _buildFab() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final frosted = ref.watch(frostedGlassProvider).barsOn;
    // LayoutBuilder 而非 MediaQuery.sizeOf：跟随实际可用宽窄切换布局。
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kWideBreakpoint;
        return wide ? _buildWide() : _buildNarrow(frosted);
      },
    );
  }
}
