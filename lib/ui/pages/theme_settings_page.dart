import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/theme_provider.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../tokens/design_tokens.dart';
import '../widgets/app_icon.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/xp_card.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_sliding_segmented.dart';
import '../widgets/xp_snack.dart';
import 'icon_settings_page.dart';

/// 主题外观页：
///
/// 一个主题 = 一套完整外观方案（颜色 + 卡片外观 + 图标 + 磨砂 + 转场）。
/// - 顶部主题画廊：每张卡用主题真实配色渲染迷你预览，点按应用整套外观；
///   长按用户自建主题出现右上角减号可删除（内置与当前使用中的不可删）。
/// - 下方编辑器始终跟随「当前主题」实时同步（不再有独立本地色值副本）：
///   内置预设只读展示真实配色，点「复制为自定义主题」后即可编辑；
///   自定义主题的所有修改即时生效并持久化到该主题。
class ThemeSettingsPage extends ConsumerStatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  ConsumerState<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends ConsumerState<ThemeSettingsPage>
    with XpPageScaffold<ThemeSettingsPage> {
  /// 长按后处于「删除态」的主题 id（显示右上角减号）。
  String? _armedDelete;

  /// 进入本页时的主题 id：离开时若未保留修改，恢复回该状态。
  late String _enteredId;

  /// 进入本页时全部用户自建主题的快照（id → 配置）。
  /// 会话内对任意主题的修改/新建/删除都以它为基准回滚。
  late Map<String, AppTheme> _enteredThemes;

  @override
  void initState() {
    super.initState();
    final state = ref.read(themeProvider);
    _enteredId = state.currentId;
    _enteredThemes = {for (final t in state.userThemes) t.id: t};
  }

  /// 是否有未保留的修改：当前状态与进入时快照不一致。
  /// 覆盖：切换主题 / 新建或删除主题 / 任意主题的颜色、样式、圆角、
  /// 图标、磨砂、转场、名称等全部可序列化字段。
  /// 注意 Map 的 == 是引用比较，须用 mapEquals 按内容比较。
  bool _isDirty(ThemeState state) {
    if (state.currentId != _enteredId) return true;
    final currentById = {for (final t in state.userThemes) t.id: t};
    // 会话内新建的主题
    if (currentById.keys.any((id) => !_enteredThemes.containsKey(id))) {
      return true;
    }
    // 会话内删除或修改的既有主题
    for (final e in _enteredThemes.entries) {
      final cur = currentById[e.key];
      if (cur == null) return true;
      if (!mapEquals(cur.toJson(), e.value.toJson())) return true;
    }
    return false;
  }

  /// 恢复为进入本页时的主题状态（放弃本次会话的全部修改）。
  Future<void> _revertAndLeave() async {
    final notifier = ref.read(themeProvider.notifier);
    // 0. 先还原本会话被删除的既有主题（保证 _enteredId 可被选中）
    for (final e in _enteredThemes.entries) {
      final exists = ref
          .read(themeProvider)
          .userThemes
          .any((t) => t.id == e.key);
      if (!exists) {
        await notifier.addUserTheme(e.value);
      }
    }
    // 1. 切回进入时的主题（先切走，新建主题不再「当前」才能删除）
    await notifier.select(_enteredId);
    // 2. 删除本会话新建的主题（不在进入时快照里的）
    for (final t in ref.read(themeProvider).userThemes.toList()) {
      if (!_enteredThemes.containsKey(t.id)) {
        await notifier.deleteUserTheme(t.id);
      }
    }
    // 3. 还原被修改的既有主题配置
    for (final e in _enteredThemes.entries) {
      AppTheme? cur;
      for (final t in ref.read(themeProvider).userThemes) {
        if (t.id == e.key) {
          cur = t;
          break;
        }
      }
      if (cur != null && !mapEquals(cur.toJson(), e.value.toJson())) {
        await notifier.updateCurrentTheme(e.value);
      }
    }
  }

  /// 离开拦截：有未保留修改时弹确认，让用户选择保留 / 恢复原状 / 留下。
  Future<void> _confirmLeave() async {
    final choice = await showXpDialog<String>(
      context: context,
      title: '保留主题修改？',
      content: '离开前可选择保留当前修改，或恢复为进入本页时的主题。',
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'stay'),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'revert'),
          child: const Text(
            '恢复原状并离开',
            style: TextStyle(color: XpSemanticColors.danger),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'save'),
          child: const Text('保留修改并离开'),
        ),
      ],
    );
    if (!mounted) return;
    switch (choice) {
      case 'save':
        // 滑动条可能留有「只改内存未落盘」的预览值，离开前统一落盘。
        await ref.read(themeProvider.notifier).flushPersist();
        if (mounted) Navigator.pop(context);
      case 'revert':
        await _revertAndLeave();
        if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(themeProvider);
    final current = state.current;
    final scheme = Theme.of(context).colorScheme;
    final dirty = _isDirty(state);
    return PopScope<Object?>(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: buildXpScaffold(
        appBar: AppBar(title: const Text('主题外观')),
        buildBody: (_) => ListView(
          padding: const EdgeInsets.all(XpSpacing.l),
          children: [
            // ---- 主题画廊 ----
            Text('主题', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: XpSpacing.xs),
            Text(
              '点按应用整套外观（颜色 / 卡片 / 图标 / 磨砂 / 转场）；长按自建主题可删除。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: XpSpacing.m),
            SizedBox(
              height: 142,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final theme in state.allThemes)
                    _buildGalleryCard(theme, state),
                  _buildNewCard(),
                ],
              ),
            ),
            const SizedBox(height: XpSpacing.xl),
            const Divider(height: 1),
            const SizedBox(height: XpSpacing.xl),

            // ---- 当前主题编辑器（始终跟随选中主题） ----
            _buildEditorHeader(current),
            const SizedBox(height: XpSpacing.m),
            _buildColorSection(current),
            const SizedBox(height: XpSpacing.m),
            _buildAppearanceSection(current),
            const SizedBox(height: XpSpacing.m),
            _buildIconSection(current),
            const SizedBox(height: XpSpacing.m),
            _buildFrostedSection(current),
            const SizedBox(height: XpSpacing.m),
            _buildTransitionSection(current),
          ],
        ),
      ),
    );
  }

  // ── 主题画廊 ─────────────────────────────────────────────────

  /// 单个主题预览卡：迷你页面（真实背景色）+ 卡片（真实卡色/圆角）+ 主按钮
  /// （主题色）；使用中描边高亮，删除态右上角红色减号。
  Widget _buildGalleryCard(AppTheme theme, ThemeState state) {
    final scheme = Theme.of(context).colorScheme;
    final active = theme.id == state.currentId;
    final deleteMode = _armedDelete == theme.id;
    final dark = theme.isDark;
    final pageBg = dark
        ? const Color(0xFF10151F)
        : (theme.background ?? scheme.surfaceContainerHighest);
    final cardColor = dark
        ? const Color(0xFF1B2230)
        : (theme.cardColor ?? Colors.white);
    final lineColor = dark
        ? Colors.white.withValues(alpha: 0.30)
        : Colors.black.withValues(alpha: 0.14);
    final previewRadius = (theme.cardRadius ?? XpRadius.m).clamp(8.0, 20.0);

    return GestureDetector(
      key: ValueKey('theme_card_${theme.id}'),
      onTap: () => _select(theme),
      onLongPress: () {
        // 仅用户自建且非当前使用中的主题可进入删除态
        if (!theme.isPreset && theme.id != state.currentId) {
          setState(() => _armedDelete = theme.id);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 140,
            padding: const EdgeInsets.all(XpSpacing.s),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(XpRadius.l),
              border: Border.all(
                color: active ? scheme.primary : scheme.outlineVariant,
                width: active ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 迷你页面预览
                Container(
                  height: 84,
                  width: double.infinity,
                  padding: const EdgeInsets.all(XpSpacing.s),
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: BorderRadius.circular(XpRadius.m),
                  ),
                  child: Stack(
                    children: [
                      // 迷你卡片
                      Positioned(
                        top: XpSpacing.s,
                        left: XpSpacing.s,
                        right: XpSpacing.s,
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(
                            horizontal: XpSpacing.s,
                            vertical: XpSpacing.s,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(previewRadius),
                            border: theme.cardStyle == XpCardStyle.outlined
                                ? Border.all(color: scheme.outlineVariant)
                                : null,
                            boxShadow: theme.cardStyle == XpCardStyle.elevated
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: theme.seedColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: XpSpacing.xs),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      height: 5,
                                      width: 70,
                                      decoration: BoxDecoration(
                                        color: lineColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      height: 5,
                                      width: 46,
                                      decoration: BoxDecoration(
                                        color: lineColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 迷你主按钮
                      Positioned(
                        bottom: XpSpacing.s,
                        right: XpSpacing.s,
                        child: Container(
                          width: 48,
                          height: 14,
                          decoration: BoxDecoration(
                            color: theme.seedColor,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: XpSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        theme.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (active)
                      Icon(Icons.check_circle, size: 16, color: scheme.primary)
                    else if (dark)
                      Icon(
                        Icons.dark_mode_outlined,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (deleteMode)
            Positioned(
              top: -6,
              right: -6,
              child: GestureDetector(
                key: ValueKey('theme_del_${theme.id}'),
                onTap: () => _confirmDelete(theme),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: XpSemanticColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 「新建主题」卡：复制当前主题为一套可编辑的自定义主题。
  Widget _buildNewCard() {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const ValueKey('theme_new'),
      borderRadius: BorderRadius.circular(XpRadius.l),
      onTap: _createNew,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(left: XpSpacing.s),
        padding: const EdgeInsets.all(XpSpacing.s),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(XpRadius.l),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 28, color: scheme.primary),
            const SizedBox(height: XpSpacing.s),
            Text(
              '新建主题',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _select(AppTheme theme) async {
    if (theme.isDark) {
      showXpSnack(context, '暗色跟随系统深色设置：系统开启深色模式即自动使用');
      return;
    }
    setState(() => _armedDelete = null);
    await ref.read(themeProvider.notifier).select(theme.id);
  }

  // ── 主题生命周期：新建 / 复制 / 重命名 / 删除 ─────────────────

  /// 复制当前主题为一套自定义主题（保留其全部外观字段）。
  /// 源为暗色预设时不复制深色背景/卡色（浅色主题下会文字全糊），回退默认。
  AppTheme _cloneTheme(
    AppTheme src, {
    required String id,
    required String name,
  }) => AppTheme(
    id: id,
    name: name,
    seedColor: src.seedColor,
    background: src.isDark ? null : src.background,
    cardColor: src.isDark ? null : src.cardColor,
    sheetColor: src.isDark ? null : src.sheetColor,
    fontFamily: src.fontFamily,
    fontScale: src.fontScale,
    cardStyle: src.cardStyle,
    cardRadius: src.cardRadius,
    iconPack: src.iconPack,
    frosted: src.frosted,
    transitionBlur: src.transitionBlur,
    isDark: false,
  );

  Future<void> _createNew() async {
    final name = await _promptThemeName(
      context,
      title: '新建主题',
      initial: '我的主题',
    );
    if (name == null || name.isEmpty || !mounted) return;
    final cur = ref.read(themeProvider).current;
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await ref
        .read(themeProvider.notifier)
        .addUserTheme(_cloneTheme(cur, id: id, name: name));
    if (!mounted) return;
    showXpSnack(context, '已新建并应用「$name」，可自由编辑');
  }

  Future<void> _forkCurrent() async {
    final cur = ref.read(themeProvider).current;
    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    await ref
        .read(themeProvider.notifier)
        .addUserTheme(_cloneTheme(cur, id: id, name: '${cur.name} 副本'));
    if (!mounted) return;
    showXpSnack(context, '已复制并应用「${cur.name} 副本」，可自由编辑');
  }

  Future<void> _rename() async {
    final cur = ref.read(themeProvider).current;
    final name = await _promptThemeName(
      context,
      title: '重命名主题',
      initial: cur.name,
    );
    if (name == null || name.isEmpty || !mounted) return;
    if (name == cur.name) return;
    await ref
        .read(themeProvider.notifier)
        .updateCurrentTheme(cur.copyWith(name: name));
    if (!mounted) return;
    showXpSnack(context, '已重命名为「$name」');
  }

  /// 删除当前主题：先切回内置预设（当前主题不可直接删），再删除。
  Future<void> _deleteCurrent() async {
    final cur = ref.read(themeProvider).current;
    final ok = await confirmXpDialog(
      context,
      title: '删除主题',
      content: '确定删除主题「${cur.name}」？删除后不可恢复。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok || !mounted) return;
    final notifier = ref.read(themeProvider.notifier);
    await notifier.select(presetThemes.first.id);
    await notifier.deleteUserTheme(cur.id);
    if (!mounted) return;
    showXpSnack(context, '已删除「${cur.name}」');
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

  /// 主题名称输入弹窗：TextField 作用域在弹窗内，不与页面交互抢键盘焦点。
  Future<String?> _promptThemeName(
    BuildContext context, {
    required String title,
    required String initial,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _ThemeNameDialog(title: title, initial: initial),
    );
  }

  // ── 编辑器头部 ────────────────────────────────────────────────

  Widget _buildEditorHeader(AppTheme theme) {
    final scheme = Theme.of(context).colorScheme;
    final preset = theme.isPreset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '当前主题 · ${theme.name}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: XpSpacing.s,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: preset
                    ? scheme.surfaceContainerHighest
                    : scheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(XpRadius.pill),
              ),
              child: Text(
                preset ? '内置' : '自定义',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: preset
                      ? scheme.onSurfaceVariant
                      : scheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: XpSpacing.xs),
        Text(
          preset
              ? '内置预设不可直接修改；点下方按钮复制为自定义主题后可自由编辑。'
              : '所有修改即时生效并保存到「${theme.name}」。',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: XpSpacing.m),
        if (preset)
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _forkCurrent,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('复制为自定义主题'),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _rename,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('重命名'),
                ),
              ),
              const SizedBox(width: XpSpacing.m),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _deleteCurrent,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: XpSemanticColors.danger,
                  ),
                  label: Text(
                    '删除主题',
                    style: TextStyle(color: XpSemanticColors.danger),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── 颜色 ──────────────────────────────────────────────────────

  Widget _buildColorSection(AppTheme theme) {
    final preset = theme.isPreset;
    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _sectionTitle('颜色'),
          _colorRow(
            label: '主题色',
            color: theme.seedColor,
            hex: _hexOf(theme.seedColor),
            onPick: preset ? null : () => _pickColor('seed'),
          ),
          _colorRow(
            label: '页面背景色',
            color: theme.background,
            hex: theme.background == null ? null : _hexOf(theme.background!),
            onPick: preset ? null : () => _pickColor('background'),
            onReset: preset ? null : () => _resetColor('background'),
          ),
          _colorRow(
            label: '卡片背景色',
            color: theme.cardColor,
            hex: theme.cardColor == null ? null : _hexOf(theme.cardColor!),
            onPick: preset ? null : () => _pickColor('card'),
            onReset: preset ? null : () => _resetColor('card'),
          ),
          _colorRow(
            label: '弹窗背景色',
            color: theme.sheetColor,
            hex: theme.sheetColor == null ? null : _hexOf(theme.sheetColor!),
            onPick: preset ? null : () => _pickColor('sheet'),
            onReset: preset ? null : () => _resetColor('sheet'),
          ),
        ],
      ),
    );
  }

  /// 颜色项行：色块预览 + 名称 + 色值（未设置显示「默认」）。
  /// 取色前先收起键盘，避免名称输入框抢焦点弹出键盘。
  Widget _colorRow({
    required String label,
    required Color? color,
    required String? hex,
    VoidCallback? onPick,
    VoidCallback? onReset,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPick != null;
    final isDefault = color == null;
    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
      leading: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color ?? scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: isDefault
              ? Icon(Icons.auto_awesome, size: 13, color: scheme.outline)
              : null,
        ),
      ),
      title: Text(label),
      subtitle: Text(!isDefault && hex != null ? hex : '默认'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 仅在已设置过颜色（非默认）时才显示「恢复默认」，避免无效果按钮
          if (enabled && onReset != null && color != null)
            IconButton(
              tooltip: '恢复默认',
              icon: const Icon(Icons.restart_alt, size: 20),
              onPressed: onReset,
            ),
          if (enabled)
            const Icon(Icons.chevron_right, size: 20)
          else
            Icon(Icons.lock_outline, size: 16, color: scheme.outline),
        ],
      ),
      onTap: onPick,
    );
  }

  /// 打开取色器并把结果写回当前主题对应颜色项。
  Future<void> _pickColor(String field) async {
    final theme = ref.read(themeProvider).current;
    if (theme.isPreset) return;
    // 收起键盘：取色弹窗关闭后不会把焦点/键盘还给页面输入框。
    FocusManager.instance.primaryFocus?.unfocus();
    final initial = switch (field) {
      'background' => theme.background ?? const Color(0xFFF5F6F8),
      'card' => theme.cardColor ?? const Color(0xFFFFFFFF),
      'sheet' => theme.sheetColor ?? const Color(0xFFF1F2F4),
      _ => theme.seedColor,
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
    // 对比度校验：浅色主题下背景/卡片/弹窗过深会导致文字与背景全糊。
    if (field != 'seed' && picked.computeLuminance() < 0.15) {
      showXpSnack(context, '颜色过深（浅色主题下背景/卡片应为浅色系，文字会糊在一起）。请取浅色。', error: true);
      return;
    }
    final cur = ref.read(themeProvider).current;
    final updated = switch (field) {
      'seed' => cur.copyWith(seedColor: picked),
      'background' => cur.copyWith(background: picked),
      'card' => cur.copyWith(cardColor: picked),
      _ => cur.copyWith(sheetColor: picked),
    };
    await ref.read(themeProvider.notifier).updateCurrentTheme(updated);
  }

  Future<void> _resetColor(String field) async {
    final cur = ref.read(themeProvider).current;
    if (cur.isPreset) return;
    final updated = switch (field) {
      'background' => cur.copyWith(clearBackground: true),
      'card' => cur.copyWith(clearCardColor: true),
      _ => cur.copyWith(clearSheetColor: true),
    };
    await ref.read(themeProvider.notifier).updateCurrentTheme(updated);
  }

  // ── 外观（卡片样式滑块 / 圆角滑动条） ─────────────────────────

  Widget _buildAppearanceSection(AppTheme theme) {
    final preset = theme.isPreset;
    final notifier = ref.read(themeProvider.notifier);
    // 未设置时跟随设计 token 默认（XpRadius.m = 20）；滑动条 5~32 覆盖该值。
    final effectiveRadius = (theme.cardRadius ?? XpRadius.m).clamp(5.0, 32.0);
    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _sectionTitle('外观'),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              XpSpacing.l,
              XpSpacing.xs,
              XpSpacing.l,
              XpSpacing.m,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('卡片样式', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: XpSpacing.s),
                XpSlidingSegmented<XpCardStyle>(
                  items: const [
                    XpSegmentedItem(value: XpCardStyle.filled, label: '填充'),
                    XpSegmentedItem(value: XpCardStyle.outlined, label: '描边'),
                    XpSegmentedItem(value: XpCardStyle.elevated, label: '浮起'),
                  ],
                  selected: theme.cardStyle,
                  enabled: !preset,
                  onChanged: (v) =>
                      notifier.updateCurrentTheme(theme.copyWith(cardStyle: v)),
                ),
                const SizedBox(height: XpSpacing.m),
                Row(
                  children: [
                    Text('卡片圆角', style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      theme.cardRadius == null
                          ? '默认 ${effectiveRadius.round()}'
                          : '${effectiveRadius.round()}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (theme.cardRadius != null)
                      IconButton(
                        tooltip: '恢复默认',
                        icon: const Icon(Icons.restart_alt, size: 20),
                        onPressed: preset
                            ? null
                            : () => notifier.updateCurrentTheme(
                                theme.copyWith(clearCardRadius: true),
                              ),
                      ),
                  ],
                ),
                Slider(
                  value: effectiveRadius,
                  min: 5,
                  max: 32,
                  divisions: 27,
                  label: '${effectiveRadius.round()}',
                  // 拖动过程只改内存驱动实时预览，松手后一次性落盘，
                  // 避免每 tick 全量序列化 + SharedPreferences 写入。
                  onChanged: preset
                      ? null
                      : (v) => notifier.updateCurrentThemeSilent(
                          theme.copyWith(cardRadius: v.roundToDouble()),
                        ),
                  onChangeEnd: preset ? null : (_) => notifier.flushPersist(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 图标（进入独立图标页，写回当前主题） ───────────────────────

  Widget _buildIconSection(AppTheme theme) {
    final scheme = Theme.of(context).colorScheme;
    final preset = theme.isPreset;
    final pack = ref.watch(iconPackProvider);
    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _sectionTitle('图标'),
          ListTile(
            enabled: !preset,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            leading: AppIcon(
              icon: Icons.emoji_emotions_outlined,
              color: scheme.primary,
            ),
            title: const Text('图标风格'),
            subtitle: Text(preset ? '内置预设只读，复制为自定义后可选' : '当前：${pack.label}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: preset
                ? null
                : () => Navigator.of(context).push(
                    XpRoute<void>(builder: (_) => const IconSettingsPage()),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 磨砂玻璃 ──────────────────────────────────────────────────

  Widget _buildFrostedSection(AppTheme theme) {
    final scheme = Theme.of(context).colorScheme;
    final preset = theme.isPreset;
    final frosted = ref.watch(frostedGlassProvider);
    final notifier = ref.read(themeProvider.notifier);

    void set({bool? enabled, bool? appBar, bool? card, bool? sheet}) {
      if (preset) return;
      notifier.setFrosted(
        FrostedState(
          enabled: enabled ?? frosted.enabled,
          appBar: appBar ?? frosted.appBar,
          card: card ?? frosted.card,
          sheet: sheet ?? frosted.sheet,
        ),
      );
    }

    // ListTile.enabled 只做置灰，不会禁用 trailing 里的 Switch，
    // 预设只读时需显式传 null 关闭交互。
    ValueChanged<bool>? onChanged(void Function(bool) apply) =>
        preset ? null : apply;

    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _sectionTitle('磨砂玻璃'),
          ListTile(
            enabled: !preset,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            leading: Icon(Icons.blur_on, color: scheme.primary),
            title: const Text('磨砂玻璃'),
            subtitle: const Text('总开关，关闭后以下三项均不生效'),
            trailing: Switch(
              value: frosted.enabled,
              onChanged: onChanged((v) => set(enabled: v)),
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            enabled: !preset,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            leading: Icon(Icons.vertical_split, color: scheme.primary),
            title: const Text('标题栏/导航栏磨砂'),
            trailing: Switch(
              value: frosted.appBar,
              onChanged: onChanged((v) => set(appBar: v)),
            ),
          ),
          // 卡片磨砂：Release 强制关闭并隐藏开关（效果存在闪灰黑问题，
          // 见 FrostedState.cardsOn）；debug/profile 保留以便排查。
          if (!kReleaseMode) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              enabled: !preset,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: XpSpacing.l,
              ),
              leading: Icon(Icons.style_outlined, color: scheme.primary),
              title: const Text('卡片磨砂'),
              subtitle: const Text('卡片表面白色磨砂（σ10 · 透明度 0.55）'),
              trailing: Switch(
                value: frosted.card,
                onChanged: onChanged((v) => set(card: v)),
              ),
            ),
          ],
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            enabled: !preset,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            leading: Icon(Icons.article_outlined, color: scheme.primary),
            title: const Text('弹窗磨砂'),
            subtitle: const Text('弹窗表面白色磨砂（σ10 · 透明度 0.7）'),
            trailing: Switch(
              value: frosted.sheet,
              onChanged: onChanged((v) => set(sheet: v)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 转场动效 ──────────────────────────────────────────────────

  Widget _buildTransitionSection(AppTheme theme) {
    final scheme = Theme.of(context).colorScheme;
    final preset = theme.isPreset;
    final blurOn = ref.watch(transitionBlurProvider);
    final notifier = ref.read(themeProvider.notifier);
    return XpCard(
      padding: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _sectionTitle('转场动效'),
          ListTile(
            enabled: !preset,
            contentPadding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
            leading: Icon(
              Icons.motion_photos_on_outlined,
              color: scheme.primary,
            ),
            title: const Text('实时模糊动效'),
            subtitle: const Text('页面切换时旧页后退的实时高斯模糊；关闭后更省 GPU'),
            trailing: Switch(
              value: blurOn,
              onChanged: preset ? null : (v) => notifier.setTransitionBlur(v),
            ),
          ),
        ],
      ),
    );
  }

  // ── 公共 ──────────────────────────────────────────────────────

  Widget _sectionTitle(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          XpSpacing.l,
          XpSpacing.m,
          XpSpacing.l,
          XpSpacing.xs,
        ),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }

  static String _hexOf(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
}

/// 主题名称输入弹窗：自持 TextEditingController（随弹窗卸载才 dispose，
/// 避免退出动画期间提前释放报错）；TextField 作用域在弹窗内，
/// 不参与页面键盘焦点争夺。
class _ThemeNameDialog extends StatefulWidget {
  const _ThemeNameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_ThemeNameDialog> createState() => _ThemeNameDialogState();
}

class _ThemeNameDialogState extends State<_ThemeNameDialog> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: TextField(
          controller: _ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            labelText: '主题名称',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onSubmitted: (_) => Navigator.pop(context, _ctrl.text.trim()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
