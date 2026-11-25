import 'package:flutter/material.dart';

import '../../layout/xp_page_scaffold_mixin.dart';
import '../../tokens/design_tokens.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_param_row.dart';
import 'help_topics.dart';

/// 说明列表页（我的 → 关于 → 说明）。
///
/// 条目全部来自 [helpTopics] 登记表：本页不写死标题、副标题和跳转目标，
/// 新增一条说明只需要改 help_topics.dart。
class HelpIndexPage extends StatefulWidget {
  const HelpIndexPage({super.key});

  @override
  State<HelpIndexPage> createState() => _HelpIndexPageState();
}

class _HelpIndexPageState extends State<HelpIndexPage>
    with XpPageScaffold<HelpIndexPage> {
  @override
  Widget build(BuildContext context) {
    return buildXpScaffold(
      appBar: AppBar(title: const Text('说明')),
      buildBody: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          32,
        ),
        children: [
          XpCard(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < helpTopics.length; i++) ...[
                  if (i > 0)
                    const XpParamDivider(
                      indent: kXpParamDividerIndentWithLeading,
                    ),
                  XpParamRow(
                    leadingIcon: helpTopics[i].icon,
                    label: helpTopics[i].title,
                    subtitle: helpTopics[i].subtitle,
                    onTap: () => _open(context, helpTopics[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, HelpTopic topic) {
    Navigator.of(context).push(XpRoute(builder: (_) => topic.buildPage()));
  }
}
