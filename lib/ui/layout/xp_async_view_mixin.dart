import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/xp_empty_state.dart';
import '../widgets/xp_sheet.dart';

/// 异步视图 mixin:统一 AsyncValue 的 loading / error / 空 列表渲染。
///
/// 用法(ConsumerState 混入):
/// ```dart
/// xpWhen(context, asyncValue, data: (items) => ListView(...));
/// ```
/// loading 统一转圈、error 统一「加载失败+重试」、空数据统一 XpEmptyState。
mixin XpAsyncView<T extends StatefulWidget> on State<T> {
  Widget xpWhen<V>(
    BuildContext context,
    AsyncValue<V> async, {
    required Widget Function(V data) data,
    Widget Function(Object error, StackTrace? st)? error,
    bool Function(V)? isEmpty,
    WidgetBuilder? empty,
    VoidCallback? onRetry,
  }) {
    return async.when(
      loading: () => const XpLoading(),
      error: (e, st) =>
          (error != null)
              ? error(e, st)
              : _defaultError(context, e, onRetry: onRetry),
      data: (v) {
        if (isEmpty != null && isEmpty(v) && empty != null) {
          return empty(context);
        }
        return data(v);
      },
    );
  }

  Widget _defaultError(BuildContext context, Object e, {VoidCallback? onRetry}) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: scheme.error),
          const SizedBox(height: 8),
          Text('加载失败：$e', style: TextStyle(color: scheme.onSurfaceVariant)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }

  /// 常用空态:图标+文案。
  WidgetBuilder xpEmpty(IconData icon, String title, {String? message}) =>
      (_) => XpEmptyState(icon: icon, title: title, message: message);
}
