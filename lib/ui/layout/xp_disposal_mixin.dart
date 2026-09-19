import 'dart:async';

import 'package:flutter/material.dart';

/// 资源释放 mixin:登记的 controller/timer/subscription 在 dispose 自动释放。
///
/// 用法:
/// ```dart
/// late final _nameCtrl = register(TextEditingController());
/// _timer = registerTimer(Timer.periodic(...));
/// _sub = registerSub(stream.listen(...));
/// ```
/// 替代手写 dispose 清单,防泄漏兜底。
mixin XpDisposal<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _xpDisposers = [];

  /// 登记任意 ChangeNotifier 系对象(TextEditingController/FocusNode/
  /// AnimationController/ScrollController 等)并原样返回。
  A register<A extends ChangeNotifier>(A notifier) {
    _xpDisposers.add(notifier.dispose);
    return notifier;
  }

  /// 登记并返回 Timer,dispose 时自动 cancel。
  Timer registerTimer(Timer timer) {
    _xpDisposers.add(timer.cancel);
    return timer;
  }

  /// 登记并返回 StreamSubscription,dispose 时自动 cancel。
  StreamSubscription<E> registerSub<E>(StreamSubscription<E> sub) {
    _xpDisposers.add(sub.cancel);
    return sub;
  }

  @override
  void dispose() {
    for (final d in _xpDisposers.reversed) {
      d();
    }
    _xpDisposers.clear();
    super.dispose();
  }
}
