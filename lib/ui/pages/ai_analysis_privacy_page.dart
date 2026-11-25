import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';

/// AI 分析的隐私与数据边界说明页（由 AI 分析页顶部警示条进入）。
class AiAnalysisPrivacyPage extends StatefulWidget {
  const AiAnalysisPrivacyPage({super.key});

  @override
  State<AiAnalysisPrivacyPage> createState() => _AiAnalysisPrivacyPageState();
}

class _AiAnalysisPrivacyPageState extends State<AiAnalysisPrivacyPage>
    with XpPageScaffold<AiAnalysisPrivacyPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('数据边界')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          Text(
            'AI 分析和统计页的 AI 助手不是一回事：那边发的是汇总数字，'
            '这边发的是每一笔账单。请先看完下面的说明再使用。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          _Section(
            icon: Icons.send_outlined,
            title: '会发送什么',
            lines: const [
              '每笔账单的时间、金额、收支类型',
              '分类（一级/叶子）与账户名称',
              '备注 —— 默认关闭，开启后先做本地脱敏',
              '所选时间范围内的全部账单条数',
            ],
          ),
          _Section(
            icon: Icons.block_outlined,
            title: '不会发送什么',
            lines: const [
              '账单 ID、创建时间、修改时间',
              '记账时的地理位置、图片',
              '账户余额与资产总值',
              '其他账本的数据',
            ],
          ),
          _Section(
            icon: Icons.cloud_outlined,
            title: '发到哪里',
            lines: const [
              '只发送到你自己在「AI 设置」里填写的接口地址',
              'XuPurse 不中转、不收集、不上传任何数据',
              '但该服务商是否留存、如何使用，由其自身政策决定',
              '如果你填的是第三方中转站，请确认你信任它',
            ],
          ),
          _Section(
            icon: Icons.security_outlined,
            title: '本地做了哪些保护',
            lines: const [
              '备注中的手机号、身份证、银行卡、邮箱、6 位以上数字会替换为 ***',
              '超过 60 字的备注会被截断',
              '明细只用于当次对话，不写入本地对话记录',
              '单次最多发送 600 笔 / 64 KB，超限会要求缩小范围',
            ],
          ),
          _Section(
            icon: Icons.tune_outlined,
            title: '你能怎么控制',
            lines: const [
              '时间范围越小，暴露的信息越少（默认本月）',
              '备注默认不发送，需要时再开',
              '随时可以在「AI 设置」里删除该接口配置',
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.lines,
  });

  final IconData icon;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: XpSpacing.m),
      child: XpCard(
        padding: const EdgeInsets.all(XpSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(icon: icon, size: 20, color: scheme.primary),
                const SizedBox(width: XpSpacing.s),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: XpSpacing.s),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '· ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
