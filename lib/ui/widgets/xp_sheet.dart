import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../tokens/design_tokens.dart';
import 'xp_button.dart';

/// 统一底部配置弹窗入口。
///
/// - 高度：默认占屏幕垂直 85%（[heightFactor]）；可再叠加固定像素 [extraHeight]。
/// - 遮罩：弹窗外区域仅「变暗」（黑色渐变，无模糊——全屏实时模糊是
///   转场掉帧元凶，iOS 原生 sheet 同样只做变暗）。
/// - 表面：弹窗背景色（主题「弹窗背景色」）或「配置弹窗磨砂」（σ10 · α0.7），
///   两者互斥（磨砂开启时背景固定为半透明白）。
/// - 性能：iOS present sheet 同款分层——遮罩/滑入/拖拽全走渲染属性
///   （零逐帧 rebuild）；真实内容首帧即构建（此时弹窗在屏幕外，构建
///   成本不可见）；磨砂只作用于弹窗表面，滑入完成后淡入、开始关闭时
///   立即淡出——滑动过程零模糊重算。
/// - 交互：顶部拖拽手柄可下拉关闭；点击遮罩/返回键同样可关闭。
Future<T?> showXpSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.85,
  double extraHeight = 0,
  bool isDismissible = true,
  bool showDragHandle = true,
  Duration transitionDuration = XpMotion.component,
  Curve transitionCurve = Curves.easeOutCubic,
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
    transitionDuration: transitionDuration,
    // 出入场动画在 pageBuilder 内自驱（遮罩淡入 + 弹窗滑入）。
    transitionBuilder: (_, _, __, child) => child,
    pageBuilder: (ctx, animation, _) => _XpSheet(
      builder: builder,
      animation: animation,
      heightFactor: heightFactor,
      extraHeight: extraHeight,
      showDragHandle: showDragHandle,
      sheetOn: sheetOn,
      sheetColor: sheetColor,
      transitionCurve: transitionCurve,
    ),
  );
}

/// 配置弹窗主体：变暗遮罩 + 滑入 + 拖拽手柄 + 表面磨砂（到位后淡入）。
class _XpSheet extends StatefulWidget {
  const _XpSheet({
    required this.builder,
    required this.animation,
    required this.heightFactor,
    required this.extraHeight,
    required this.showDragHandle,
    required this.sheetOn,
    required this.sheetColor,
    required this.transitionCurve,
  });

  final WidgetBuilder builder;
  final Animation<double> animation;
  final double heightFactor;
  final double extraHeight;
  final bool showDragHandle;
  final bool sheetOn;
  final Color? sheetColor;

  /// 滑入/滑出位移曲线（默认 easeOutCubic，可整体放慢或换曲线）。
  final Curve transitionCurve;

  /// 弹窗表面磨砂的高斯模糊半径。
  static const double blurSigma = 10;

  /// 弹窗磨砂表面参数（半透明白，透明度较卡片磨砂低=更实）。
  static const double frostedAlpha = 0.7;

  /// 遮罩变暗强度。
  static const double barrierAlpha = 0.35;

  @override
  State<_XpSheet> createState() => _XpSheetState();
}

class _XpSheetState extends State<_XpSheet> with TickerProviderStateMixin {
  /// 拖拽位移：ValueNotifier 驱动，拖拽过程零 rebuild。
  final ValueNotifier<double> _drag = ValueNotifier(0);

  /// 表面磨砂淡入/淡出：滑入完成后淡入，开始关闭或下拉时淡出。
  late final AnimationController _frost;

  /// 滑入位移曲线（默认 easeOutCubic，非线性减速入场）。
  late final CurvedAnimation _slideCurve;

  late final void Function(AnimationStatus) _onStatus;

