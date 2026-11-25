import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_config.dart';
import '../../state/theme_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../pages/ai_chat_page.dart';

/// AI 悬浮按钮纵向位置（占页面可用高度的比例 0~1）；null = 使用默认 70%。
///
/// 由 MainShell 在每次切入统计页时重置为 null，按钮回到默认位置。
final aiFabTopProvider = StateProvider<double?>((ref) => null);

/// 统计页 AI 悬浮按钮：已配置 AI 时显示，点击进入整页聊天。
///
/// 默认位于屏幕右侧 70% 高度处；仅允许上下拖动（水平锁定右缘）；
/// 每次进入统计页重置回默认位置（见 [aiFabTopProvider]）。
class AiDraggableFab extends ConsumerStatefulWidget {
  const AiDraggableFab({super.key});

  @override
  ConsumerState<AiDraggableFab> createState() => _AiDraggableFabState();
}

class _AiDraggableFabState extends ConsumerState<AiDraggableFab> {
  /// 默认位于页面可用高度 70% 处。
  static const double _defaultFraction = 0.70;

  /// 右缘留白（与页面左右边距一致）。
  static const double _rightInset = XpSpacing.l;

  /// 拖动时上下最小留白。
  static const double _minMargin = 8;

  /// 按钮尺寸（FAB 标准 56）。
  static const double _fabSize = 56;

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(
      aiConfigProvider.select((s) => s.isConfigured),
    );
    if (!configured) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        // 窄屏磨砂导航开启时 body 延伸到底部导航之后，预留导航高度避免
        // 按钮被拖入/遮挡在导航栏区域；其余情况 body 已止于导航之上。
        final barsOn = ref.watch(frostedGlassProvider).barsOn;
        final reserve = barsOn && constraints.maxWidth < kSectionBreakpoint
            ? kBottomNavigationBarHeight
            : 0.0;
        final effectiveH = maxH - reserve;
        final minTop = _minMargin;
        final maxTop = effectiveH - _fabSize - _minMargin;
        if (effectiveH <= 0 || maxTop < minTop) {
          return const SizedBox.shrink();
        }

        final fraction = ref.watch(aiFabTopProvider);
        final defaultTop = effectiveH * _defaultFraction;
        final top = (fraction == null ? defaultTop : fraction * effectiveH)
            .clamp(minTop, maxTop)
            .toDouble();

        return Stack(
          children: [
            Positioned(
              right: _rightInset,
              top: top,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  final next = (top + d.delta.dy)
                      .clamp(minTop, maxTop)
                      .toDouble();
                  ref.read(aiFabTopProvider.notifier).state = next / effectiveH;
                },
                child: FloatingActionButton(
                  tooltip: 'AI 助手',
                  heroTag: 'ai_fab',
                  onPressed: () => Navigator.of(
                    context,
                  ).push(XpRoute(builder: (_) => const AiChatPage())),
                  child: const AppIcon(icon: Icons.smart_toy_outlined),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
