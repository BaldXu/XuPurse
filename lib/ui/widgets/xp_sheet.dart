import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../tokens/design_tokens.dart';

/// 统一底部配置弹窗入口。
///
/// - 高度：默认占屏幕垂直 85%（[heightFactor]）。
/// - 遮罩：弹窗外区域「变暗 + 高斯模糊」（σ10，与弹窗磨砂共用一层模糊）。
/// - 表面：弹窗背景色（主题「弹窗背景色」）或「配置弹窗磨砂」（σ10 · α0.7），
///   两者互斥（磨砂开启时背景固定为半透明白）。
/// - 性能：内容懒加载——滑入动画结束后才构建并淡入，重内容不拖慢出场动画。
/// - 交互：顶部拖拽手柄可下拉关闭；点击遮罩/返回键同样可关闭。
Future<T?> showXpSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.85,
  bool isDismissible = true,
  bool showDragHandle = true,
}) {
  // 弹窗生命周期内状态稳定，展示前捕获一次。
  final container = ProviderScope.containerOf(context, listen: false);
  final sheetOn = container.read(frostedGlassProvider).sheetOn;
  final sheetColor = container.read(currentThemeProvider).sheetColor;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent, // 遮罩视觉由 pageBuilder 自绘
    transitionDuration: XpMotion.component,
    // 出入场动画在 pageBuilder 内自驱（遮罩淡入 + 弹窗滑入）。
    transitionBuilder: (_, _, __, child) => child,
    pageBuilder: (ctx, animation, _) => _XpSheet(
      builder: builder,
      animation: animation,
      heightFactor: heightFactor,
      showDragHandle: showDragHandle,
      sheetOn: sheetOn,
      sheetColor: sheetColor,
    ),
  );
}

/// 配置弹窗主体：自绘遮罩（模糊+变暗）、滑入、拖拽手柄、懒加载淡入内容。
class _XpSheet extends StatefulWidget {
  const _XpSheet({
    required this.builder,
    required this.animation,
    required this.heightFactor,
    required this.showDragHandle,
    required this.sheetOn,
    required this.sheetColor,
  });

  final WidgetBuilder builder;
  final Animation<double> animation;
  final double heightFactor;
  final bool showDragHandle;
  final bool sheetOn;
  final Color? sheetColor;

  /// 遮罩与弹窗磨砂共用的高斯模糊半径。
  static const double blurSigma = 10;

  /// 弹窗磨砂表面参数（半透明白，透明度较卡片磨砂低=更实）。
  static const double frostedAlpha = 0.7;

  /// 遮罩变暗强度。
  static const double barrierAlpha = 0.35;

  @override
  State<_XpSheet> createState() => _XpSheetState();
}

class _XpSheetState extends State<_XpSheet> {
  bool _contentReady = false;
  double _drag = 0;

  late final void Function(AnimationStatus) _onStatus;

