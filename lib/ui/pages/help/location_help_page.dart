import 'package:flutter/material.dart';

import '../../layout/xp_page_scaffold_mixin.dart';
import '../../tokens/design_tokens.dart';
import 'help_widgets.dart';

/// 说明页：账单位置（定位）的原理、精度与权限取舍。
///
/// 内容口径来自 `domain/services/location_service.dart`（IP 定位 +
/// 10 分钟缓存 + 失败切换服务商）与 `state/location_auto_provider.dart`
/// （默认关闭）。改定位实现时同步更新本页文案。
class LocationHelpPage extends StatefulWidget {
  const LocationHelpPage({super.key});

  @override
  State<LocationHelpPage> createState() => _LocationHelpPageState();
}

class _LocationHelpPageState extends State<LocationHelpPage>
    with XpPageScaffold<LocationHelpPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('账单位置（定位）')),
      buildBody: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          Text(
            '记账页的「位置」不是 GPS 定位，而是通过 IP 地址估算的城市。'
            '这里说明它的原理、精度，以及为什么全程不申请定位权限。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.xl),
          const HelpSectionTitle('它是怎么定位的'),
          const SizedBox(height: XpSpacing.m),
          const HelpPointCard(
            icon: Icons.language,
            title: '通过 IP 地址查询城市',
            points: [
              '进入「新增明细」且开启了自动识别时，App 会向 IP 归属地服务查询当前网络出口的城市，'
                  '先试 ipwho.is，失败自动切换 ipapi.co。',
              '拿到的结果是「国家 + 城市」，例如「中国-深圳」；附带坐标只是 IP 数据库里的'
                  '城市中心点，不能当成你站的位置。',
              '结果在本机缓存 10 分钟，避免频繁进出记账页时反复请求；不会在后台定时定位。',
              '查询失败时会提示「位置获取失败」，你仍可以在记账页「位置」行手动输入地点。',
            ],
          ),
          const SizedBox(height: XpSpacing.xs),
          const HelpNote(
            '自动识别默认关闭，只有你在「设置 → 记账自动识别位置」手动打开后，才会发起查询。',
          ),
          const SizedBox(height: XpSpacing.xl),
          const HelpSectionTitle('为什么精度只到城市，不能更准'),
          const SizedBox(height: XpSpacing.m),
          const HelpPointCard(
            icon: Icons.adjust,
            title: '没有购买商用定位服务',
            points: [
              '高德、百度等地图厂商的高精度定位 SDK（GPS / 基站 / Wi-Fi 混合定位）需要付费授权。'
                  '这是个人开发项目，没有购买这类服务，所以没有接入。',
              '退而求其次用免费的 IP 定位：只能判断你联网的出口城市，精度天生就是城市级。',
              '同一宽带下的所有设备会得到同一个城市；用 VPN / 代理，或运营商跨省出口时，'
                  '还可能落到别的城市。',
              '所以这里显示的是「大致城市」，不精确到街道、店铺，也不会用来判断你具体在哪消费。',
            ],
          ),
          const SizedBox(height: XpSpacing.xl),
          const HelpSectionTitle('为什么不申请定位权限'),
          const SizedBox(height: XpSpacing.m),
          const HelpPointCard(
            icon: Icons.lock_outline,
            title: '全程不碰系统定位权限',
            points: [
              '不申请任何定位权限：Android / iOS 都不会弹出权限框，也不读取 GPS、基站或 Wi-Fi 位置信息。',
              '好处是不需要授权、不在后台耗电，App 也拿不到你的精确位置；代价就是精度只有城市级。',
              '只有 IP 查询这一步会联网：把设备当前 IP 发给上面提到的第三方服务换取城市。'
                  '本项目没有自己的服务器，位置只写进本机账本。',
              'AI 助手不接收位置：统计摘要里没有地点，逐笔明细 JSON 也刻意不含坐标。',
            ],
          ),
          const SizedBox(height: XpSpacing.xs),
          const HelpNote(
            '想关闭或重新打开：我的 → 设置 → 记账自动识别位置。'
            '关闭后仍可在记账页「位置」行手动输入地点。',
          ),
        ],
      ),
    );
  }
}
