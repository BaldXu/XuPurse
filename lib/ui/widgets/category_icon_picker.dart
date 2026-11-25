import 'package:flutter/material.dart';

import '../../core/utils/icons.dart';
import '../tokens/design_tokens.dart';
import 'app_icon.dart';

/// 分类图标选择网格（分类管理页 / 记账页快速新建分类共用）。
///
/// 选中态用主题色浅底 + 描边；图标来自 [iconRegistry] 的语义名。
class CategoryIconPicker extends StatelessWidget {
  const CategoryIconPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.itemSize = 44,
  });

  /// 当前选中的图标语义名。
  final String selected;

  /// 选择回调；null = 只读。
  final ValueChanged<String>? onChanged;

  /// 单个圆形图标尺寸。
  final double itemSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: XpSpacing.s,
      runSpacing: XpSpacing.s,
      children: [
        for (final name in iconRegistry.keys.toList()..sort())
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(name),
            child: Container(
              width: itemSize,
              height: itemSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected == name
                    ? scheme.primary.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest,
                border: Border.all(
                  color: selected == name ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: AppIcon(name: name, size: itemSize * 0.5),
            ),
          ),
      ],
    );
  }
}
