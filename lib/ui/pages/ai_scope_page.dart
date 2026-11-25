import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/ai/ai_analysis_context.dart';
import '../../domain/ai/ai_scope.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/ai_mode_banner.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_button.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_sliding_segmented.dart';
import '../widgets/xp_snack.dart';
import 'ai_analysis_preview_page.dart';
import 'ai_analysis_privacy_page.dart';
import 'ai_scope_help_page.dart';
import 'ai_scope_preview_page.dart';

/// AI 数据范围设置页：控制聊天时发送给 AI 的本机数据。
///
/// 两种模式二选一：
/// - 标准（默认）：只发聚合统计摘要，低隐私；
/// - 详细：发逐笔明细 JSON，隐私等级高，首次切换需确认须知。
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

  /// 详细模式的体积统计（草稿范围实时计算）。
  AiAnalysisData? _volume;
  bool _volumeLoading = false;
  int _volumeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(aiScopeProvider);
    if (_draft.isDetail) _loadVolume();
  }

  Future<void> _loadVolume() async {
    if (!_draft.isDetail) return;
    final id = ++_volumeRequestId;
    setState(() => _volumeLoading = true);
    try {
      final (start, end) = _draft.resolveDetailRange(DateTime.now());
      final data = await AiAnalysisContext(ref).build(
        start: start,
        end: end,
        includeNotes: _draft.detailIncludeNotes,
      );
      if (!mounted || id != _volumeRequestId) return;
      setState(() {
        _volume = data;
        _volumeLoading = false;
      });
    } catch (_) {
      if (!mounted || id != _volumeRequestId) return;
      setState(() => _volumeLoading = false);
    }
  }

  Future<void> _confirmSave() async {
    if (_draft.isDetail && _volumeLoading) {
      showXpSnack(context, '正在统计范围内账单，请稍候再保存');
      return;
    }
    if (_draft.isDetail && (_volume == null || _volume!.overLimit)) {
      showXpSnack(context, '当前范围超过单次发送上限，请先缩小范围', error: true);
      return;
    }
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
          '将恢复为默认模板（标准模式、近6个月，资产、收支、分类全部允许；'
          '涉及隐私的标签、备注保持关闭）。',
      confirmLabel: '恢复',
    );
    if (!ok || !mounted) return;
    setState(() {
      _draft = AiScope.defaultScope;
      _volume = null;
    });
    showXpSnack(context, '已恢复默认设置，点击「确认并生效」后生效');
  }

  void _openHelp() {
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => const AiScopeHelpPage()));
  }

  void _openPrivacy() {
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => const AiAnalysisPrivacyPage()));
  }

  /// 预览：按当前草稿（临时规则，未保存）生成内容。
  void _openPreview() {
    if (_draft.isDetail) {
      final data = _volume;
      if (data == null || data.estimated) return;
      Navigator.of(
        context,
      ).push(XpRoute(builder: (_) => AiAnalysisPreviewPage(data: data)));
      return;
    }
    Navigator.of(
      context,
    ).push(XpRoute(builder: (_) => AiScopePreviewPage(scope: _draft)));
  }

  Future<void> _onModeChanged(AiDataMode next) async {
    if (next == _draft.mode) return;
    if (next == AiDataMode.detail && !_draft.detailPrivacyAcked) {
      final ok = await confirmXpDialog(
        context,
        title: '详细模式会把每一笔账单发给 AI',
        content:
            '· 包括时间、金额、分类、账户\n'
            '· 备注默认不发送\n'
            '· 数据只发给你自己配置的服务商\n\n'
            '详细说明见本页顶部提示条。',
        confirmLabel: '我已知晓',
        cancelLabel: '返回',
      );
      if (!ok || !mounted) return;
      setState(() {
        _draft = _draft.copyWith(
          mode: next,
          detailPrivacyAcked: true,
        );
      });
    } else {
      setState(() => _draft = _draft.copyWith(mode: next));
    }
    if (next == AiDataMode.detail) await _loadVolume();
  }

  Future<void> _pickDetailRange() async {
    final now = DateTime.now();
    final picked = await showXpDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRangeStart: _draft.detailCustomStart == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_draft.detailCustomStart!),
      initialDateRangeEnd: _draft.detailCustomEnd == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(_draft.detailCustomEnd!),
      helpText: '选择要分析的时间范围',
      saveText: '确定',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _draft = _draft.copyWith(
        detailRange: AiAnalysisRange.custom,
        detailCustomStart: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ).millisecondsSinceEpoch,
        detailCustomEnd: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
        ).millisecondsSinceEpoch,
      );
    });
    await _loadVolume();
  }

  /// 详细模式超限时向后收缩到能装下的最长区间。
  Future<void> _shrinkRange() async {
    final data = _volume;
    if (data == null) return;
    final start = await AiAnalysisContext(
      ref,
    ).suggestStart(data.start, data.end);
    if (!mounted) return;
    if (start == null) {
      showXpSnack(context, '没有找到足够小的可用区间，请手动选择更短的范围', error: true);
      return;
    }
    final endDay = DateTime.fromMillisecondsSinceEpoch(data.end - 1);
    setState(() {
      _draft = _draft.copyWith(
        detailRange: AiAnalysisRange.custom,
        detailCustomStart: start,
        detailCustomEnd: DateTime(
          endDay.year,
          endDay.month,
          endDay.day,
        ).millisecondsSinceEpoch,
      );
    });
    await _loadVolume();
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
        buildBody: (_) => ListView(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.s,
            XpSpacing.l,
            32,
          ),
          children: [
            // ① 模式切换（互斥二选一，用滑块切换器）
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: XpSlidingSegmented<AiDataMode>(
                  items: const [
                    XpSegmentedItem(
                      value: AiDataMode.summary,
                      label: '标准',
                      icon: Icons.summarize_outlined,
                    ),
                    XpSegmentedItem(
                      value: AiDataMode.detail,
                      label: '详细',
                      icon: Icons.list_alt_outlined,
                    ),
                  ],
                  selected: _draft.mode,
                  onChanged: _onModeChanged,
                ),
              ),
            ),
            const SizedBox(height: XpSpacing.s),
            Center(
              child: Text(
                _draft.isDetail
                    ? '详细模式：把范围内每一笔账单发给 AI'
                    : '标准模式：只发聚合统计摘要，不含单笔明细',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: XpSpacing.l),
            if (_draft.isDetail)
              ..._buildDetailSections(theme, scheme)
            else
              ..._buildSummarySections(theme, scheme),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── 详细模式 ─────────────────────────

  List<Widget> _buildDetailSections(ThemeData theme, ColorScheme scheme) {
    final data = _volume;
    return [
      AiModeBanner(
        modeLabel: '详细',
        warning: true,
        description: '每一笔账单都会发给 AI，点击查看数据边界与脱敏规则',
        onTap: _openPrivacy,
      ),
      const SizedBox(height: XpSpacing.m),
      _sectionLabel('数据范围'),
      const SizedBox(height: XpSpacing.s),
      XpCard(
        padding: const EdgeInsets.all(XpSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in AiAnalysisRange.values)
                  ChoiceChip(
                    label: Text(r.label),
                    selected: _draft.detailRange == r,
                    onSelected: (_) {
                      if (r == AiAnalysisRange.custom) {
                        _pickDetailRange();
                      } else {
                        setState(
                          () => _draft = _draft.copyWith(detailRange: r),
                        );
                        _loadVolume();
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: XpSpacing.m),
            Text(
              data == null
                  ? '统计中…'
                  : '${_formatDate(data.start)} ~ ${_formatDate(data.end - 1)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: XpSpacing.xs),
            if (_volumeLoading)
              Text(
                '正在统计…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              )
            else if (data != null)
              _VolumeLine(data: data),
          ],
        ),
      ),
      const SizedBox(height: XpSpacing.m),
      _sectionLabel('发送内容'),
      const SizedBox(height: XpSpacing.s),
      XpCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          value: _draft.detailIncludeNotes,
          onChanged: (v) {
            setState(
              () => _draft = _draft.copyWith(detailIncludeNotes: v),
            );
            _loadVolume();
          },
          secondary: const AppIcon(icon: Icons.notes_outlined),
          title: const Text('附带备注'),
          subtitle: const Text('备注会先做本地脱敏（手机号/卡号/邮箱 → ***）'),
        ),
      ),
      const SizedBox(height: XpSpacing.m),
      XpCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: AppIcon(icon: Icons.data_object, color: scheme.primary),
          title: const Text('预览将发送的 JSON'),
          subtitle: Text(
            data == null || data.estimated
                ? '当前范围过大，无法预览'
                : '共 ${data.count} 条记录',
          ),
          trailing: const Icon(Icons.chevron_right),
          enabled: data != null && !data.estimated,
          onTap: _openPreview,
        ),
      ),
      if (data != null && data.overLimit) ...[
        const SizedBox(height: XpSpacing.m),
        _OverLimitCard(
          data: data,
          onShrink: _shrinkRange,
          onThisMonth: () {
            setState(
              () => _draft = _draft.copyWith(
                detailRange: AiAnalysisRange.thisMonth,
              ),
            );
            _loadVolume();
          },
        ),
      ],
    ];
  }

  // ───────────────────────── 标准模式 ─────────────────────────

  List<Widget> _buildSummarySections(ThemeData theme, ColorScheme scheme) {
    return [
      // 总开关
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

      // 介绍入口
      XpCard(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: AppIcon(icon: Icons.help_outline, color: scheme.primary),
          title: const Text('AI 如何读取我的数据？'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openHelp,
        ),
      ),
      const SizedBox(height: XpSpacing.s),

      // 预览入口
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

      // 时间范围
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

      // 资产 / 收支 / 分类开关
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
                            () => _draft = _draft.copyWith(categoryTopN: n),
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

      // 可能敏感的数据类型
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
    ];
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

/// 体量一行：条数 / 字节 / token 估算（黄红两档）。
class _VolumeLine extends StatelessWidget {
  const _VolumeLine({required this.data});

  final AiAnalysisData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = data.overLimit
        ? scheme.error
        : (data.warn ? XpSemanticColors.warning : scheme.onSurfaceVariant);
    return Text(
      '${data.count} 笔 · ${_fmtBytes(data.bytes)} · ≈${_fmtTokens(data)} tokens'
      '${data.estimated ? '（估算）' : ''}',
      style: theme.textTheme.bodySmall?.copyWith(color: color),
    );
  }
}

