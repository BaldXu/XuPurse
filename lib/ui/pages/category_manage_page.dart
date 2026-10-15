import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/icons.dart';
import '../../core/utils/ids.dart';
import '../../data/database/app_database.dart';
import '../../domain/services/category_service.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/app_icon.dart';
import '../widgets/xp_empty_state.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_snack.dart';
import '../../state/providers.dart';
import '../tokens/design_tokens.dart';
import 'category_merge_page.dart';

/// 分类管理页（两级树；支出/收入/转账 三 tab）。
class CategoryManagePage extends ConsumerStatefulWidget {
  const CategoryManagePage({super.key});

  @override
  ConsumerState<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends ConsumerState<CategoryManagePage>
    with XpPageScaffold<CategoryManagePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: buildXpScaffold(
        appBar: AppBar(
          title: const Text('分类管理'),
          actions: [
            TextButton(
              onPressed: () async {
                final merged = await Navigator.of(context).push<bool>(
                  XpRoute(builder: (_) => const CategoryMergePage()),
                );
                if (merged == true && context.mounted) {
                  showXpSnack(context, '分类合并完成');
                }
              },
              child: const Text('分类合并'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '支出'),
              Tab(text: '收入'),
              Tab(text: '转账'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final type in BillType.values) _CategoryList(type: type),
          ],
        ),
        floatingActionButton: XpFab(
          onPressed: () => showXpSheet<void>(
            context: context,
            builder: (_) => const CategoryFormSheet(),
          ),
          icon: const Icon(Icons.add),
          label: const Text('新增分类'),
        ),
      ),
    );
  }
}

/// 拖拽列表里的一行：一级分类，或某个一级分类下展开出来的子分类。
class _CategoryRow {
  const _CategoryRow(this.category, {this.parentId});

  final Category category;

  /// 所属层级：null = 一级分类层；非 null = 该父分类的子分类层（＝拖动范围）。
  final String? parentId;
}

class _CategoryList extends ConsumerStatefulWidget {
  const _CategoryList({required this.type});

  final BillType type;

  @override
  ConsumerState<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<_CategoryList> {
  /// 已展开的一级分类 id；默认全部折叠（否则分类一多整屏铺开看不清）。
  final Set<String> _expanded = {};

  /// 拖拽落位后的本地排序值覆盖（id → sort，取值与写库值相同）；
  /// 写库成功/失败后立即清除，回到数据库真实顺序。
  final Map<String, int> _localSort = {};

  int _sortOf(Category c) => _localSort[c.id] ?? c.sort;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(categoriesProvider).valueOrNull ?? [];
    // 正常情况下顺序由库里 (sort, name) 决定；拖拽落位后先按本地覆盖值渲染，
    // 否则等写库回流的那一两帧里列表会先弹回原位再跳到新位置。
    final typed = all.where((c) => c.type == widget.type.name).toList()
      ..sort((a, b) {
        final bySort = _sortOf(a).compareTo(_sortOf(b));
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    if (typed.isEmpty) {
      return const XpEmptyState(
        icon: Icons.category_outlined,
        title: '暂无分类',
        message: '点击右下角新增',
      );
    }
    final parents = typed.where((c) => c.parentId == null).toList();
    final childrenByParent = <String, List<Category>>{};
    for (final c in typed) {
      if (c.parentId != null) {
        (childrenByParent[c.parentId!] ??= []).add(c);
      }
    }
    // 拉平成一维行（一级分类 + 其展开的子分类），交给 ReorderableListView 拖动。
    final rows = <_CategoryRow>[];
    for (final parent in parents) {
      rows.add(_CategoryRow(parent));
      if (_expanded.contains(parent.id)) {
        for (final child in childrenByParent[parent.id] ?? const <Category>[]) {
          rows.add(_CategoryRow(child, parentId: parent.id));
        }
      }
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 96),
      // 关掉桌面端默认的拖拽把手，统一「长按整行」拖动（手机/桌面手势一致）。
      buildDefaultDragHandles: false,
      header: rows.length > 1 ? _buildDragHint(context) : null,
      itemCount: rows.length,
      onReorder: (oldIndex, newIndex) => _reorder(rows, oldIndex, newIndex),
      itemBuilder: (context, i) {
        final row = rows[i];
        final category = row.category;
        final isParent = row.parentId == null;
        final childCount = childrenByParent[category.id]?.length ?? 0;
        return Column(
          key: ValueKey('${isParent ? 'p' : 'c'}-${category.id}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDelayedDragStartListener(
              index: i,
              child: _SwipeRevealTile(
                onDelete: () => _delete(category),
                child: _CategoryTile(
                  category: category,
                  indent: !isParent,
                  childCount: childCount,
                  expanded: isParent && _expanded.contains(category.id),
                  onToggleExpand: isParent
                      ? () => _toggleExpand(category.id)
                      : null,
                  // 一级分类：点击整行 = 展开/收起（无子分类时进编辑）；
                  // 子分类：点击整行 = 编辑。
                  onTap: isParent
                      ? (childCount > 0
                            ? () => _toggleExpand(category.id)
                            : null)
                      : () => _edit(category),
                  onEdit: () => _edit(category),
                ),
              ),
            ),
            // 分组分隔线：仅当下一行是另一个一级分类时画（与旧列表一致，末组不收尾）。
            if (i + 1 < rows.length && rows[i + 1].parentId == null)
              const Divider(height: 1),
          ],
        );
      },
    );
  }

