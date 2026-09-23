import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_scope.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'ai_scope_help_page.dart';
import 'ai_scope_preview_page.dart';

/// AI 数据范围设置页：控制聊天时发送给 AI 的本机统计摘要包含哪些数据。
///
/// 页面内所有修改先落在本地草稿 [_draft]，点「确认并生效」经确认弹窗后
/// 才写入 [aiScopeProvider]（全局生效）。
class AiScopePage extends ConsumerStatefulWidget {
  const AiScopePage({super.key});

  @override
  ConsumerState<AiScopePage> createState() => _AiScopePageState();
}

class _AiScopePageState extends ConsumerState<AiScopePage>
    with XpPageScaffold<AiScopePage> {
  late AiScope _draft;

  /// 用户确认「不保存离开」后置位，放行本次 pop（避免 PopScope 二次拦截）。
  bool _leaveConfirmed = false;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(aiScopeProvider);
  }

  Future<void> _confirmSave() async {
    final ok = await confirmXpDialog(
      context,
      title: '保存设置',
      content: '确定保存当前数据范围设置？保存后将立即生效。',
      confirmLabel: '确认',
    );
    if (!ok || !mounted) return;
    await ref.read(aiScopeProvider.notifier).save(_draft);
    if (!mounted) return;
    showXpSnack(context, '已保存，新范围立即生效');
    Navigator.of(context).pop();
  }

  Future<void> _confirmReset() async {
    final ok = await confirmXpDialog(
      context,
      title: '恢复默认设置',
      content:
          '将恢复为默认模板（近6个月，资产、收支、分类全部允许；'
          '涉及隐私的标签、备注保持关闭）。',
      confirmLabel: '恢复',
    );
    if (!ok || !mounted) return;
    setState(() => _draft = AiScope.defaultScope);
    showXpSnack(context, '已恢复默认设置，点击「确认并生效」后生效');
  }

  void _openHelp() {
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => const AiScopeHelpPage()));
  }

  /// 预览：按当前草稿（临时规则，未保存）生成摘要文本。
  void _openPreview() {
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => AiScopePreviewPage(scope: _draft)));
  }

  /// 草稿与已保存范围不一致（存在未保存修改）。
  bool get _dirty => _draft != ref.read(aiScopeProvider);

  /// 尝试离开但存在未保存修改：弹窗确认是否不保存离开。
  Future<void> _confirmLeave() async {
    final leave = await confirmXpDialog(
      context,
      title: '放弃修改？',
      content: '你有未保存的修改，确定不保存就离开吗？',
      confirmLabel: '不保存离开',
      danger: true,
    );
    if (leave && mounted) {
      // 先放行再 pop，否则 PopScope（canPop=false）会再次拦截形成死循环。
      setState(() => _leaveConfirmed = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PopScope(
      canPop: !_dirty || _leaveConfirmed,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmLeave();
      },
      child: buildXpScaffold(
        appBar: AppBar(
          title: const Text('数据范围设置'),
          actions: [
            _RoundAction(
              icon: Icons.restore,
              tooltip: '恢复默认设置',
              onPressed: _confirmReset,
            ),
            _RoundAction(
              icon: Icons.check,
              tooltip: '确认并生效',
              onPressed: _confirmSave,
            ),
            const SizedBox(width: XpSpacing.s),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.s,
            XpSpacing.l,
            32,
          ),
          children: [
            Text(
              '控制发送给 AI 的统计摘要包含哪些数据，设置一次全局生效。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: XpSpacing.s),

            // ① 总开关
            XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _draft.enabled,
                    onChanged: (v) =>
                        setState(() => _draft = _draft.copyWith(enabled: v)),
                    secondary: AppIcon(
                      icon: Icons.shield_outlined,
                      color: _draft.enabled ? scheme.primary : null,
                    ),
                    title: const Text('允许 AI 读取本机财务摘要'),
                    subtitle: const Text('关闭后 AI 只能纯聊天'),
                  ),
                  if (!_draft.enabled)
                    _WarningBanner(
                      icon: Icons.warning_amber_rounded,
                      text:
                          '已关闭数据授权。AI 无法自动读取你的账单数据，'
                          '也就无法根据数据分析你的财务状况，只能进行纯聊天。',
                    ),
                ],
              ),
            ),
            const SizedBox(height: XpSpacing.s),

            // ② 介绍入口：跳转 AI 介绍页
            XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: AppIcon(
                  icon: Icons.help_outline,
                  color: scheme.primary,
                ),
                title: const Text('AI 如何读取我的数据？'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openHelp,
              ),
            ),
            const SizedBox(height: XpSpacing.s),

            // ②' 预览入口：按当前草稿规则生成摘要文本
            XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: AppIcon(
                  icon: Icons.visibility_outlined,
                  color: scheme.primary,
                ),
                title: const Text('预览统计摘要文本'),
                subtitle: const Text('查看当前设置下 AI 会看到的摘要内容'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openPreview,
              ),
            ),
            const SizedBox(height: XpSpacing.xl),

            Text(
              '数据范围',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: XpSpacing.m),

            // ③ 时间范围
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
                  const Text('时间范围'),
                  const SizedBox(height: XpSpacing.xs),
                  Text(
                    '统计摘要覆盖的时间窗口',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: XpSpacing.m),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in AiScopeRange.values)
                        ChoiceChip(
                          label: Text(r.label),
                          selected: _draft.range == r,
                          onSelected: (_) => setState(
                            () => _draft = _draft.copyWith(range: r),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: XpSpacing.s),

            // ④ 资产 / 收支 / 分类开关
            XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    value: _draft.includeAssets,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(includeAssets: v),
                    ),
                    secondary: const AppIcon(
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    title: const Text('资产情况'),
                    subtitle: const Text('账户余额与资产趋势'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _draft.includeIncomeExpense,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(includeIncomeExpense: v),
                    ),
                    secondary: const AppIcon(icon: Icons.swap_vert),
                    title: const Text('收支情况'),
                    subtitle: const Text('收支汇总、按月趋势与预算执行'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _draft.includeCategories,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(includeCategories: v),
                    ),
                    secondary: const AppIcon(icon: Icons.pie_chart_outline),
                    title: const Text('分类 Top N'),
                    subtitle: const Text('支出 / 收入分类金额排行'),
                  ),
                  if (_draft.includeCategories)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        XpSpacing.l,
                        XpSpacing.xs,
                        XpSpacing.l,
                        XpSpacing.m,
                      ),
                      child: Row(
                        children: [
                          Text('排行数量', style: theme.textTheme.bodyMedium),
                          const Spacer(),
                          for (final n in const [10, 20])
                            Padding(
                              padding: EdgeInsets.only(
                                left: n == 10 ? 0 : XpSpacing.s,
                              ),
                              child: ChoiceChip(
                                label: Text('Top $n'),
                                selected: _draft.categoryTopN == n,
                                onSelected: (_) => setState(
                                  () =>
                                      _draft = _draft.copyWith(categoryTopN: n),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: XpSpacing.s),

            // ⑤ 可能敏感的数据类型（涉及隐私，默认关闭）
            XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      XpSpacing.l,
                      XpSpacing.m,
                      XpSpacing.l,
                      XpSpacing.s,
                    ),
                    child: Text(
                      '可能敏感的数据类型',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _WarningBanner(
                    icon: Icons.warning_amber_rounded,
                    text:
                        '以下数据更贴近消费明细、涉及隐私，'
                        '请确认你信任当前配置的 AI 服务商后再开启。',
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _draft.includeTags,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(includeTags: v),
                    ),
                    secondary: const AppIcon(icon: Icons.sell_outlined),
                    title: const Text('标签'),
                    subtitle: const Text('账单标签的金额排行'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _draft.includeRemarks,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(includeRemarks: v),
                    ),
                    secondary: const AppIcon(icon: Icons.notes_outlined),
                    title: const Text('备注'),
                    subtitle: const Text('账单备注文本的金额排行'),
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

/// 标题栏右上角圆形操作按钮：固定白色圆形背景 + 主题色图标。
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: 20,
            tooltip: tooltip,
            icon: Icon(icon, color: scheme.primary),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// 警示条：总开关关闭时提示 AI 无法自动分析。
class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        0,
        XpSpacing.l,
        XpSpacing.m,
      ),
      padding: const EdgeInsets.all(XpSpacing.m),
      decoration: BoxDecoration(
        color: XpSemanticColors.warning.withValues(alpha: 0.12),
        borderRadius: XpRadius.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon: icon, size: 20, color: XpSemanticColors.warning),
          const SizedBox(width: XpSpacing.s),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: XpSemanticColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
