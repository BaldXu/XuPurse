import 'package:flutter/material.dart';

import 'app_icon.dart';
import '../tokens/design_tokens.dart';

/// 统一空状态占位:大图标 + 标题 + 副文 + 可选按钮。
/// 替代散落各页的私有 EmptyHint 实现与裸 Text('暂无...')。
class XpEmptyState extends StatelessWidget {
  const XpEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon: icon, size: 48, color: scheme.outline),
            const SizedBox(height: XpSpacing.m),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (message != null) ...[
              const SizedBox(height: XpSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: XpSpacing.l),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 统一错误态占位:错误图标 + 标题 + 错误详情 + 可选重试。
/// 替代散落各页的裸 Text('加载失败：$e')；xpWhen 默认错误分支也走这里。
class XpErrorState extends StatelessWidget {
  const XpErrorState({
    super.key,
    this.title = '加载失败',
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(icon: Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: XpSpacing.m),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (message != null) ...[
              const SizedBox(height: XpSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: XpSpacing.l),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
