import 'package:flutter/material.dart';

import '../tokens/design_tokens.dart';
import 'app_icon.dart';

/// 前导图标色块尺寸（与设置页入口行保持一致）。
const double _iconBlockSize = 36;

/// 主/副标题之间的视觉微调间距。
const double _labelGap = 1;

/// 带前导图标块的参数行分隔线缩进（与图标右侧文字左缘对齐）。
const double kXpParamDividerIndentWithLeading =
    XpSpacing.l + _iconBlockSize + XpSpacing.m;

/// 统一参数行：左标签（可选前导图标块 / 自定义前导）+ 右值 + chevron。
///
/// 设置入口、偏好项、记账弹窗的参数设置区共用同一套行高、间距与 chevron，
/// 避免各页面自行拼 Row 导致视觉漂移。
class XpParamRow extends StatelessWidget {
  const XpParamRow({
    super.key,
    required this.label,
    this.subtitle,
    this.value,
    this.valueWidget,
    this.leadingIcon,
    this.leading,
    this.valueStyle,
    this.showChevron = true,
    this.onTap,
  });

  /// 主标签文案。
  final String label;

  /// 副标签（可选，单行省略）。
  final String? subtitle;

  /// 右侧值文案（与 [valueWidget] 二选一）。
  final String? value;

  /// 右侧自定义值（如旗帜 + 余额的组合）。
  final Widget? valueWidget;

  /// 前导图标（渲染为 36×36 的 primary 低透明度圆角色块）。
  final IconData? leadingIcon;

  /// 完全自定义前导（如账户头像），优先于 [leadingIcon]。
  final Widget? leading;

  /// 覆盖右侧值样式。
  final TextStyle? valueStyle;

  /// 是否显示右侧 chevron（纯展示行传 false）。
  final bool showChevron;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final valueBase = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: XpSpacing.m,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: XpSpacing.m),
            ] else if (leadingIcon != null) ...[
              _IconBlock(icon: leadingIcon!),
              const SizedBox(width: XpSpacing.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: _labelGap),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (valueWidget != null) ...[
              const SizedBox(width: XpSpacing.m),
              valueWidget!,
            ] else if (value != null) ...[
              const SizedBox(width: XpSpacing.m),
              Flexible(
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: valueStyle == null
                      ? valueBase
                      : valueBase.merge(valueStyle),
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: XpSpacing.xs),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 参数行之间的发丝分隔线。
class XpParamDivider extends StatelessWidget {
  const XpParamDivider({super.key, this.indent = 0});

  /// 左侧缩进（带前导图标块时传 [kXpParamDividerIndentWithLeading]）。
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: indent,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}

/// 设置入口式图标色块。
class _IconBlock extends StatelessWidget {
  const _IconBlock({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _iconBlockSize,
      height: _iconBlockSize,
      decoration: ShapeDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        shape: XpShape.smooth(
          borderRadius: BorderRadius.circular(XpRadius.s),
        ),
      ),
      child: AppIcon(icon: icon, size: 20, color: colorScheme.primary),
    );
  }
}
