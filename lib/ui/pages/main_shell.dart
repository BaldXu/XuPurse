import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../layout/breakpoints.dart';
import '../layout/lazy_indexed_stack.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_frosted_bar.dart';
import 'accounts_page.dart';
import 'home_page.dart';
import 'mine_page.dart';
import 'statistics_page.dart';

/// 主导航壳：明细 / 资产 / 统计 / 我的。
///
/// IndexedStack 保持各页状态。自适应：
/// - 窄屏（手机竖屏）：底部 NavigationBar（现状不变）；
/// - 宽屏（桌面横屏）：左侧带文字标签的宽侧栏。
///
/// 磨砂模式:外层包 [BackdropGroup],一级页 AppBar 与底部导航栏共享一次
/// 引擎模糊(BackdropFilter.grouped 自动归组);开关关闭恢复原生样式。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  // 固定 key 避免每次 build 生成新组导致共享模糊层失效重建。
  late final BackdropKey _backdropKey = BackdropKey();

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

  /// 宽屏：左侧带文字标签的宽侧栏 + 内容区。
  Widget _buildWide() {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          // extended：图标 + 文字标签的宽侧栏
          labelType: NavigationRailLabelType.none,
          extended: true,
          minExtendedWidth: 168,
          leading: const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
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
          child: LazyIndexedStack(index: _index, children: _pages),
        ),
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
      onDestinationSelected: (i) => setState(() => _index = i),
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
      body: LazyIndexedStack(index: _index, children: _pages),
      bottomNavigationBar: frosted ? XpFrostedContainer(child: navBar) : navBar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final frosted = ref.watch(frostedGlassProvider).barsOn;
    // LayoutBuilder 而非 MediaQuery.sizeOf：跟随实际可用宽窄切换布局。
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kWideBreakpoint;
        final shell = wide ? _buildWide() : _buildNarrow(frosted);
        return frosted
            ? BackdropGroup(backdropKey: _backdropKey, child: shell)
            : shell;
      },
    );
  }
}
