import 'package:flutter/material.dart';

import '../../../core/utils/amount.dart';
import '../../tokens/design_tokens.dart';

/// 带符号金额文本（正数 `+`、负数 `-`、零不带符号）。
String signedYuan(int amount) {
  if (amount > 0) return '+${formatYuan(amount)}';
  if (amount < 0) return '-${formatYuan(-amount)}';
  return formatYuan(0);
}

/// 涨跌语义色：正数收入绿、负数支出红、零弱化文字色。
Color deltaColor(BuildContext context, int amount) {
  if (amount > 0) return XpSemanticColors.income;
  if (amount < 0) return XpSemanticColors.expense;
  return Theme.of(context).colorScheme.onSurfaceVariant;
}

/// 指标格：上标签下数值（等宽数字），多列横排共用。
class ReportMetricCell extends StatelessWidget {
  const ReportMetricCell({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.caption,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// 数值下方的小字说明（可选）。
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: XpSpacing.xs),
        Text(
          value,
          style: textTheme.titleSmall
              ?.copyWith(color: valueColor, fontWeight: FontWeight.w700)
              .tabular,
        ),
        if (caption != null) ...[
          const SizedBox(height: 2),
          Text(
            caption!,
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// 卡片内分区标题（可选副标题）。
class ReportSectionTitle extends StatelessWidget {
  const ReportSectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: XpSpacing.xs),
          Text(
            subtitle!,
            style: textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// 口径/说明脚注（页面底部或分区内的小字）。
class ReportFootnote extends StatelessWidget {
  const ReportFootnote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.xs,
        XpSpacing.xs,
        XpSpacing.xs,
        0,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          height: 1.5,
        ),
      ),
    );
  }
}
