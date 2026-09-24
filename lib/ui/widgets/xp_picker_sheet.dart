import 'package:flutter/material.dart';

import '../../core/utils/amount.dart';
import '../../core/utils/app_colors.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/currency_service.dart';
import '../tokens/currency_meta.dart';
import '../tokens/design_tokens.dart';
import 'app_icon.dart';
import 'xp_param_row.dart';
import 'xp_sheet.dart';

/// 单个选择项高度（上下 12 内边距 + 36 头像 / 两行文字取高）。
const double _optionHeight = 64;

/// 面板标题区高度（标题 + 上下内边距 + 分隔线）。
const double _headerHeight = 46;

/// 面板底部留白。
const double _bottomPad = XpSpacing.l;

/// 底部主操作（如「完成」）区域高度。
const double _actionAreaHeight = 72;

/// 选择面板结果；[value] 为 null 表示「自动」（账户）或「跟随账户」（币种）。
///
/// 用包装类而非裸 null，是为了与「关闭面板 = 未更改」区分开。
class PickerChoice {
  const PickerChoice(this.value);

  final String? value;
}

/// 面板高度：按内容行数估算，避免固定比例下出现大片空白。
double _pickerHeightFactor(
  BuildContext context, {
  required int rows,
  double extra = 0,
}) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final content = _headerHeight + rows * _optionHeight + _bottomPad + extra;
  return (content / screenHeight).clamp(0.24, 0.85);
}

/// 账户选择面板（二级选择）：点选项即收起并回传所选账户。
///
/// [autoLabel] 非空时首项为「自动」，回传 [PickerChoice] 的 value 为 null。
/// 关闭（点遮罩 / 下拉）返回 null，调用方应视为「未更改」。
Future<PickerChoice?> showAccountPickerSheet({
  required BuildContext context,
  required List<Account> accounts,
  required String? selectedId,
  String title = '选择账户',
  String? autoLabel,
}) {
  return showXpSheet<PickerChoice>(
    context: context,
    heightFactor: _pickerHeightFactor(
      context,
      rows: accounts.length + (autoLabel == null ? 0 : 1),
    ),
    builder: (sheetContext) => _PickerShell(
      title: title,
      children: [
        if (autoLabel != null) ...[
          _PickerOption(
            leading: const _AutoAvatar(),
            title: autoLabel,
            subtitle: '记账时自动选择一个账户',
            selected: selectedId == null,
            onTap: () => Navigator.pop(sheetContext, const PickerChoice(null)),
          ),
          const XpParamDivider(),
        ],
        for (var i = 0; i < accounts.length; i++) ...[
          if (i > 0) const XpParamDivider(),
          _PickerOption(
            leading: _AccountAvatar(account: accounts[i]),
            title: accounts[i].name,
            subtitle: accounts[i].remark,
            trailing: _AccountBalance(account: accounts[i]),
            selected: accounts[i].id == selectedId,
            onTap: () =>
                Navigator.pop(sheetContext, PickerChoice(accounts[i].id)),
          ),
        ],
      ],
    ),
  );
}

/// 记账币种选择面板：首项为「跟随账户」，其余为受支持币种。
///
/// 关闭返回 null，调用方应视为「未更改」。
Future<PickerChoice?> showCurrencyPickerSheet({
  required BuildContext context,
  required String accountCurrency,
  required String? currentCode,
}) {
  final codes = CurrencyService.supportedCodes;
  final effective = currentCode ?? accountCurrency;
  return showXpSheet<PickerChoice>(
    context: context,
    heightFactor: _pickerHeightFactor(context, rows: codes.length + 1),
    builder: (sheetContext) => _PickerShell(
      title: '记账币种',
      children: [
        _PickerOption(
          leading: _Flag(code: accountCurrency),
          title: '跟随账户',
          subtitle: accountCurrency,
          selected: currentCode == null,
          onTap: () => Navigator.pop(sheetContext, const PickerChoice(null)),
        ),
        for (final code in codes) ...[
          const XpParamDivider(),
          _PickerOption(
            leading: _Flag(code: code),
            title: code,
            subtitle: code == accountCurrency ? '账户币种' : null,
            selected: effective == code,
            onTap: () => Navigator.pop(sheetContext, PickerChoice(code)),
          ),
        ],
      ],
    ),
  );
}

