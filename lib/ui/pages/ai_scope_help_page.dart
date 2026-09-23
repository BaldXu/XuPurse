import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';

/// AI 数据读取与脱敏介绍页：解释应用如何给 AI 提供数据、摘要如何生成、
/// 如何脱敏（纯文本卡片排版，样式与 AI 介绍页一致）。
class AiScopeHelpPage extends StatefulWidget {
  const AiScopeHelpPage({super.key});

  @override
  State<AiScopeHelpPage> createState() => _AiScopeHelpPageState();
}

class _AiScopeHelpPageState extends State<AiScopeHelpPage>
    with XpPageScaffold<AiScopeHelpPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('AI 如何读取我的数据？')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          Text(
            '你在聊天窗提问时，应用会先从你本机的账单里生成一份「统计摘要」，'
            '随问题一起发给 AI。这份摘要就是 AI 唯一能看到的你的数据。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xl),

          Text(
            '数据是怎么发出去的',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          const _PointCard(
            icon: Icons.description_outlined,
            title: '不是原始账单，是脱敏摘要',
            points: [
              '发送前，应用在你本机把账单聚合成一段 Markdown 文本（可以理解'
                  '成一份脱敏后的「财务简报」），再附到你的问题后面发给 AI。',
              '默认只发金额合计、分类排行、趋势等汇总数据，'
                  '不含单笔账单的备注、地点、标签、附件等明细。',
              '你配置的 AI 服务商只会收到这份摘要 + 你的对话内容，'
                  '不会拿到你的完整账本数据。',
              '每段对话只附送一次：同一个聊天窗口内，首次提问会带上摘要，'
                  '之后的追问不再重复发送（省 tokens）；如果账本数据有更新，'
                  '新开一个聊天窗口即可让 AI 读取到最新摘要。',
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          const _PointCard(
            icon: Icons.dns_outlined,
            title: '全部在你本机完成',
            points: [
              '摘要的读取与聚合都在你本机完成，不上传任何原始数据；'
                  'API Key 与对话内容也只发送到你配置的 API 端点。',
            ],
          ),
          const SizedBox(height: XpSpacing.xl),

          Text(
            '摘要是怎么生成的',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          const _PointCard(
            icon: Icons.tune,
            title: '按「数据范围设置」聚合',
            points: [
              '每次发送前，应用读取本机账本，按你在「数据范围设置」页勾选的内容做聚合计算。',
              '时间范围：决定统计覆盖的时间窗口（近1个月 / 3个月 / 6个月 / 1年 / 全部）。',
              '资产情况：账户余额与资产趋势。',
              '收支情况：收支汇总、按月趋势与预算执行。',
              '分类 Top N：支出 / 收入分类金额排行。',
              '备注与标签（可选）：账单标签排行、备注文本的金额排行，'
                  '默认关闭，开启需谨慎（涉及隐私）。',
            ],
          ),
          const SizedBox(height: XpSpacing.xl),

          Text(
            '如何脱敏（隐私保护）',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          const _PointCard(
            icon: Icons.shield_outlined,
            title: '多重保护',
            points: [
              '默认只发汇总，不发明细：摘要默认只含金额合计、分类排行、趋势，'
                  '不含单笔账单的备注、地点、标签、附件等明细。',
              '标签/备注需主动开启：这两项贴近消费明细、涉及隐私，默认关闭；'
                  '只有你在「数据范围设置」里开启后，才会把账单标签排行、'
                  '备注文本的金额排行发给 AI。',
              '不含敏感标识：账户名、分类名是你本地的自定义名称；'
                  '系统提示词同时禁止 AI 复述或索要身份证号、卡号等敏感信息。',
              '总开关兜底：在「数据范围设置」关闭总开关后，应用完全不向 AI '
                  '发送任何本机数据，聊天退回纯聊天模式。',
            ],
          ),
          const SizedBox(height: XpSpacing.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.xs),
            child: Text(
              '提示：你可以随时在「数据范围设置」页调整这些范围，'
              '保存后全局生效。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 要点卡片：图标 + 标题 + 说明点（样式与 AI 介绍页功能卡一致）。
class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.icon,
    required this.title,
    required this.points,
  });

  final IconData icon;
  final String title;
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