  /// 列表顶部提示（ReorderableListView 的 header 不参与拖动）。
  Widget _buildDragHint(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        XpSpacing.l,
        XpSpacing.s,
        XpSpacing.l,
        XpSpacing.m,
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: XpSpacing.xs),
          Expanded(
            child: Text(
              '长按分类可上下拖动排序，一级分类与子分类各自在同层级内移动',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 长按拖动落位：只在同层级内移动（一级分类之间 / 同一父分类的子分类之间），
  /// 按落点顺序重新编号写库。只写 sort，**不改 parentId**，层级不会被拖动改掉。
  Future<void> _reorder(
    List<_CategoryRow> rows,
    int oldIndex,
    int newIndex,
  ) async {
    // ReorderableListView 给的 newIndex 是「移除被拖项之前」的插入位，先归一化。
    if (newIndex > oldIndex) newIndex -= 1;
    if (newIndex == oldIndex) return;
    final moved = rows[oldIndex];
    final scope = moved.parentId; // null = 一级分类层
    // 同层兄弟（保持当前显示顺序，且排除被拖动项）。
    final siblings = <String>[
      for (var i = 0; i < rows.length; i++)
        if (i != oldIndex && rows[i].parentId == scope) rows[i].category.id,
    ];
    // 落点：数一数「移除被拖项后、插入位之前的同层兄弟」有几个（必 ∈ [0, len]）。
    var pos = 0;
    var seen = 0;
    for (var i = 0; i < rows.length && seen < newIndex; i++) {
      if (i == oldIndex) continue;
      if (rows[i].parentId == scope) pos += 1;
      seen += 1;
    }
    siblings.insert(pos, moved.category.id);

    // 先本地渲染新顺序（编号规则与写库共用 siblingSortMap），写完再交回数据库顺序。
    final sorts = CategoryService.siblingSortMap(
      siblings,
      topLevel: scope == null,
    );
    setState(() => _localSort.addAll(sorts));
    try {
      await ref
          .read(categoryServiceProvider)
          .reorderSiblings(
            type: widget.type,
            orderedIds: siblings,
            topLevel: scope == null,
          );
    } catch (e) {
      if (mounted) showXpSnack(context, '排序失败：$e', error: true);
    } finally {
      _localSort.removeWhere((id, _) => sorts.containsKey(id));
      if (mounted) setState(() {});
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  Future<void> _edit(Category c) {
    return showXpSheet<void>(
      context: context,
      builder: (_) => CategoryFormSheet(category: c),
    );
  }

  Future<void> _delete(Category c) async {
    // 1) 有子分类不允许直接删（父分类须先处理子分类）
    final childrenCount = c.parentId == null
        ? await ref.read(categoryRepoProvider).countChildren(c.id)
        : 0;
    if (!mounted) return;
    if (childrenCount > 0) {
      showXpSnack(context, '请先删除该分类下的子分类', error: true);
      return;
    }
    final billCount = await ref.read(billRepoProvider).countByCategoryId(c.id);
    if (!mounted) return;

    // 2) 确认删除
    final confirmed = await confirmXpDialog(
      context,
      title: '删除分类',
      content: billCount > 0
          ? '「${c.name}」下还有 $billCount 笔明细，删除前需要先为这些明细指定新的分类。确定继续？'
          : '确定删除「${c.name}」？',
      confirmLabel: '删除',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    // 3) 无明细：直接删除
    if (billCount == 0) {
      await ref.read(categoryRepoProvider).delete(c.id);
      if (mounted) showXpSnack(context, '已删除「${c.name}」');
      return;
    }

    // 4) 有明细：先选定/新建目标分类，明细迁移完成后才删除
    final type = EnumDbName.fromDbName(
      BillType.values,
      c.type,
      BillType.expense,
    );
    final options = _reassignOptions(
      ref.read(categoriesProvider).valueOrNull ?? [],
      type,
      c,
    );
    final choice = await showXpSheet<String>(
      context: context,
      heightFactor: 0.6,
      builder: (_) =>
          _ReassignTargetSheet(billCount: billCount, options: options),
    );
    if (choice == null || !mounted) return;

    final String targetId;
    if (choice == _kCreateNewCategory) {
      final created = await showXpSheet<String>(
        context: context,
        builder: (_) => _NewCategorySheet(type: type, parentId: c.parentId),
      );
      if (created == null || !mounted) return;
      targetId = created;
    } else {
      targetId = choice;
    }

    try {
      await ref
          .read(categoryServiceProvider)
          .deleteWithReassign(categoryId: c.id, targetCategoryId: targetId);
      if (mounted) showXpSnack(context, '已删除「${c.name}」，明细已迁移');
    } catch (e) {
      if (mounted) showXpSnack(context, '删除失败：$e', error: true);
    }
  }
}

/// 目标分类候选（父分类在前、其子分类紧随，标签带父级前缀）。
List<_ReassignOption> _reassignOptions(
  List<Category> all,
  BillType type,
  Category exclude,
) {
  final typed = all
      .where((c) => c.type == type.name && c.id != exclude.id)
      .toList();
  final byId = {for (final c in typed) c.id: c};
  final parents = typed.where((c) => c.parentId == null).toList();
  final childrenByParent = <String, List<Category>>{};
  for (final c in typed) {
    if (c.parentId != null) {
      (childrenByParent[c.parentId!] ??= []).add(c);
    }
  }
  String label(Category c) {
    final parentId = c.parentId;
    if (parentId == null) return c.name;
    final parent = byId[parentId];
    return parent == null ? c.name : '${parent.name} / ${c.name}';
  }

  final out = <_ReassignOption>[];
  for (final p in parents) {
    out.add(
      _ReassignOption(id: p.id, label: label(p), icon: p.icon, color: p.color),
    );
    for (final child in childrenByParent[p.id] ?? const []) {
      out.add(
        _ReassignOption(
          id: child.id,
          label: label(child),
          icon: child.icon,
          color: child.color,
        ),
      );
    }
  }
  return out;
}

/// 迁移目标选项。
class _ReassignOption {
  const _ReassignOption({
    required this.id,
    required this.label,
    this.icon,
    this.color,
  });

  final String id;
  final String label;
  final String? icon;
  final String? color;
}

/// 「新建分类」哨兵值（与真实分类 id 不冲突）。
const String _kCreateNewCategory = '__create_new_category__';

/// 选择迁移目标：列出同类型分类 + 「新建分类」入口。
class _ReassignTargetSheet extends StatelessWidget {
  const _ReassignTargetSheet({required this.billCount, required this.options});

  final int billCount;
  final List<_ReassignOption> options;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            XpSpacing.l,
            0,
            XpSpacing.l,
            XpSpacing.xs,
          ),
          child: Text(
            '把 $billCount 笔明细移动到：',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: XpSpacing.l),
          child: Text(
            '删除分类前必须为这些明细指定新分类，不能让其失去归属。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: XpSpacing.s),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: scheme.primary.withValues(alpha: 0.15),
                  child: Icon(Icons.add, size: 18, color: scheme.primary),
                ),
                title: const Text('新建分类'),
                subtitle: const Text('当场创建一个新分类并迁入'),
                onTap: () => Navigator.pop(context, _kCreateNewCategory),
              ),
              const Divider(height: 1),
              if (options.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(XpSpacing.l),
                  child: Text(
                    '该类型下暂无其它分类，请选择「新建分类」。',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              for (final o in options)
                ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _parseColor(
                      o.color ?? '#4D3C77',
                    ).withValues(alpha: 0.15),
                    child: AppIcon(
                      name: o.icon,
                      size: 16,
                      color: _parseColor(o.color ?? '#4D3C77'),
                    ),
                  ),
                  title: Text(o.label),
                  onTap: () => Navigator.pop(context, o.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 删除含明细分类时「当场新建」的目标分类表单（名称 + 图标）。
class _NewCategorySheet extends ConsumerStatefulWidget {
  const _NewCategorySheet({required this.type, this.parentId});

  final BillType type;
  final String? parentId;

  @override
  ConsumerState<_NewCategorySheet> createState() => _NewCategorySheetState();
}

class _NewCategorySheetState extends ConsumerState<_NewCategorySheet> {
  final _nameCtrl = TextEditingController();
  String _icon = kDefaultCategoryIcon;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: XpSpacing.l,
        right: XpSpacing.l,
        top: XpSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + XpSpacing.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('新建分类', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: XpSpacing.xs),
            Text(
              '新建后，原分类下的明细会全部转移到它名下。',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: XpSpacing.l),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '分类名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            Text('图标', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: XpSpacing.s),
            _CategoryIconPicker(
              selected: _icon,
              onChanged: _saving ? null : (v) => setState(() => _icon = v),
            ),
            const SizedBox(height: XpSpacing.l),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '创建并迁移'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showXpSnack(context, '分类名称不能为空', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(categoryServiceProvider)
          .createCategory(
            type: widget.type,
            name: name,
            icon: _icon,
            parentId: widget.parentId,
          );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showXpSnack(context, '创建失败：$e', error: true);
    }
  }
}

/// 图标选择网格（分类表单 / 新建分类弹窗共用）。
class _CategoryIconPicker extends StatelessWidget {
  const _CategoryIconPicker({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String>? onChanged;

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
              width: 44,
              height: 44,
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
              child: AppIcon(name: name, size: 22),
            ),
          ),
      ],
    );
  }
}

/// 分类行：分类自身图标 + 名称 + 展开箭头（一级分类且有子分类时）。
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    this.indent = false,
    this.childCount = 0,
    this.expanded = false,
    this.onToggleExpand,
    this.onTap,
    required this.onEdit,
  });

  final Category category;
  final bool indent;
  final int childCount;
  final bool expanded;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.color ?? '#4D3C77');
    final isParent = category.parentId == null;
    return ListTile(
      onTap: onTap,
      // 一二级分类左右统一留 15dp 内边距，子分类在此基础再缩进。
      contentPadding: EdgeInsets.only(left: indent ? 15 + 24 : 15, right: 15),
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: color.withValues(alpha: 0.15),
        // 用分类自己配置的图标（未配置时由 AppIcon 兜底默认图标）。
        child: AppIcon(name: category.icon, size: 16, color: color),
      ),
      title: Text(category.name),
      subtitle: isParent
          ? Text(childCount > 0 ? '$childCount 个子分类' : '一级分类')
          : const Text('子分类'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isParent && childCount > 0)
            IconButton(
              onPressed: onToggleExpand,
              tooltip: expanded ? '收起子分类' : '展开子分类',
              visualDensity: VisualDensity.compact,
              icon: AnimatedRotation(
                turns: expanded ? 0.25 : 0,
                duration: XpMotion.micro,
                child: const Icon(Icons.chevron_right, size: 22),
              ),
            ),
          IconButton(
            onPressed: onEdit,
            tooltip: '编辑',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

/// 左滑露出删除按钮的列表项（自实现，项目无 flutter_slidable 依赖）。
///
/// - 向左拖动：前景左移，右侧露出固定宽度删除按钮；松手按位移/速度吸附。
/// - 展开态点击前景：先收起（不误触进入编辑）。
class _SwipeRevealTile extends StatefulWidget {
  const _SwipeRevealTile({required this.child, required this.onDelete});

  final Widget child;
  final VoidCallback onDelete;

  @override
  State<_SwipeRevealTile> createState() => _SwipeRevealTileState();
}

class _SwipeRevealTileState extends State<_SwipeRevealTile>
    with SingleTickerProviderStateMixin {
  /// 删除按钮宽度（等于前景最大左移距离）。
  static const double _actionWidth = 88;

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: XpMotion.micro,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    _ctrl.value = (_ctrl.value - d.delta.dx / _actionWidth).clamp(0.0, 1.0);
  }

  void _onEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;
    if (vx < -300) {
      _ctrl.forward();
    } else if (vx > 300) {
      _ctrl.reverse();
    } else {
      _ctrl.value >= 0.5 ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return GestureDetector(
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: _onEnd,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final offset = _actionWidth * _ctrl.value;
          return Stack(
            children: [
              // 背景：右侧删除按钮（被前景盖住，前景左移后露出）
              Positioned.fill(
                child: Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: _actionWidth,
                      height: double.infinity,
                      child: Material(
                        color: XpSemanticColors.danger,
                        child: InkWell(
                          onTap: () {
                            _ctrl.reverse();
                            widget.onDelete();
                          },
                          child: const Center(
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 前景：不透明表面盖住背景，随拖动左移
              Transform.translate(
                offset: Offset(-offset, 0),
                child: Material(color: bg, child: widget.child),
              ),
              // 展开态：拦截前景点击，先收起
              if (_ctrl.value > 0)
                Positioned(
                  left: 0,
                  right: offset,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _ctrl.reverse(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Color _parseColor(String color) {
  final hex = color.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16) ?? 0x4D3C77;
  return Color(0xFF000000 | value);
}

/// 分类表单（新增/编辑）。
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.category});

  final Category? category;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  BillType _type = BillType.expense;
  String? _parentId;
  String _color = '#4D3C77';
  String _icon = kDefaultCategoryIcon;
  bool _saving = false;

  static const _palette = [
    '#5470C6',
    '#91CC75',
    '#FAC858',
    '#EE6666',
    '#73C0DE',
    '#3BA272',
    '#EA7CCC',
    '#9A60B4',
    '#FC8452',
    '#F472B6',
    '#4D3C77',
    '#FF0000',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _type = EnumDbName.fromDbName(BillType.values, c?.type, BillType.expense);
    _parentId = c?.parentId;
    _color = c?.color ?? '#4D3C77';
    _icon = c?.icon ?? kDefaultCategoryIcon;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parents = (ref.watch(categoriesProvider).valueOrNull ?? [])
        .where((c) => c.type == _type.name && c.parentId == null)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: XpSpacing.l,
        right: XpSpacing.l,
        top: XpSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.category == null ? '新增分类' : '编辑分类',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: XpSpacing.l),
            SegmentedButton<BillType>(
              segments: const [
                ButtonSegment(value: BillType.expense, label: Text('支出')),
                ButtonSegment(value: BillType.income, label: Text('收入')),
                ButtonSegment(value: BillType.transfer, label: Text('转账')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _parentId = null;
              }),
            ),
            const SizedBox(height: XpSpacing.m),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '分类名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: XpSpacing.m),
            DropdownButtonFormField<String?>(
              initialValue: _parentId,
              decoration: const InputDecoration(
                labelText: '父分类（可选）',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('（无，作为一级分类）'),
                ),
                for (final p in parents)
                  DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _parentId = v),
            ),
            const SizedBox(height: XpSpacing.m),
            Text('图标', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: XpSpacing.s),
            _CategoryIconPicker(
              selected: _icon,
              onChanged: _saving ? null : (v) => setState(() => _icon = v),
            ),
            const SizedBox(height: XpSpacing.m),
            Text('颜色', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: XpSpacing.s),
            Wrap(
              spacing: 8,
              children: [
                for (final hex in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: _parseColor(hex),
                      child: _color == hex
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: XpSpacing.m),
            Text(
              '排序请直接在分类列表里长按拖动调整',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '保存中…' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showXpSnack(context, '分类名称不能为空', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(categoryRepoProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      if (widget.category == null) {
        // 新分类排在目标层级末尾（一级分类步长 100、子分类步长 1），
        // 之后在列表里长按拖动就能调位置。
        final sort = await ref
            .read(categoryServiceProvider)
            .nextSort(type: _type, parentId: _parentId);
        await repo.insert(
          CategoriesCompanion.insert(
            id: genId(),
            type: _type.name,
            name: name,
            icon: Value(_icon),
            color: Value(_color),
            parentId: Value(_parentId),
            customName: Value(true),
            defaultSelect: const Value(false),
            sort: Value(sort),
            seedKey: const Value(null),
            createdAt: now,
            updatedAt: now,
          ),
        );
      } else {
        final old = widget.category!;
        // 只有「换了父分类」（层级变了）才重算排序值，落到新层级末尾；
        // 平时编辑不写 sort —— 顺序一律交给分类列表长按拖动，避免手填序号撞号。
        final newSort = old.parentId == _parentId
            ? null
            : await ref
                  .read(categoryServiceProvider)
                  .nextSort(type: _type, parentId: _parentId);
        await repo.update(
          old.id,
          CategoriesCompanion(
            type: Value(_type.name),
            name: Value(name),
            icon: Value(_icon),
            color: Value(_color),
            parentId: Value(_parentId),
            customName: Value(true),
            sort: newSort == null ? const Value.absent() : Value(newSort),
            updatedAt: Value(now),
          ),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showXpSnack(context, '保存失败：$e', error: true);
    }
  }
}
