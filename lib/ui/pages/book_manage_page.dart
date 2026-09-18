import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/global_database.dart';
import '../../state/providers.dart';

/// 账本管理页：新建 / 切换 / 删除账本（切换后重建数据源）。
class BookManagePage extends ConsumerStatefulWidget {
  const BookManagePage({super.key});

  @override
  ConsumerState<BookManagePage> createState() => _BookManagePageState();
}

class _BookManagePageState extends ConsumerState<BookManagePage> {
  int _revision = 0;

  Future<List<Book>> _loadBooks() async {
    final mgr = ref.read(databaseManagerProvider);
    final books = await mgr.listBooks();
    // 读取每个账本名字段（listBooks 已含）
    return books;
  }

  void _refreshProviders() {
    ref.invalidate(dbProvider);
    ref.invalidate(baseCurrencyProvider);
    ref.read(billsLimitProvider.notifier).state = 50;
  }

  Future<void> _switchBook(String bookId) async {
    final mgr = ref.read(databaseManagerProvider);
    if (mgr.currentBookId == bookId) return;
    await mgr.switchBook(bookId);
    _refreshProviders();
    setState(() => _revision++);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已切换账本')));
    }
  }

  Future<void> _createBook() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建账本'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '账本名称',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              ctx,
              ctrl.text.trim().isEmpty ? null : ctrl.text.trim(),
            ),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || !mounted) return;
    final mgr = ref.read(databaseManagerProvider);
    await mgr.createBook(name: name);
    _refreshProviders();
    setState(() => _revision++);
  }

  Future<void> _deleteBook(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除账本'),
        content: Text('确定删除「${book.name}」？该账本下全部数据将被清空，且不可恢复。'),
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
  }

  @override
  Widget build(BuildContext context) {
    final currentId = ref.watch(databaseManagerProvider).currentBookId;
    return Scaffold(
      appBar: AppBar(title: const Text('账本管理')),
      body: FutureBuilder<List<Book>>(
        future: _loadBooks(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createBook,
        icon: const Icon(Icons.add),
        label: const Text('新建账本'),
      ),
    );
  }
}