  @override
  void initState() {
    super.initState();
    // 滑入动画结束后再构建真实内容并淡入，保证出场不因重内容掉帧。
    _onStatus = (status) {
      if (status == AnimationStatus.completed && !_contentReady) {
        setState(() => _contentReady = true);
      }
    };
    widget.animation.addStatusListener(_onStatus);
    if (widget.animation.isCompleted) _contentReady = true;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _drag = math.max(0, _drag + d.delta.dy));
  }

  void _onDragEnd(DragEndDetails d) {
    final close = _drag > 120 || d.velocity.pixelsPerSecond.dy > 800;
    if (close) {
      Navigator.of(context).pop();
    } else if (_drag > 0) {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final media = MediaQuery.of(context);
        final screenH = media.size.height;
        final sheetH = screenH * widget.heightFactor;
        final t = Curves.easeOutCubic.transform(widget.animation.value);
        final slide = sheetH * (1 - t) + _drag;

        return Stack(
          children: [
            // 全屏高斯模糊：对底层页面（弹窗磨砂与其共享同一模糊层）。
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _XpSheet.blurSigma,
                    sigmaY: _XpSheet.blurSigma,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            // 变暗遮罩：覆盖全屏（层级低于弹窗），弹窗大圆角外的
            // 小区域同样保持暗色，视觉更自然。
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(
                    alpha: _XpSheet.barrierAlpha * widget.animation.value,
                  ),
                ),
              ),
            ),
            // 弹窗主体：自下而上滑入。
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(0, slide),
                child: _buildSheet(theme: Theme.of(context), sheetH: sheetH),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSheet({required ThemeData theme, required double sheetH}) {
    final scheme = theme.colorScheme;
    final Color bg = widget.sheetOn
        ? Colors.white.withValues(alpha: _XpSheet.frostedAlpha)
        : (widget.sheetColor ??
              theme.bottomSheetTheme.backgroundColor ??
              scheme.surfaceContainerLow);

    return SizedBox(
      key: const ValueKey('xp_sheet_surface'),
      width: double.infinity,
      height: sheetH,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: XpRadius.sheetLarge),
        child: Material(
          color: bg,
          child: Column(
            children: [
              if (widget.showDragHandle) _buildDragHandle(theme),
              Expanded(child: _buildContent(theme)),
            ],
          ),
        ),
      ),
    );
  }

  /// 内容懒加载 + 淡入：滑入动画完成前只渲染占位，完成后构建并淡入。
  Widget _buildContent(ThemeData theme) {
    return AnimatedOpacity(
      opacity: _contentReady ? 1 : 0,
      duration: XpMotion.component,
      curve: Curves.easeOut,
      child: _contentReady ? widget.builder(context) : const SizedBox.expand(),
    );
  }

  Widget _buildDragHandle(ThemeData theme) {
    final scheme = theme.colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Container(
        height: 28,
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// 日期选择弹窗：淡入 + 上移（XpMotion），进出场动画与页面转场一致，
/// 替代裸 showDatePicker（默认对话框转场太弱 + 首帧构建重，观感像没动画）。
Future<DateTime?> showXpDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
}) {
  return showGeneralDialog<DateTime>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: XpMotion.container,
    transitionBuilder: _xpDialogTransition,
    pageBuilder: (ctx, _, __) => DatePickerDialog(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      initialEntryMode: initialEntryMode,
    ),
  );
}

/// 日期范围选择弹窗（统计/趋势/首页自定义范围用），进出场动画同上。
Future<DateTimeRange?> showXpDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initialDateRangeStart,
  DateTime? initialDateRangeEnd,
  String? helpText,
  String? cancelText,
  String? confirmText,
  String? saveText,
}) {
  return showGeneralDialog<DateTimeRange>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: XpMotion.container,
    transitionBuilder: _xpDialogTransition,
    pageBuilder: (ctx, _, __) => DateRangePickerDialog(
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange:
          initialDateRangeStart != null && initialDateRangeEnd != null
          ? DateTimeRange(
              start: initialDateRangeStart,
              end: initialDateRangeEnd,
            )
          : null,
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      saveText: saveText,
    ),
  );
}

/// 对话框进出场：淡入 + 上移 4%（easeOut 进 / easeIn 出）。
Widget _xpDialogTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: XpMotion.easeOut,
    reverseCurve: XpMotion.easeIn,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// 限宽 AlertDialog:长文本确认弹窗在桌面宽屏不再被拉到接近全宽。
/// 项目内所有 showDialog(AlertDialog) 统一走这个封装。
Future<T?> showXpDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  Widget? contentWidget,
  required List<Widget> actions,
  double maxWidth = 400,
}) {
  return showDialog<T>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: contentWidget ?? (content != null ? Text(content) : null),
      ),
      actions: actions,
    ),
  );
}

/// 统一确认弹窗(取消 + 危险/普通确认),高频样板收敛。
Future<bool> confirmXpDialog(
  BuildContext context, {
  required String title,
  String? content,
  String confirmLabel = '确定',
  String cancelLabel = '取消',
  bool danger = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final ok = await showXpDialog<bool>(
    context: context,
    title: title,
    content: content,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel),
      ),
      FilledButton(
        style: danger
            ? FilledButton.styleFrom(backgroundColor: scheme.error)
            : null,
        onPressed: () => Navigator.pop(context, true),
        child: Text(confirmLabel),
      ),
    ],
  );
  return ok == true;
}
