import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/icon_pack_provider.dart';
import '../../state/theme_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_snack.dart';
import '../tokens/design_tokens.dart';

/// 图标选择页：展示全部图标包，选择后点右上角「确认」应用，整个 App 刷新图标。
///
/// - 简约：Material Icons 单色线性图标（App 默认）。
/// - Twitter 表情：twemoji 彩色 SVG 表情，色彩更丰富。
/// 选择仅在点「确认」后生效并持久化，返回后所有图标即时切换。
class IconSettingsPage extends ConsumerStatefulWidget {
  const IconSettingsPage({super.key});

  @override
  ConsumerState<IconSettingsPage> createState() => _IconSettingsPageState();
}

class _IconSettingsPageState extends ConsumerState<IconSettingsPage>
    with XpPageScaffold<IconSettingsPage> {
  late IconPack _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(iconPackProvider);
  }

  Future<void> _confirm() async {
    if (_selected == ref.read(iconPackProvider)) {
      Navigator.pop(context);
      return;
    }
    final ok = await ref.read(themeProvider.notifier).setIconPack(_selected);
    if (!mounted) return;
    if (!ok) {
      // 预设只读：需先在主题页复制为自定义主题。
      showXpSnack(context, '内置预设不可修改，请先在主题页复制为自定义主题');
      return;
    }
    // 先提示再返回：pop 后 context 失效，不能再用它弹 snack。
    showXpSnack(context, '已应用到「${ref.read(themeProvider).current.name}」');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(iconPackProvider);
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(
        title: const Text('图标'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text(
              '确认',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(XpSpacing.l),
        children: [
          Text('图标风格', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: XpSpacing.xs),
          Text(
            '选择图标包，点右上角「确认」后整 App 图标即时刷新。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: XpSpacing.l),
          for (final pack in IconPack.values) ...[
            _IconPackCard(
              pack: pack,
              selected: _selected == pack,
              active: current == pack,
              onTap: () => setState(() => _selected = pack),
            ),
            const SizedBox(height: XpSpacing.l),
          ],
        ],
      ),
    );
  }
}

/// 单个图标包卡片：选中态描边 + 对勾；预览条强制按该包渲染。
class _IconPackCard extends StatelessWidget {
  const _IconPackCard({
    required this.pack,
    required this.selected,
    required this.active,
    required this.onTap,
  });

  final IconPack pack;
  final bool selected;
  final bool active;
  final VoidCallback onTap;

  /// 预览用语义名（覆盖常用分类/账户，两套图标均可渲染）。
  static const _previewNames = [
    'restaurant',
    'local_cafe',
    'shopping_cart',
    'commute',
    'savings',
    'pets',
    'mic',
    'school',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = active ? scheme.primary : null;
    // 选中态描边卡：自定义 shape 描边 + 动态底色，XpCard 不支持 color/shape
    // 参数，保留裸 Card。
    return Card(
      elevation: 0,
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.35)
          : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(XpSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    pack.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: XpSpacing.s),
                  if (active)
                    Text(
                      '使用中',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: scheme.primary),
                    ),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: XpSpacing.m),
              Text(
                pack == IconPack.minimal
                    ? 'Material 单色线性图标，跟随主题色渲染，简洁克制。'
                    : 'Twitter Emoji 彩色表情（twemoji），色彩丰富活泼。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: XpSpacing.m),
              // 预览条：强制按当前卡片图标包渲染，便于对比。
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final name in _IconPackCard._previewNames)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.surface.withValues(alpha: 0.6),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: AppIcon(name: name, size: 24, pack: pack),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
