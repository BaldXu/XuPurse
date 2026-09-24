import 'package:flutter/material.dart';

import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';

/// 加密备份介绍页：加密有什么用 / 算法原理 / 丢密码后果 / 使用建议。
class EncryptionHelpPage extends StatefulWidget {
  const EncryptionHelpPage({super.key});

  @override
  State<EncryptionHelpPage> createState() => _EncryptionHelpPageState();
}

class _EncryptionHelpPageState extends State<EncryptionHelpPage>
    with XpPageScaffold<EncryptionHelpPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('加密备份有什么用？')),
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
            '开启加密后，备份文件会先用你设置的密码加密再保存。'
            '下面是加密能做什么、它的原理，以及必须记住的注意事项。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          const _SectionCard(
            icon: Icons.lock_outline,
            title: '加密有什么用',
            points: [
              '备份文件包含你的全部账单、账户、分类和设置，属于敏感数据',
              '不加密时它是一段明文 JSON，谁拿到文件都能直接打开查看',
              '加密后内容全部变成密文：文件泄露（传到网盘、误发给别人、'
                  '手机丢失）也不用担心，没有密码什么都看不到',
            ],
          ),
          const SizedBox(height: XpSpacing.l),
          const _SectionCard(
            icon: Icons.psychology_outlined,
            title: '加密原理',
            points: [
              '密码经 Argon2id 算法派生出 256 位密钥——密钥只在加密过程'
                  '内存中使用，用完即弃，从不写入磁盘',
              '数据用 AES-256-GCM 认证加密：只有持有正确密码才能解开，'
                  '文件被改动也会被立刻识别',
              '每次备份都会随机生成盐和随机数，同一密码导出的两份备份'
                  '密文也完全不同，无法靠比对猜测内容',
            ],
          ),
          const SizedBox(height: XpSpacing.l),
          const _SectionCard(
            icon: Icons.report_gmailerrorred_outlined,
            title: '丢失密码会怎样',
            points: [
              '密码不会保存在任何地方，也不会上传服务器，没有找回或'
                  '重置渠道',
              '忘记密码 = 这份备份永久无法解密，里面的数据无法找回',
              '恢复备份时必须输入同一个密码，记错一样无法恢复',
            ],
          ),
          const SizedBox(height: XpSpacing.l),
          const _SectionCard(
            icon: Icons.timer_outlined,
            title: '对速度的影响',
            points: [
              '加密和解密都需要额外计算，备份与恢复会比不加密慢几秒，'
                  '属正常现象',
              '文件越大、密码派生耗时越长，耐心等待即可，请勿中途退出',
            ],
          ),
          const SizedBox(height: XpSpacing.l),
          const _SectionCard(
            icon: Icons.tips_and_updates_outlined,
            title: '使用建议',
            points: [
              '密码至少 8 位，建议 12 位以上并混合大小写字母、数字和符号',
              '建议用密码管理器保存密码；不要与银行卡、支付密码等混用',
            ],
          ),
        ],
      ),
    );
  }
}

/// 说明卡片：图标 + 标题 + 要点列表（复用 AI 介绍页卡片范式）。
class _SectionCard extends StatelessWidget {
  const _SectionCard({
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
