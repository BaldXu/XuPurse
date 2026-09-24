import 'package:drift/drift.dart' show OrderingTerm, Value;

import '../../core/utils/ids.dart';
import '../seed/default_accounts.dart';
import '../seed/default_categories.dart';
import 'app_database.dart';
import 'global_database.dart';

/// 账本工厂与切换器。
///
/// - 全局库存账本列表；每个账本对应独立数据库 `book-<id>`，数据完全隔离。
/// - 新建账本时自动写入种子数据（默认分类、默认账户）。
/// - 测试时可注入内存数据库工厂（[DatabaseManager.inMemory]）。
class DatabaseManager {
  DatabaseManager({
    GlobalDatabase Function()? globalFactory,
    AppDatabase Function(String bookId)? bookFactory,
  }) : _globalFactory = globalFactory ?? GlobalDatabase.open,
       _bookFactory = bookFactory ?? AppDatabase.forBook;

  /// 测试专用：全部使用内存数据库。
  DatabaseManager.inMemory()
    : this(
        globalFactory: GlobalDatabase.memory,
        bookFactory: (_) => AppDatabase.memory(),
      );

  final GlobalDatabase Function() _globalFactory;
  final AppDatabase Function(String bookId) _bookFactory;

  GlobalDatabase? _global;
  final Map<String, AppDatabase> _openedBooks = {};
  String? _currentBookId;

  /// 打开（或复用）全局库
  Future<GlobalDatabase> global() async {
    if (_global == null) {
      final db = _globalFactory();
      await db.customSelect('SELECT 1').get();
      _global = db;
    }
    return _global!;
  }