/// 标签选择面板（多选）：点「完成」回传选中的标签 id 集合。
///
/// 关闭返回 null，调用方应视为「未更改」。
Future<Set<String>?> showTagPickerSheet({
  required BuildContext context,
  required List<Tag> tags,
  required Set<String> selectedIds,
  String title = '选择标签',
}) {
  return showXpSheet<Set<String>>(
    context: context,
    heightFactor: _pickerHeightFactor(
      context,
      rows: tags.length,
      extra: _actionAreaHeight,
    ),
    builder: (_) =>
        _TagPickerBody(title: title, tags: tags, initialIds: selectedIds),
  );
}

/// 选择面板骨架：标题 + 分隔线 + 可滚动选项列表（+ 可选底部操作）。
class _PickerShell extends StatelessWidget {
  const _PickerShell({
    required this.title,
    required this.children,
    this.footer,
  });

  final String title;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            XpSpacing.s,
            XpSpacing.l,
            XpSpacing.s,
          ),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        Flexible(
          child: ListView(
            padding: const EdgeInsets.only(bottom: _bottomPad),
            children: children,
          ),
        ),
        if (footer != null) footer!,
      ],
    );
  }
}

/// 通用选项行：前导 + 标题/副标题 + 尾部值 + 选中勾。
class _PickerOption extends StatelessWidget {
  const _PickerOption({
    required this.title,
    required this.selected,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: XpSpacing.l,
          vertical: XpSpacing.m,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: XpSpacing.m),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.bodyLarge),
                  if (hasSubtitle)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: XpSpacing.m),
              trailing!,
            ],
            const SizedBox(width: XpSpacing.s),
            SizedBox(
              width: 20,
              height: 20,
              child: selected
                  ? Icon(Icons.check, size: 20, color: colorScheme.primary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// 「自动」项头像（中性色）。
class _AutoAvatar extends StatelessWidget {
  const _AutoAvatar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
      foregroundColor: colorScheme.onSurfaceVariant,
      child: const AppIcon(icon: Icons.auto_awesome, size: 20),
    );
  }
}

/// 账户头像（按账户色着色）。
class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(account.color);
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      foregroundColor: color,
      child: AppIcon(name: account.icon, size: 20),
    );
  }
}

/// 账户余额（旗帜 + 按币种着色的 tabular 数字）。
class _AccountBalance extends StatelessWidget {
  const _AccountBalance({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          XpCurrencyMetaConfig.flagOf(account.currency),
          style: textTheme.titleSmall,
        ),
        const SizedBox(width: XpSpacing.xs),
        Text(
          formatYuan(account.currentBalance),
          style: textTheme.titleSmall
              ?.copyWith(
                fontWeight: FontWeight.w600,
                color: XpCurrencyMetaConfig.colorOf(account.currency),
              )
              .tabular,
        ),
      ],
    );
  }
}

/// 币种旗帜。
class _Flag extends StatelessWidget {
  const _Flag({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          XpCurrencyMetaConfig.flagOf(code),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

/// 标签多选面板主体（本地暂存选中集，点「完成」回传）。
class _TagPickerBody extends StatefulWidget {
  const _TagPickerBody({
    required this.title,
    required this.tags,
    required this.initialIds,
  });

  final String title;
  final List<Tag> tags;
  final Set<String> initialIds;

  @override
  State<_TagPickerBody> createState() => _TagPickerBodyState();
}

class _TagPickerBodyState extends State<_TagPickerBody> {
  late final Set<String> _selected = {...widget.initialIds};

  @override
  Widget build(BuildContext context) {
    return _PickerShell(
      title: widget.title,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.s,
          XpSpacing.l,
          XpSpacing.l,
        ),
        child: FilledButton(
          onPressed: () => Navigator.pop(context, _selected),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          child: const Text('完成'),
        ),
      ),
      children: [
        for (var i = 0; i < widget.tags.length; i++) ...[
          if (i > 0) const XpParamDivider(),
          _PickerOption(
            leading: _TagAvatar(tag: widget.tags[i]),
            title: widget.tags[i].name,
            subtitle: widget.tags[i].preferCurrency == null
                ? null
                : '优先币种 ${widget.tags[i].preferCurrency}',
            selected: _selected.contains(widget.tags[i].id),
            onTap: () => setState(() {
              final id = widget.tags[i].id;
              if (!_selected.remove(id)) _selected.add(id);
            }),
          ),
        ],
      ],
    );
  }
}

/// 标签头像（按标签色着色）。
class _TagAvatar extends StatelessWidget {
  const _TagAvatar({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(tag.color);
    return CircleAvatar(
      radius: 18,
      backgroundColor: color.withValues(alpha: 0.15),
      foregroundColor: color,
      child: const AppIcon(icon: Icons.label_outline, size: 20),
    );
  }
}
