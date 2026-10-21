import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/refund_service.dart';
import '../../state/providers.dart';
import '../tokens/design_tokens.dart';
import 'app_icon.dart';

/// 金额语义色(统一从 design_tokens 提供,保留旧名兼容既有调用方)。
const Color kExpenseColor = XpSemanticColors.expense;
const Color kIncomeColor = XpSemanticColors.income;
const Color kTransferColor = XpSemanticColors.transfer;

/// 按账单类型取金额语义色。
Color semanticColorOf(BillType type) => switch (type) {
  BillType.expense => XpSemanticColors.expense,
  BillType.income => XpSemanticColors.income,
  BillType.transfer => XpSemanticColors.transfer,
};

/// 单条账单（首页列表行）。
class BillTile extends ConsumerWidget {
  const BillTile({super.key, required this.bill, this.onTap, this.onLongPress});

  final Bill bill;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    // 退款合计：支出按净额展示（原本 100 元支出 + 20 元退款 → 显示 80）
    final refundTotals =
        ref.watch(refundTotalsProvider).value ?? const <String, int>{};
    final catById = {for (final c in categories) c.id: c};
    final accById = {for (final a in accounts) a.id: a};
    final type = BillType.values.byName(bill.type);

    final iconColor = hexToColor(catById[bill.categoryId]?.color);
    final title = bill.comment?.isNotEmpty == true
        ? bill.comment!
        : (catById[bill.categoryId]?.name ?? '未知分类');
    final baseSubtitle = switch (type) {
      BillType.transfer =>
        '${accById[bill.accountId]?.name ?? '?'} → ${accById[bill.incomeAccountId]?.name ?? '?'}',
      BillType.expense => accById[bill.accountId]?.name ?? '',
      BillType.income => accById[bill.accountId]?.name ?? '',
    };
    final refund = type == BillType.expense
        ? (refundTotals[bill.id] ?? 0)
        : 0;
    // 有退款时副标题补一句，主金额展示净额，避免用户以为原金额没变
    final subtitle = refund <= 0
        ? baseSubtitle
        : (baseSubtitle.isEmpty
              ? '已退 ¥${formatYuan(refund)}'
              : '$baseSubtitle · 已退 ¥${formatYuan(refund)}');
    final netAmount = refund <= 0 ? bill.amount : bill.amount - refund;
    final color = semanticColorOf(type);
    final prefix = type == BillType.expense
        ? '-'
        : (type == BillType.income ? '+' : '');

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.15),
        foregroundColor: iconColor,
        child: AppIcon(name: catById[bill.categoryId]?.icon, size: 20),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '$prefix${formatYuan(netAmount)}',
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600)
            .tabular,
      ),
    );
  }
}

/// 按天分组的账单列表（组头：日期 + 当日小计）。
class BillDayGroups extends ConsumerWidget {
  const BillDayGroups({super.key, required this.bills});

  final List<Bill> bills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundTotals =
        ref.watch(refundTotalsProvider).value ?? const <String, int>{};
    final groups = <String, List<Bill>>{};
    for (final bill in bills) {
      final dt = DateTime.fromMillisecondsSinceEpoch(bill.time);
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(bill);
    }

    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      var expense = 0;
      var income = 0;
      for (final b in entry.value) {
        // 小计同样按净额，才不会出现「小计 100 但下面那笔显示 80」
        if (b.type == BillType.expense.name) {
          expense += netAmountOf(b, refundTotals);
        }
        if (b.type == BillType.income.name) income += b.amount;
      }
      widgets.add(
        _DayHeader(
          label: _dayLabel(entry.key),
          expense: expense,
          income: income,
        ),
      );
      widgets.addAll(entry.value.map((b) => BillTile(bill: b)));
    }
    return Column(children: widgets);
  }

  static String _dayLabel(String key) {
    final parts = key.split('-');
    final dt = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final today = DateTime.now();
    final isToday =
        today.year == dt.year && today.month == dt.month && today.day == dt.day;
    return '${dt.month}月${dt.day}日 ${weekdays[dt.weekday - 1]}${isToday ? ' · 今天' : ''}';
  }
}

class _DayHeader extends ConsumerWidget {
  const _DayHeader({
    required this.label,
    required this.expense,
    required this.income,
  });

  final String label;
  final int expense;
  final int income;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.m,
        XpSpacing.l,
        XpSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.labelMedium)),
          Text(
            '支 ${formatYuan(expense)}  收 ${formatYuan(income)}',
            style: textTheme.labelMedium
                ?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
                .tabular,
          ),
        ],
      ),
    );
  }
}
