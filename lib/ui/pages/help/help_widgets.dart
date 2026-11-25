import 'package:flutter/material.dart';

import '../../tokens/design_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/xp_card.dart';

/// 说明页通用排版组件（`pages/help/` 下的说明页统一用这一套）。
///
/// - [HelpSectionTitle]：分区标题；
/// - [HelpStepsCard]：编号步骤卡（如「怎么配置 AI」）；
/// - [HelpPointCard]：图标 + 标题 + 要点卡；
/// - [HelpNote]：分区下方的小字补充。
///
/// 新增说明页时直接复用，别在页面里再复制一份卡片/步骤行样式——
/// 样式统一靠这里收口，改一处全站生效。
class HelpSectionTitle extends StatelessWidget {
  const HelpSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 说明正文里的小字补充（灰色、左右各留一点缩进，和卡片拉开层次）。
class HelpNote extends StatelessWidget {
  const HelpNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: XpSpacing.xs),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 编号步骤卡：每行一个圆形序号 + 步骤文案。
class HelpStepsCard extends StatelessWidget {
  const HelpStepsCard({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return XpCard(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            _StepRow(
              n: i + 1,
              text: steps[i],
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.n,
    required this.text,
    required this.isLast,
  });

  final int n;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : XpSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: XpSpacing.s),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

/// 要点卡：图标 + 标题 + 可选入口说明 + 若干条要点。
class HelpPointCard extends StatelessWidget {
  const HelpPointCard({
    super.key,
    required this.icon,
    required this.title,
    this.where,
    required this.points,
  });

  final IconData icon;
  final String title;

  /// 使用入口；原理/能力说明类卡片无入口，传 null。
  final String? where;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return XpCard(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.m,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon: icon, size: 22, color: scheme.primary),
              const SizedBox(width: XpSpacing.s),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (where != null) ...[
            const SizedBox(height: XpSpacing.xs),
            Text(
              where!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: XpSpacing.m),
          for (var i = 0; i < points.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == points.length - 1 ? 0 : XpSpacing.s,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '·',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: XpSpacing.s),
                  Expanded(
                    child: Text(points[i], style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
