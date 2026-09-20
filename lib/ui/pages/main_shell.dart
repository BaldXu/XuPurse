import 'package:flutter/material.dart';

import '../layout/breakpoints.dart';
import '../layout/lazy_indexed_stack.dart';
import 'accounts_page.dart';
import 'home_page.dart';
import 'mine_page.dart';
import 'statistics_page.dart';

/// 主导航壳：明细 / 资产 / 统计 / 我的。
///
/// IndexedStack 保持各页状态。自适应：
/// - 窄屏（手机竖屏）：底部 NavigationBar（现状不变）；
/// - 宽屏（桌面横屏）：左侧带文字标签的宽侧栏。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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
                icon: Icon(_icons[i]),
                selectedIcon: Icon(_selectedIcons[i]),
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

  /// 窄屏：现状不变（底部导航栏）。
  Widget _buildNarrow() {
    return Scaffold(
      body: LazyIndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_selectedIcons[i]),
              label: _labels[i],
            ),
        ],
      ),
      // 只给本 Scaffold 一个空 AppBar 高度占位：避免各页 Scaffold AppBar 颜色
      // 与 Rail 侧栏区拼接处出现视觉断层 —— 各页自带 AppBar，无需处理。
    );
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder 而非 MediaQuery.sizeOf：跟随实际可用宽窄切换布局。
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= kWideBreakpoint;
        return wide ? _buildWide() : _buildNarrow();
      },
    );
  }
}
