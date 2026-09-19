import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/currency_service.dart';
import '../../state/providers.dart';
import '../layout/breakpoints.dart';

/// 汇率设置页：列出内置币种汇率，可手动覆盖（1 单位外币 = X 本位币）。
class CurrencySettingsPage extends ConsumerWidget {
  const CurrencySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(currencyServiceProvider);
    final service = ref.watch(currencyServiceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('汇率设置')),
      body: ContentWidthBox(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '本位币为总资产折算的目标币种；汇率为 1 单位外币折合本位币（CNY）的数量。'
                '修改后总资产将按新汇率折算。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本位币',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ref
                          .watch(baseCurrencyProvider)
                          .when(
                            loading: () => const LinearProgressIndicator(),
                            error: (e, _) => Text('加载失败：$e'),
                            data: (base) => DropdownButtonFormField<String>(
                              key: ValueKey(base),
                              initialValue: base,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                for (final code
                                    in CurrencyService.supportedCodes)
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('本位币已切换为 $v')),
                                  );
                                }
                              },
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final code in CurrencyService.supportedCodes)
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(code.substring(0, 1)),
                ),
                title: Text(code),
                subtitle: Text(
                  service.isOverridden(code)
                      ? '手动覆盖：1 $code = ${_fmt(rates[code])} CNY'
                      : '内置：1 $code = ${_fmt(rates[code])} CNY',
                  style: TextStyle(
                    color: service.isOverridden(code)
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () => _edit(context, ref, code),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String code) async {
    final service = ref.read(currencyServiceProvider.notifier);
    final current = service.rateOf(code);
    final ctrl = TextEditingController(text: _fmt(current));
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('设置 $code 汇率'),
        content: TextField(
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
              onPressed: () => Navigator.pop(ctx, '__reset__'),
              child: const Text('恢复内置'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (action == null || !context.mounted) return;
    if (action == '__reset__') {
      await service.setOverride(code, 0);
      return;
    }
    final v = double.tryParse(action.trim());
    if (v == null || v <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('请输入有效汇率')));
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
