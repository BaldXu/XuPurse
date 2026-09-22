import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../tokens/design_tokens.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_skeleton.dart';

/// 异步视图 mixin:统一 AsyncValue 的 loading / error / 空 列表渲染。
///
/// 用法(ConsumerState 混入):
/// ```dart
/// xpWhen(context, asyncValue, data: (items) => ListView(...));
/// ```
/// loading 统一骨架屏(可用 [XpAsyncView.loading] 换自定义占位)、
/// error 统一「加载失败+重试」、空数据统一 XpEmptyState;
/// loading → 数据 由 AnimatedSwitcher 做淡入(XpMotion.component)。
mixin XpAsyncView<T extends StatefulWidget> on State<T> {
  Widget xpWhen<V>(
    BuildContext context,
    AsyncValue<V> async, {
    required Widget Function(V data) data,
    Widget Function(Object error, StackTrace? st)? error,
    bool Function(V)? isEmpty,
    WidgetBuilder? empty,
    VoidCallback? onRetry,
    WidgetBuilder? loading,
  }) {
    return AnimatedSwitcher(
      duration: XpMotion.component,
      switchInCurve: XpMotion.easeOut,
      switchOutCurve: XpMotion.easeIn,
      // 顶部对齐:列表骨架 → 列表内容 交叉淡变时内容不居中跳动。
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, if (currentChild != null) currentChild],
      ),
      child: KeyedSubtree(
        key: ValueKey<String>(_branchOf(async)),
        child: async.when(
          loading: () =>
              (loading != null) ? loading(context) : const XpSkeletonList(),
          error: (e, st) => (error != null)
              ? error(e, st)
              : _defaultError(context, e, onRetry: onRetry),
          data: (v) {
            if (isEmpty != null && isEmpty(v) && empty != null) {
              return empty(context);
            }
            return data(v);
          },
        ),
      ),
    );
  }

  /// 分支标识:与 AsyncValue.when 默认渲染逻辑对齐
  /// (有值优先,重建刷新时保持旧数据的 loading 不误标为 loading)。
  static String _branchOf<V>(AsyncValue<V> async) {
    if (async.hasValue) return 'data';
    if (async.hasError) return 'error';
    return 'loading';
  }

  Widget _defaultError(
    BuildContext context,
    Object e, {
    VoidCallback? onRetry,
  }) {
    return XpErrorState(
      message: '$e',
      actionLabel: onRetry == null ? null : '重试',
      onAction: onRetry,
    );
  }

  /// 常用空态:图标+文案。
  WidgetBuilder xpEmpty(IconData icon, String title, {String? message}) =>
      (_) => XpEmptyState(icon: icon, title: title, message: message);
}
