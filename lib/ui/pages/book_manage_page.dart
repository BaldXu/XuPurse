import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/global_database.dart';
import '../../state/providers.dart';
import '../layout/xp_page_scaffold_mixin.dart';
import '../widgets/xp_sheet.dart';
import '../widgets/xp_fab.dart';
import '../widgets/xp_snack.dart';
import '../widgets/xp_skeleton.dart';

/// 账本管理页：新建 / 切换 / 删除账本（切换后重建数据源）。
class BookManagePage extends ConsumerStatefulWidget {
  const BookManagePage({super.key});

  @override
  ConsumerState<BookManagePage> createState() => _BookManagePageState();
}

class _BookManagePageState extends ConsumerState<BookManagePage>
    with XpPageScaffold<BookManagePage> {
  int _revision = 0;
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooks();
  }

  Future<List<Book>> _loadBooks() async {
    final mgr = ref.read(databaseManagerProvider);
    final books = await mgr.listBooks();
    // 读取每个账本名字段（listBooks 已含）
    return books;
  }

  void _refreshProviders() {
    ref.invalidate(dbProvider);
    ref.invalidate(baseCurrencyProvider);
    ref.invalidate(minBillTimeProvider);
    ref.read(homeMonthsProvider.notifier).state = 1;
    ref.read(homeTypeFilterProvider.notifier).state = HomeTypeFilter.all;
    ref.read(homeCustomRangeProvider.notifier).state = null;
  }

  Future<void> _switchBook(String bookId) async {
    final mgr = ref.read(databaseManagerProvider);
    if (mgr.currentBookId == bookId) return;
    await mgr.switchBook(bookId);
    _refreshProviders();
    setState(() => _revision++);
    _booksFuture = _loadBooks();
    if (mounted) {
      showXpSnack(context, '已切换账本');
    }
  }

  Future<void> _createBook() async {
    final ctrl = TextEditingController();
    final name = await showXpDialog<String>(
      context: context,
      title: '新建账本',
      contentWidget: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '账本名称',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
          ),
          child: const Text('创建'),
        ),
      ],
    );
    ctrl.dispose();
    if (name == null || !mounted) return;
    final mgr = ref.read(databaseManagerProvider);
    await mgr.createBook(name: name);
    _refreshProviders();
    setState(() => _revision++);
    _booksFuture = _loadBooks();
  }

  Future<void> _deleteBook(Book book) async {
    final ok = await confirmXpDialog(
      context,
      title: '删除账本',
      content: '确定删除「${book.name}」？该账本下全部数据将被清空，且不可恢复。',
      confirmLabel: '删除',
      danger: true,
    );
    if (!ok || !mounted) return;
    final mgr = ref.read(databaseManagerProvider);
    await mgr.deleteBook(book.id);
    // 删除当前账本后自动切换到剩余账本（无则新建默认账本），避免无当前账本
    if (mgr.currentBookId == null) {
      final rest = await mgr.listBooks();
      if (rest.isNotEmpty) {
        await mgr.switchBook(rest.first.id);
      } else {
        await mgr.createBook(name: '默认账本');
      }
    }
    _refreshProviders();
    setState(() => _revision++);
    _booksFuture = _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final currentId = ref.watch(databaseManagerProvider).currentBookId;
    return buildXpScaffold(
      appBar: AppBar(title: const Text('账本管理')),
      body: FutureBuilder<List<Book>>(
        future: _booksFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const XpSkeletonList(itemCount: 4);
          }
          if (snap.hasError) {
            return Center(child: Text('加载失败：${snap.error}'));
          }
          final books = snap.data ?? const <Book>[];
          if (books.isEmpty) {
            return const Center(child: Text('暂无账本'));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final book = books[i];
              final isCurrent = book.id == currentId;
              return Card(
                child: ListTile(
                  leading: Icon(
                    isCurrent ? Icons.check_circle : Icons.menu_book_outlined,
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(book.name),
                  subtitle: Text(
                    '本位币 ${book.baseCurrency}${isCurrent ? ' · 当前' : ''}',
                  ),
                  trailing: IconButton(
                    tooltip: '删除',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteBook(book),
                  ),
                  onTap: () => _switchBook(book.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: XpFab(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('新建账本'),
      ),
    );
  }
}