/// 超限提示卡：给出缩小范围的两个快捷动作。
class _OverLimitCard extends StatelessWidget {
  const _OverLimitCard({
    required this.data,
    required this.onShrink,
    required this.onThisMonth,
  });

  final AiAnalysisData data;
  final VoidCallback onShrink;
  final VoidCallback onThisMonth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return XpCard(
      padding: const EdgeInsets.all(XpSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: scheme.error),
              const SizedBox(width: XpSpacing.xs),
              Text(
                '范围过大',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: XpSpacing.xs),
          Text(
            '单次最多发送 $kAiAnalysisMaxCount 笔、'
            '${_fmtBytes(kAiAnalysisMaxBytes)}。'
            '当前 ${data.count} 笔，请缩小范围。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: XpSpacing.m),
          Row(
            children: [
              Expanded(
                child: XpButton(
                  onPressed: onShrink,
                  expand: true,
                  child: const Text('自动缩小'),
                ),
              ),
              const SizedBox(width: XpSpacing.s),
              Expanded(
                child: XpButton(
                  onPressed: onThisMonth,
                  expand: true,
                  child: const Text('改用本月'),
                ),
              ),
            ],
          ),
        ],
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
            icon: AppIcon(icon: icon, size: 20, color: scheme.primary),
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

String _formatDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.year}/${d.month}/${d.day}';
}

String _fmtBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
}

String _fmtTokens(AiAnalysisData data) {
  final t = data.tokens;
  if (t < 1000) return '$t';
  return '${(t / 1000).toStringAsFixed(1)}k';
}
