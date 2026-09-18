import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../widgets/color_picker_dialog.dart';

/// 主题外观页：
/// - 预设主题：点按应用；长按用户自建主题出现右上角减号，可删除（内置与当前使用中不可删）。
/// - 自定义主题设置：主题色 / 页面背景 / 卡片背景三个单选项，选中后通过
///   PS 风格取色器（滑动色相 / 饱和度 / 明度）取色，确认后写回，保存新增为预设主题。
class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage> {
  /// 长按后处于「删除态」的主题 id（显示右上角减号）。
  String? _armedDelete;

  final _nameCtrl = TextEditingController();

  /// 当前正在编辑的颜色项：seed（主题色）/ background（页面背景）/ card（卡片背景）。
  String _editing = 'seed';
  late Color _seed;
  Color? _background;
  Color? _cardColor;

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
      _ => _seed,
    };
    final title = switch (field) {
      'background' => '选择页面背景色',
      'card' => '选择卡片背景色',
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
      } else {
        _seed = picked;
      }
    });
  }

  Future<void> _confirmDelete(AppTheme theme) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除主题'),
        content: Text('确定删除自定义主题「${theme.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(themeProvider.notifier).deleteUserTheme(theme.id);
    if (mounted) setState(() => _armedDelete = null);
  }

  Future<void> _saveCustom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('请输入主题名称');
      return;
    }
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await ref
        .read(themeProvider.notifier)
        .addUserTheme(
          AppTheme(
            id: id,
            name: name,
            seedColor: _seed,
            background: _background,
            cardColor: _cardColor,
          ),
        );
    if (!mounted) return;
    setState(() {
      _nameCtrl.clear();
      _seed = ref.read(currentThemeProvider).seedColor;
      _background = null;
      _cardColor = null;
    });
    _toast('已新增并应用「$name」');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('主题外观')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- 第一层：预设主题 ----
          Text('预设主题', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '点按应用；长按用户自建主题可删除（内置与当前使用中的不可删）。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final theme in state.allThemes)
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

          // ---- 第二层：自定义主题设置 ----
          Text('自定义主题', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            '三个颜色项均为单选项：选中后打开取色器，滑动色相 / 饱和度 / 明度'
            '取色并确认；保存后新增为一个预设主题。',
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
                      label: const Text('保存为预设主题'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 颜色项行：颜色预览 + 标题 + 单选框（可恢复默认）。
  Widget _colorRow({
    required String field,
    required String label,
    required Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final canReset = field != 'seed' && color != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
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
      title: Text(label),
      subtitle: Text(color == null ? '默认' : _hexOf(color)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canReset)
            IconButton(
              tooltip: '恢复默认',
              icon: const Icon(Icons.restart_alt, size: 20),
              onPressed: () => setState(() {
                if (field == 'background') {
                  _background = null;
                } else {
                  _cardColor = null;
                }
              }),
            ),
          Radio<String>(value: field),
        ],
      ),
      onTap: () => _pickColor(field),
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
                  color: Color(0xFFE5484D),
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
