import 'dart:async';

import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';

/// 长按 N 秒才触发的危险确认按钮：按住显示进度，中途松开即取消。
///
/// 用于高危操作（清空数据、删除定时任务等），比二次确认弹窗更防误触。
/// 满 N 秒自动回调 [onConfirmed]。
class LongPressDeleteButton extends StatefulWidget {
  const LongPressDeleteButton({
    super.key,
    required this.seconds,
    required this.onConfirmed,
    this.label,
  });

  final int seconds;
  final VoidCallback onConfirmed;

  /// 未按住时的提示文案（默认「长按 N 秒确认删除」）。
  final String? label;

  @override
  State<LongPressDeleteButton> createState() => _LongPressDeleteButtonState();
}

class _LongPressDeleteButtonState extends State<LongPressDeleteButton> {
  Timer? _timer;
  int _elapsedMs = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_timer != null) return;
    _elapsedMs = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() => _elapsedMs += 50);
      if (_elapsedMs >= widget.seconds * 1000) {
        t.cancel();
        _timer = null;
        setState(() {});
        widget.onConfirmed();
      }
    });
  }

  void _cancel() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    setState(() => _elapsedMs = 0);
  }

  @override
  Widget build(BuildContext context) {
    final holding = _timer != null;
    final progress = (_elapsedMs / (widget.seconds * 1000)).clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: XpSpacing.s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _start(),
            onTapUp: (_) => _cancel(),
            onTapCancel: _cancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: holding ? colorScheme.error : colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                holding
                    ? '松开取消 · ${widget.seconds - (_elapsedMs / 1000).floor()}s'
                    : widget.label ?? '长按 ${widget.seconds} 秒确认删除',
                style: TextStyle(
                  color: holding
                      ? colorScheme.onError
                      : colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 160,
            child: LinearProgressIndicator(
              value: holding ? progress : 0,
              minHeight: 3,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
