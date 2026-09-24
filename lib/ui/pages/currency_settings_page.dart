import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/currency_service.dart';
import '../../domain/services/exchange_rate_service.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import '../tokens/design_tokens.dart';

/// 汇率设置页：列出内置币种汇率，可手动覆盖（1 单位外币 = X 本位币）。
class CurrencySettingsPage extends ConsumerStatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  ConsumerState<CurrencySettingsPage> createState() =>
      _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends ConsumerState<CurrencySettingsPage>
    with XpPageScaffold<CurrencySettingsPage> {
  /// 一键更新汇率进行中标志。
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final rates = ref.watch(currencyServiceProvider);
    final service = ref.watch(currencyServiceProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return buildXpScaffold(
      appBar: AppBar(title: const Text('汇率设置')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(XpSpacing.l),
            child: Text(
              '本位币为总资产折算的目标币种；汇率为 1 单位外币折合本位币（CNY）的数量。'
              '修改后总资产将按新汇率折算。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            child: XpCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本位币', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: XpSpacing.s),
                  ref
                      .watch(baseCurrencyProvider)
                      .when(
                        loading: () => const LinearProgressIndicator(),
                        // 卡内 inline 小错误，非页面级场景，保留轻量 Text。
                        error: (e, _) => Text('加载失败：$e'),
                        data: (base) => DropdownButtonFormField<String>(
                          key: ValueKey(base),
                          initialValue: base,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            for (final code in CurrencyService.supportedCodes)
                              DropdownMenuItem<String>(
                                value: code,
                                child: Text(code),
                              ),
                          ],
                          onChanged: (v) async {
                            if (v == null || v == base) return;
                            final mgr = ref.read(databaseManagerProvider);
                            final bookId = mgr.currentBookId;
                            if (bookId == null || !context.mounted) return;
                            await mgr.updateBookBaseCurrency(bookId, v);
                            ref.invalidate(baseCurrencyProvider);
                            if (context.mounted) {
                              showXpSnack(context, '本位币已切换为 $v');
                            }
                          },
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: XpSpacing.l),
          // ── 一键更新汇率入口（走公开汇率源，不依赖 AI 配置）──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            child: XpCard(
              onTap: _updating ? null : _startUpdate,
              child: Padding(
                padding: const EdgeInsets.all(XpSpacing.l),
                child: Row(
                  children: [
                    AppIcon(
                      icon: Icons.sync,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: XpSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('一键更新汇率', style: textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(
                            '从公开汇率源获取最新汇率，确认后写入',
                            style: textTheme.bodySmall?.copyWith(
                              color: textTheme.bodySmall?.color?.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _lastUpdatedLabel(
                              ref.watch(rateLastUpdatedProvider),
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: textTheme.bodySmall?.color?.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_updating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        color: textTheme.bodySmall?.color?.withValues(
                          alpha: 0.5,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: XpSpacing.l),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            child: XpCard(
              padding: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (
                    var i = 0;
                    i < CurrencyService.supportedCodes.length;
                    i++
                  ) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 56,
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          CurrencyService.supportedCodes[i].substring(0, 1),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                      title: Text(CurrencyService.supportedCodes[i]),
                      subtitle: Text(
                        service.isOverridden(CurrencyService.supportedCodes[i])
                            ? '手动覆盖：1 ${CurrencyService.supportedCodes[i]} = ${_fmt(rates[CurrencyService.supportedCodes[i]])} CNY'
                            : '内置：1 ${CurrencyService.supportedCodes[i]} = ${_fmt(rates[CurrencyService.supportedCodes[i]])} CNY',
                        style: TextStyle(
                          color:
                              service.isOverridden(
                                CurrencyService.supportedCodes[i],
                              )
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: const Icon(Icons.edit_outlined, size: 18),
                      onTap: () => _edit(
                        context,
                        ref,
                        CurrencyService.supportedCodes[i],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 点击「一键更新汇率」：拉取公开汇率源 → 失败弹错误弹窗 → 成功弹预览对比，
  /// 用户确认后才逐个写入汇率配置，并记录「上次更新时间」。
  Future<void> _startUpdate() async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final rates = await fetchRates();
      if (!mounted) return;
      // 预览对比：修改前后汇率 + 涨跌幅，用户确认才写入。
      final confirmed = await _showRatePreviewDialog(rates);
      if (!confirmed || !mounted) return;
      final service = ref.read(currencyServiceProvider.notifier);
      var updated = 0;
      for (final e in rates.entries) {
        await service.setOverride(e.key, e.value);
        updated++;
      }
      // 仅在用户确认且写入成功后记录生效时间。
      await ref.read(rateLastUpdatedProvider.notifier).markNow();
      if (mounted) {
        showXpSnack(context, '已更新 $updated 种货币汇率');
      }
    } on RateFetchException catch (e) {
      if (mounted) {
        await _showErrorDialog(e.message);
      }
    } catch (e) {
      if (mounted) {
        await _showErrorDialog('更新汇率时发生未知错误：$e');
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// 「上次更新时间」展示文案；区分首次读取中与从未更新过。
  String _lastUpdatedLabel(AsyncValue<DateTime?> v) {
    final t = v.value;
    if (t != null) {
      String p(int n) => n.toString().padLeft(2, '0');
      return '上次更新：${t.year}-${p(t.month)}-${p(t.day)} '
          '${p(t.hour)}:${p(t.minute)}';
    }
    return v.isLoading ? '上次更新：读取中…' : '上次更新：尚未更新过';
  }

  /// 错误弹窗：展示失败原因，由用户自行排查。
  Future<void> _showErrorDialog(String message) {
    return showXpDialog<void>(
      context: context,
      title: '更新汇率失败',
      content: message,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    );
  }

  /// 预览弹窗：逐行展示 币种 | 当前汇率 → 新汇率 | 变化。确认后返回 true。
  Future<bool> _showRatePreviewDialog(Map<String, double> newRates) {
    final service = ref.read(currencyServiceProvider.notifier);
    final currentRates = {for (final c in newRates.keys) c: service.rateOf(c)};
    return showXpDialog<bool>(
      context: context,
      title: '确认更新汇率',
      contentWidget: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final code in newRates.keys)
              _RateDiffRow(
                code: code,
                oldRate: currentRates[code]!,
                newRate: newRates[code]!,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确认更新'),
        ),
      ],
    ).then((v) => v ?? false);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String code) async {
    final service = ref.read(currencyServiceProvider.notifier);
    final current = service.rateOf(code);
    final ctrl = TextEditingController(text: _fmt(current));
    final action = await showXpDialog<String>(
      context: context,
      title: '设置 $code 汇率',
      contentWidget: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: '1 $code = ? CNY',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        if (service.isOverridden(code))
          TextButton(
            onPressed: () => Navigator.pop(context, '__reset__'),
            child: const Text('恢复内置'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ctrl.text),
          child: const Text('保存'),
        ),
      ],
    );
    ctrl.dispose();
    if (action == null || !context.mounted) return;
    if (action == '__reset__') {
      await service.setOverride(code, 0);
      return;
    }
    final v = double.tryParse(action.trim());
    if (v == null || v <= 0) {
      if (context.mounted) {
        showXpSnack(context, '请输入有效汇率', error: true);
      }
      return;
    }
    await service.setOverride(code, v);
  }

  String _fmt(double? v) {
    final d = v ?? 1.0;
    return d == d.roundToDouble() ? d.toStringAsFixed(0) : d.toStringAsFixed(4);
  }
}

/// 预览弹窗中的单行：币种 | 旧汇率 → 新汇率 | 变化幅度。
class _RateDiffRow extends StatelessWidget {
  const _RateDiffRow({
    required this.code,
    required this.oldRate,
    required this.newRate,
  });

  final String code;
  final double oldRate;
  final double newRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = newRate - oldRate;
    final up = diff >= 0;
    final diffLabel = diff == 0
        ? '持平'
        : '${up ? '↑' : '↓'} ${_fmt(diff.abs())}'
              '（${up ? '+' : '-'}${((diff.abs() / oldRate) * 100).toStringAsFixed(2)}%）';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: XpSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(code, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: Text(
              '${_fmt(oldRate)} → ${_fmt(newRate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            diffLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: diff == 0
                  ? theme.colorScheme.onSurfaceVariant
                  : up
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(4);
  }
}
