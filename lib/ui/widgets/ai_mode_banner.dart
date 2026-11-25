import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_icon.dart';

/// AI 模式条：圆角矩形长条，单独一行写明「当前模式」。
///
/// - 详细模式：[warning] = true，浅红语义底（errorContainer），提示逐笔明细
///   会发送给 AI；
/// - 标准模式：中性表面底，只发聚合摘要。
///
/// 传 [onTap] 时整条可点（如跳转「数据边界」说明页）。
class AiModeBanner extends StatelessWidget {
  const AiModeBanner({
    super.key,
    required this.modeLabel,
    required this.description,
    this.warning = false,
    this.onTap,
  });

  /// 模式名（标准 / 详细）。
  final String modeLabel;

  /// 第二行说明。
  final String description;

  /// 是否使用浅红警示配色（详细模式）。
  final bool warning;

  /// 整条点击回调。
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = warning ? scheme.error : scheme.primary;
    // 语义色提示条：非常规卡片表面，沿用 data_manage 的 errorContainer 写法。
    final background = warning
        ? scheme.errorContainer.withValues(alpha: 0.45)
        : scheme.surfaceContainerHighest;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: background,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.m,
            XpSpacing.m,
            XpSpacing.m,
          ),
          child: Row(
            children: [
              AppIcon(
                icon: warning
                    ? Icons.shield_outlined
                    : Icons.auto_awesome_outlined,
                size: 22,
                color: accent,
              ),
              const SizedBox(width: XpSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前模式：$modeLabel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: warning ? scheme.error : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: XpSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: warning
                            ? scheme.onErrorContainer
                            : scheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(left: XpSpacing.xs),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