  /// 全部账本列表（按创建时间升序）
  Future<List<Book>> listBooks() async {
    final globalDb = await global();
    return (globalDb.select(
      globalDb.books,
    )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();
  }

  /// 当前账本 ID
  String? get currentBookId => _currentBookId;

  /// 打开（或复用）账本库
  Future<AppDatabase> openBook(String bookId) async {
    final existing = _openedBooks[bookId];
    if (existing != null) {
      _currentBookId = bookId;
      return existing;
    }
    final db = _bookFactory(bookId);
    await db.customSelect('SELECT 1').get();
    _openedBooks[bookId] = db;
    _currentBookId = bookId;
    return db;
  }

  /// 当前账本库（未打开则抛错，调用方应先完成账本初始化流程）
  AppDatabase get current {
    final id = _currentBookId;
    final db = id == null ? null : _openedBooks[id];
    if (db == null) {
      throw StateError('当前没有已打开的账本，请先调用 openBook()');
    }
    return db;
  }

  /// 创建账本（全局库登记 + 建库 + 种子数据），返回账本 ID。
  Future<String> createBook({
    required String name,
    String baseCurrency = 'CNY',
    String? remark,
    String? id,
  }) async {
    final globalDb = await global();
    final bookId = id ?? genId();
    final now = DateTime.now().millisecondsSinceEpoch;
    await globalDb
        .into(globalDb.books)
        .insert(
          BooksCompanion.insert(
            id: bookId,
            name: name,
            baseCurrency: Value(baseCurrency),
            remark: Value(remark),
            createdAt: now,
            updatedAt: now,
          ),
        );
    final bookDb = await openBook(bookId);
    await seedBook(bookDb);
    return bookId;
  }

  /// 从备份注册账本（恢复用）：仅写全局登记，不写种子数据，不切换当前
  /// 账本。账本内业务数据由恢复流程逐表写入。
  Future<void> registerBook({
    required String id,
    required String name,
    String baseCurrency = 'CNY',
    String? remark,
    int? createdAt,
    int? updatedAt,
  }) async {
    final globalDb = await global();
    final now = DateTime.now().millisecondsSinceEpoch;
    await globalDb
        .into(globalDb.books)
        .insert(
          BooksCompanion.insert(
            id: id,
            name: name,
            baseCurrency: Value(baseCurrency),
            remark: Value(remark),
            createdAt: createdAt ?? now,
            updatedAt: updatedAt ?? now,
          ),
        );
  }

  /// 删除账本（级联：清空并关闭整个账本数据库 + 移除全局登记）。
  Future<void> deleteBook(String bookId) async {
    final db = _openedBooks.remove(bookId);
    if (db != null) {
      await db.wipe();
      await db.close();
    } else {
      // 未打开过的账本：临时打开只为清空数据（文件本身可能残留，内容已清空）。
      final fresh = _bookFactory(bookId);
      try {
        await fresh.wipe();
      } finally {
        await fresh.close();
      }
    }
    final globalDb = await global();
    await (globalDb.delete(
      globalDb.books,
    )..where((t) => t.id.equals(bookId))).go();
    if (_currentBookId == bookId) _currentBookId = null;
  }

  /// 切换账本
  Future<AppDatabase> switchBook(String bookId) => openBook(bookId);

  /// 打开账本库但不切换当前账本（备份导出等只读场景用，避免副作用
  /// 改变 [currentBookId] 导致当前账本被悄悄切换）。
  Future<AppDatabase> openBookReadOnly(String bookId) async {
    final existing = _openedBooks[bookId];
    if (existing != null) return existing;
    final db = _bookFactory(bookId);
    await db.customSelect('SELECT 1').get();
    _openedBooks[bookId] = db;
    return db;
  }

  /// 修改账本本位币（全局库 books.base_currency）。
  Future<void> updateBookBaseCurrency(String bookId, String code) async {
    final globalDb = await global();
    await (globalDb.update(
      globalDb.books,
    )..where((t) => t.id.equals(bookId))).write(
      BooksCompanion(baseCurrency: Value(code), updatedAt: Value(nowMs())),
    );
  }

  /// 种子数据：默认分类 + 默认账户 + 默认标签分组（幂等，按 key 判断跳过）。
  Future<void> seedBook(AppDatabase db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 分类
    final existing = await db.select(db.categories).get();
    final existingKeys = existing.map((c) => c.seedKey).toSet();
    for (final seed in allSeedCategories) {
      if (existingKeys.contains(seed.key)) continue;
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: genId(),
              type: seed.type.name,
              name: seed.name,
              icon: Value(seed.icon),
              color: Value(seed.color),
              parentId: const Value(null),
              seedKey: Value(seed.key),
              defaultSelect: Value(seed.defaultSelect),
              sort: Value(seed.sort),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    // 补齐父子关系（种子父分类的 id 需要按 key 查）
    {
      final all = await db.select(db.categories).get();
      final byKey = {
        for (final c in all)
          if (c.seedKey != null) c.seedKey!: c.id,
      };
      for (final seed in allSeedCategories) {
        if (seed.parentKey == null) continue;
        final childId = byKey[seed.key];
        final parentId = byKey[seed.parentKey];
        if (childId == null || parentId == null) continue;
        final child = all.firstWhere((c) => c.id == childId);
        if (child.parentId == parentId) continue;
        await (db.update(
          db.categories,
        )..where((t) => t.id.equals(childId))).write(
          CategoriesCompanion(parentId: Value(parentId), updatedAt: Value(now)),
        );
      }
    }

    // 默认账户
    final accounts = await db.select(db.accounts).get();
    if (accounts.isEmpty) {
      for (final seed in defaultAccounts) {
        await db
            .into(db.accounts)
            .insert(
              AccountsCompanion.insert(
                id: genId(),
                name: seed.name,
                category: seed.category,
                type: seed.type,
                icon: Value(seed.icon),
                color: Value(seed.color),
                initialBalance: Value(seed.initialBalance),
                currentBalance: Value(seed.initialBalance),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    }
  }

  /// 关闭全部数据库（应用退出）
  Future<void> dispose() async {
    for (final db in _openedBooks.values) {
      await db.close();
    }
    _openedBooks.clear();
    await _global?.close();
    _global = null;
    _currentBookId = null;
  }
}