  @override
  void initState() {
    super.initState();
    _frost = AnimationController(vsync: this, duration: XpMotion.component);
    _slideCurve = CurvedAnimation(
      parent: widget.animation,
      curve: widget.transitionCurve,
    );
    // 磨砂只在弹窗到位后淡入；开始关闭/下拉时瞬间归零（不淡出——
    // 淡出期间每帧都在绘制模糊，而 sheet 又在移动，采样区每帧变化
    // → 每帧重算，这就是关闭掉帧的元凶）。归零后 Opacity 0 不绘制
    // 子树，滑出/拖拽全程零模糊重算，表面回到实色随 sheet 滑走。
    _onStatus = (status) {
      if (status == AnimationStatus.completed) {
        _frost.forward();
      } else if (status == AnimationStatus.reverse) {
        _frost.value = 0;
      }
    };
    widget.animation.addStatusListener(_onStatus);
    if (widget.animation.isCompleted) _frost.value = 1;
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onStatus);
    _frost.dispose();
    _slideCurve.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // 下拉时磨砂瞬间归零（拖拽全程零模糊重算）。
    if (d.delta.dy > 0 && _frost.value != 0) {
      _frost.value = 0;
    }
    _drag.value = math.max(0, _drag.value + d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    final close = _drag.value > 120 || d.velocity.pixelsPerSecond.dy > 800;
    if (close) {
      Navigator.of(context).pop();
    } else if (_drag.value > 0) {
      _drag.value = 0;
      _frost.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sheetH =
        MediaQuery.sizeOf(context).height * widget.heightFactor +
        widget.extraHeight;

    return Stack(
      children: [
        // 变暗遮罩：覆盖全屏（弹窗大圆角外的小区域同样压暗），只做
        // 变暗不模糊——FadeTransition 驱动，零逐帧 rebuild。
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: Tween<double>(
                begin: 0,
                end: _XpSheet.barrierAlpha,
              ).animate(widget.animation),
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ),
        // 弹窗主体：自下而上滑入。SlideTransition 只改渲染属性，
        // 滑入/滑出全程零 rebuild；拖拽位移同样走 ValueNotifier 局部重建。
        // RepaintBoundary：sheet 移动走纹理合成，内部内容零重绘——
        // 否则关闭时全量可见的表单每帧整块重绘（raster 15-20ms 的根因）。
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_slideCurve),
            child: ValueListenableBuilder<double>(
              valueListenable: _drag,
              builder: (_, drag, child) => drag == 0
                  ? child!
                  : Transform.translate(offset: Offset(0, drag), child: child),
              child: RepaintBoundary(
                child: _buildSheet(theme: theme, sheetH: sheetH),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheet({required ThemeData theme, required double sheetH}) {
    final scheme = theme.colorScheme;
    final bool frosted = widget.sheetOn;
    // 磨砂模式：0.7 白叠在模糊上；非磨砂：主题「弹窗背景色」或默认表面色。
    final Color bg = frosted
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
          type: MaterialType.transparency,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 表面磨砂：只模糊弹窗表面下的底层页面。必须先画模糊再画
              // 上面的半透明底色（模糊采样不含底色）。淡入后才绘制
              // （Opacity 0 不绘制）→ 滑入/滑出全程零模糊重算。
              if (frosted)
                FadeTransition(
                  opacity: _frost,
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
              ColoredBox(color: bg),
              // 磨砂未到位（滑入中/下拉中）时补白到实面：滑入期是纯白
              // 实面，到位后随磨砂淡入逐渐「透」出模糊，观感同 iOS sheet。
              if (frosted)
                FadeTransition(
                  opacity: ReverseAnimation(_frost),
                  child: ColoredBox(
                    color: Colors.white.withValues(
                      alpha: 1 - _XpSheet.frostedAlpha,
                    ),
                  ),
                ),
              Column(
                children: [
                  if (widget.showDragHandle) _buildDragHandle(theme),
                  // 真实内容首帧即构建：此时弹窗在屏幕外，构建成本不可见，
                  // 避免「滑完才懒构建」在动画结束帧打出 build 尖刺。
                  Expanded(child: widget.builder(context)),
                ],
              ),
            ],
          ),
        ),
      ),
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
  final ok = await showXpDialog<bool>(
    context: context,
    title: title,
    content: content,
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: Text(cancelLabel),
      ),
      danger
          ? XpButton(
              variant: XpButtonVariant.danger,
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            )
          : FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(confirmLabel),
            ),
    ],
  );
  return ok == true;
}
