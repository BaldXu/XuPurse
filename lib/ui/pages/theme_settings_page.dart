import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../../state/icon_pack_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_snack.dart';
import 'icon_settings_page.dart';

/// 主题外观页：
/// - 预设主题：点按应用；长按用户自建主题出现右上角减号，可删除（内置与当前使用中不可删）。
/// - 自定义主题设置：主题色 / 页面背景 / 卡片背景三个单选项，选中后通过
///   PS 风格取色器（滑动色相 / 饱和度 / 明度）取色，确认后写回，保存新增为预设主题。
class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage>
    with XpPageScaffold<ThemeSettingsPage> {
  /// 长按后处于「删除态」的主题 id（显示右上角减号）。
  String? _armedDelete;

  final _nameCtrl = TextEditingController();

  /// 当前正在编辑的颜色项：seed / background / card / sheet。
  String _editing = 'seed';
  late Color _seed;
  Color? _background;
  Color? _cardColor;
  Color? _sheetColor;

  @override
  void initState() {
    super.initState();
    _seed = ref.read(currentThemeProvider).seedColor;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _select(String id) async {
    setState(() => _armedDelete = null);
    await ref.read(themeProvider.notifier).select(id);
  }

  /// 打开取色器并把结果写回对应的颜色项。
  Future<void> _pickColor(String field) async {
    setState(() => _editing = field);
    final initial = switch (field) {
      'background' => _background ?? const Color(0xFFF5F6F8),
      'card' => _cardColor ?? const Color(0xFFFFFFFF),
      'sheet' => _sheetColor ?? const Color(0xFFF1F2F4),
      _ => _seed,
    };
    final title = switch (field) {
      'background' => '选择页面背景色',
      'card' => '选择卡片背景色',
      'sheet' => '选择弹窗背景色',
      _ => '选择主题色',
    };
    final picked = await showColorPickerDialog(
      context,
      initial: initial,
      title: title,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (field == 'background') {
        _background = picked;
      } else if (field == 'card') {
        _cardColor = picked;
      } else if (field == 'sheet') {
        _sheetColor = picked;
      } else {
        _seed = picked;
      }
    });
  }

  Future<void> _confirmDelete(AppTheme theme) async {
    final ok = await confirmXpDialog(
      context,
      title: '删除主题',
      content: '确定删除自定义主题「${theme.name}」？',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok || !mounted) return;
    await ref.read(themeProvider.notifier).deleteUserTheme(theme.id);
    if (mounted) setState(() => _armedDelete = null);
  }

  Future<void> _saveCustom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showXpSnack(context, '请输入主题名称', error: true);
      return;
    }
    // 对比度校验：深色背景配浅色主题渲染会导致文字与背景全糊（低对比）。
    // 深色背景应配深色文字 → 引导走暗色模式，而不是存成浅色主题。
    final bg = _background;
    if (bg != null && bg.computeLuminance() < 0.15) {
      showXpSnack(
        context,
        '页面背景过深（浅色主题配深色背景会导致文字与背景糊在一起）。'
        '请取浅色背景，深色外观请用系统暗色模式。',
        error: true,
      );
      return;
    }
    final card = _cardColor;
    if (card != null && card.computeLuminance() < 0.15) {
      showXpSnack(
        context,
        '卡片背景过深（浅色主题下卡片应为白色/浅色系）。'
        '请取浅色卡片背景。',
        error: true,
      );
      return;
    }
    final sheet = _sheetColor;
    if (sheet != null && sheet.computeLuminance() < 0.15) {
      showXpSnack(
        context,
        '弹窗背景过深（浅色主题下弹窗应为白色/浅色系）。'
        '请取浅色弹窗背景。',
        error: true,
      );
      return;
    }
    final notifier = ref.read(themeProvider.notifier);
    final current = ref.read(themeProvider).current;
    final editingUserTheme = !current.isPreset;
    if (editingUserTheme) {
      // 当前是用户自建主题：保存并生效到当前主题（原地更新，不新增）。
      final updated = AppTheme(
        id: current.id,
        name: name,
        seedColor: _seed,
        background: _background,
        cardColor: _cardColor,
        sheetColor: _sheetColor,
      );
      await notifier.updateCurrentTheme(updated);
    } else {
      // 当前是预设主题：另存为一个新主题并应用。
      final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await notifier.addUserTheme(
        AppTheme(
          id: id,
          name: name,
          seedColor: _seed,
          background: _background,
          cardColor: _cardColor,
          sheetColor: _sheetColor,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _nameCtrl.clear();
      _seed = ref.read(currentThemeProvider).seedColor;
      _background = null;
      _cardColor = null;
      _sheetColor = null;
    });
    showXpSnack(context, editingUserTheme ? '已保存并生效到「$name」' : '已新增并应用「$name」');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeProvider);
    final scheme = Theme.of(context).colorScheme;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('主题外观')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- 第一层：预设主题（浅色） ----
          Text('预设主题', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '点按应用；长按用户自建主题可删除（内置与当前使用中的不可删）。'
            '深色外观由下方「暗色模式」控制，不与浅色主题混排。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final theme in state.allThemes.where((t) => !t.isDark))
                _ThemeBall(
                  theme: theme,
                  active: theme.id == state.currentId,
                  deleteMode: _armedDelete == theme.id,
                  onTap: () => _select(theme.id),
                  onLongPress: () {
                    // 仅用户自建且非当前使用中的主题可进入删除态
                    if (!theme.isPreset && theme.id != state.currentId) {
                      setState(() => _armedDelete = theme.id);
                    }
                  },
                  onDelete: () => _confirmDelete(theme),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // ---- 暗色模式（独立分区：跟随系统开关，不占浅色预设位） ----
          Text('暗色模式', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '跟随系统深色设置自动切换（内置克莱因蓝暗色变体），无需手动选择。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: AppIcon(
                icon: Icons.dark_mode_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('克莱因蓝 · 暗色'),
              subtitle: const Text('跟随系统深色设置自动切换，无需手动选择'),
              onTap: () {
                showXpSnack(context, '暗色跟随系统设置：系统开启深色模式即自动生效');
              },
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // ---- 第二层：自定义主题设置 ----
          Text('自定义主题', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            state.current.isPreset
                ? '四个颜色项均为单选项：选中后打开取色器，取色确认后'
                      '「另存为」新主题并应用。'
                : '四个颜色项均为单选项：选中后打开取色器，取色确认后'
                      '「保存并生效」到当前主题「${state.current.name}」。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: '主题名称',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  RadioGroup<String>(
                    groupValue: _editing,
                    onChanged: (v) {
                      if (v != null) _pickColor(v);
                    },
                    child: Column(
                      children: [
                        _colorRow(field: 'seed', label: '主题色', color: _seed),
                        _colorRow(
                          field: 'background',
                          label: '页面背景色',
                          color: _background,
                        ),
                        _colorRow(
                          field: 'card',
                          label: '卡片背景色',
                          color: _cardColor,
                          enabled: !ref.watch(frostedGlassProvider).cardsOn,
                          disabledHint: '卡片磨砂开启时，卡片背景固定为白色',
                        ),
                        _colorRow(
                          field: 'sheet',
                          label: '弹窗背景色',
                          color: _sheetColor,
                          enabled: !ref.watch(frostedGlassProvider).sheetOn,
                          disabledHint: '弹窗磨砂开启时，弹窗背景固定为白色',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveCustom,
                      icon: const Icon(Icons.add),
                      label: Text(
                        state.current.isPreset ? '另存为自定义主题' : '保存并生效',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildAppearanceSection(state),

          // ---- 图标包（全局开关，独立于主题预设） ----
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildIconSection(),

          // ---- 磨砂玻璃（全局开关，独立于主题预设） ----
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          _buildFrostedSection(),
        ],
      ),
    );
  }

  /// 第三层:当前主题外观定制(仅用户自建主题可改,预设只读)。
  Widget _buildAppearanceSection(ThemeState state) {
    final theme = state.current;
    final editable = !theme.isPreset;
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(themeProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('外观定制', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          editable ? '修改实时生效并保存到「${theme.name}」。' : '内置预设不可修改;先保存一个自定义主题再定制。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('动画'),
                  subtitle: const Text('页面转场动画'),
                  trailing: Switch(
                    value: theme.animationsEnabled,
                    onChanged: editable
                        ? (v) => notifier.updateCurrentTheme(
                            theme.copyWith(animationsEnabled: v),
                          )
                        : null,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('卡片样式'),
                  trailing: DropdownMenu<XpCardStyle>(
                    initialSelection: theme.cardStyle,
                    enabled: editable,
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: XpCardStyle.filled, label: '填充'),
                      DropdownMenuEntry(
                        value: XpCardStyle.outlined,
                        label: '描边',
                      ),
                      DropdownMenuEntry(
                        value: XpCardStyle.elevated,
                        label: '浮起',
                      ),
                    ],
                    onSelected: (v) {
                      if (v != null) {
                        notifier.updateCurrentTheme(
                          theme.copyWith(cardStyle: v),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('卡片圆角'),
                  subtitle: Text(
                    theme.cardRadius == null ? '默认 12' : '${theme.cardRadius}',
                  ),
                  trailing: SegmentedButton<double>(
                    selected: {theme.cardRadius ?? 12},
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 8, label: Text('小')),
                      ButtonSegment(value: 12, label: Text('中')),
                      ButtonSegment(value: 16, label: Text('大')),
                    ],
                    onSelectionChanged: editable
                        ? (sel) => notifier.updateCurrentTheme(
                            theme.copyWith(cardRadius: sel.first),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 图标包:全局开关(不依赖具体主题),点击进入图标选择页;
  /// 确认后整 App 分类/账户图标即时切换并持久化。
  Widget _buildIconSection() {
    final scheme = Theme.of(context).colorScheme;
    final pack = ref.watch(iconPackProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图标', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '分类与账户图标的整体风格，可切换 Twitter 表情（twemoji）。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: AppIcon(
              icon: Icons.emoji_emotions_outlined,
              color: scheme.primary,
            ),
            title: const Text('图标风格'),
            subtitle: Text('当前：${pack.label}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const IconSettingsPage()),
            ),
          ),
        ),
      ],
    );
  }

  /// 磨砂玻璃:全局配置(不依赖具体主题)。总开关 + 三个子开关——
  /// 标题栏/导航栏磨砂、卡片磨砂、弹窗磨砂;总开关关闭时子开关失效。
  Widget _buildFrostedSection() {
    final state = ref.watch(frostedGlassProvider);
    final notifier = ref.read(frostedGlassProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('磨砂玻璃', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '白色高斯模糊质感：标题栏/导航栏、卡片与弹窗可分别开关。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.blur_on, color: scheme.primary),
                title: const Text('磨砂玻璃'),
                subtitle: const Text('总开关，关闭后以下三项均不生效'),
                trailing: Switch(
                  value: state.enabled,
                  onChanged: notifier.setEnabled,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.vertical_split, color: scheme.primary),
                title: const Text('标题栏/导航栏磨砂'),
                enabled: state.enabled,
                trailing: Switch(
                  value: state.appBar,
                  onChanged: notifier.setAppBar,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.style_outlined, color: scheme.primary),
                title: const Text('卡片磨砂'),
                subtitle: const Text('卡片表面白色磨砂（σ10 · 透明度 0.55）'),
                enabled: state.enabled,
                trailing: Switch(
                  value: state.card,
                  onChanged: notifier.setCard,
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.article_outlined, color: scheme.primary),
                title: const Text('弹窗磨砂'),
                subtitle: const Text('弹窗表面白色磨砂（σ10 · 透明度 0.7）'),
                enabled: state.enabled,
                trailing: Switch(
                  value: state.sheet,
                  onChanged: notifier.setSheet,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 颜色项行：颜色预览 + 标题 + 单选框（可恢复默认）。
  /// [enabled] 为 false 时整行置灰（如卡片磨砂开启时卡片背景色固定为白色）。
  Widget _colorRow({
    required String field,
    required String label,
    required Color? color,
    bool enabled = true,
    String? disabledHint,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final canReset = field != 'seed' && color != null;
    return ListTile(
      enabled: enabled,
      contentPadding: EdgeInsets.zero,
      leading: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: color == null
              ? Icon(Icons.auto_awesome, size: 14, color: scheme.outline)
              : null,
        ),
      ),
      title: Text(label),
      subtitle: Text(
        !enabled && disabledHint != null
            ? disabledHint
            : (color == null ? '默认' : _hexOf(color)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canReset)
            IconButton(
              tooltip: '恢复默认',
              icon: const Icon(Icons.restart_alt, size: 20),
              onPressed: enabled
                  ? () => setState(() {
                      if (field == 'background') {
                        _background = null;
                      } else if (field == 'card') {
                        _cardColor = null;
                      } else {
                        _sheetColor = null;
                      }
                    })
                  : null,
            ),
          IgnorePointer(
            ignoring: !enabled,
            child: Radio<String>(value: field),
          ),
        ],
      ),
      onTap: enabled ? () => _pickColor(field) : null,
    );
  }

  static String _hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

/// 主题圆球：外圈 = 页面背景（自定义时），内圆 = 主题色。
/// 删除态时右上角显示红色减号。
class _ThemeBall extends StatelessWidget {
  const _ThemeBall({
    required this.theme,
    required this.active,
    required this.deleteMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  final AppTheme theme;
  final bool active;
  final bool deleteMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outerColor = theme.background ?? scheme.surfaceContainerHighest;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          key: ValueKey('theme_ball_${theme.id}'),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outerColor,
              border: active
                  ? Border.all(color: scheme.primary, width: 3)
                  : null,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.seedColor,
              ),
              child: active
                  ? const Icon(Icons.check, size: 24, color: Colors.white)
                  : null,
            ),
          ),
        ),
        if (deleteMode)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              key: ValueKey('theme_del_${theme.id}'),
              onTap: onDelete,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: XpSemanticColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.remove, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
