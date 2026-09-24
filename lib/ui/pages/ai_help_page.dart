import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';

/// AI 介绍页：怎么配置 AI + 现有功能逐项介绍（纯文本卡片排版）。
class AiHelpPage extends StatefulWidget {
  const AiHelpPage({super.key});

  @override
  State<AiHelpPage> createState() => _AiHelpPageState();
}

class _AiHelpPageState extends State<AiHelpPage>
    with XpPageScaffold<AiHelpPage> {
  /// 配置步骤文案。
  static const _steps = <String>[
    '进入「我的」→「AI 设置」',
    '点「新增配置」，选择协议：OpenAI 兼容 / Anthropic 兼容',
    '填写服务商提供的 Base URL（接口地址）',
    '粘贴 API Key（在服务商后台创建）',
    '填写模型名称 model，如 deepseek-chat / claude-sonnet-4-5',
    '点「测试连接」验证可用，再点「保存」',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('配置AI有什么用？')),
      // 转场期间只渲染骨架（buildBody 门）：整页多张要点卡片，首帧全量
      // 构建会与转场动画抢帧；completed 后首次构建真实内容。
      buildBody: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          Text(
            '接入 AI 后，账本的查账、算账可以交给 AI 代劳。'
            '下面是接入方法、已经支持的功能，以及它的能力边界。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          Text(
            '怎么配置 AI',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          XpCard(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.m,
              XpSpacing.l,
              XpSpacing.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  _stepRow(
                    context,
                    i + 1,
                    _steps[i],
                    isLast: i == _steps.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: XpSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.xs),
            child: Text(
              '提示：多数国内服务（DeepSeek、火山方舟等）都兼容 OpenAI 协议，'
              '直接选「OpenAI 兼容」即可。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          Text(
            'AI 能帮你做什么',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          const _FeatureCard(
            icon: Icons.smart_toy_outlined,
            title: '统计页 AI 助手',
            where: '入口：底部导航「统计」→ 右下角 AI 悬浮按钮',
            points: [
              '基于你本机的账单自动生成统计摘要，随问随答：这个月花了多少、'
                  '哪类支出最多、和上个月比涨了还是跌了',
              '内置隐私规则，只基于摘要作答，不会向你索要手机号等敏感信息',
            ],
          ),
          const SizedBox(height: XpSpacing.xl),
          Text(
            'AI 的局限',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          const _FeatureCard(
            icon: Icons.info_outline,
            title: '不会联网，拿不到实时信息',
            points: [
              '本 App 只调用 AI 的「对话接口」：把账本摘要发过去，把回答取回来，'
                  '除此之外不会为它开启任何额外能力',
              '各家服务商的联网搜索 / 工具调用（OpenAI、Anthropic、DeepSeek、'
                  '火山方舟等）参数名、返回格式、开关方式都不一样，没有通用做法；'
                  '逐个适配并长期维护成本太高，本 App 不做这件事',
              '所以 AI 只能凭训练时记住的知识作答。遇到实时数据类问题'
                  '（最新汇率、今日股价、新闻、天气），它给出的答案可能过时'
                  '甚至是错的，而且语气往往很肯定',
              '这跟你的配置无关：换任何服务商、任何模型都一样，'
                  '只要请求里不带工具参数，就没有哪家会自动联网',
            ],
          ),
          const SizedBox(height: XpSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.xs),
            child: Text(
              '因此凡是需要实时数据的功能（例如汇率更新），本 App 都改为'
              '直连公开数据源，不经过 AI。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 编号步骤行：圆形序号徽标 + 步骤文案。
  Widget _stepRow(
    BuildContext context,
    int n,
    String text, {
    required bool isLast,
  }) {
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

/// 功能卡片：图标 + 标题 + 使用入口 + 说明点。
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    this.where,
    required this.points,
  });

  final IconData icon;
  final String title;

  /// 使用入口；能力说明类卡片无入口，传 null。
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
