/// Argon2id（64 MiB）派生在测试并行负载下较慢，放宽单测超时。
@Timeout.factor(4)
library;

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xupurse/data/backup/backup_service.dart';
import 'package:xupurse/data/backup/encryption_service.dart';
import 'package:xupurse/data/backup/restore_service.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';

void main() {
  // 并行测试负载下标准 Argon2id 派生极慢，用轻量参数保证套件稳定。
  BackupEncryption.fastKdf = true;

  late DatabaseManager manager;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'theme_current_id': 'preset_klein',
    });
    manager = DatabaseManager.inMemory();
  });

  tearDown(() async {
    await manager.dispose();
  });

  /// 造一个带账户 + 账单的账本并导出备份。
  Future<String> exportBookWithData(String name) async {
    final bookId = await manager.createBook(name: name);
    final db = await manager.openBook(bookId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: 'acc-1',
            name: '现金',
            category: 'fund',
            type: 'cash',
            initialBalance: const Value(100),
            currentBalance: const Value(100),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.bills)
        .insert(
          BillsCompanion.insert(
            id: 'bill-1',
            type: 'expense',
            categoryId: 'cat-1',
            amount: 50,
            time: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return BackupService(manager).exportAll();
  }

  group('RestoreService 覆盖恢复', () {
    test('覆盖恢复完整还原账本与数据', () async {
      final json = await exportBookWithData('甲');
      // 制造差异：现有数据包含额外账本
      await manager.createBook(name: '乙');
      expect(await manager.listBooks(), hasLength(2));

      await RestoreService(manager).restore(json, mode: RestoreMode.overwrite);

      final books = await manager.listBooks();
      expect(books, hasLength(1));
      expect(books.single.name, '甲');
      final db = await manager.openBook(books.single.id);
      final accounts = await db.select(db.accounts).get();
      final bills = await db.select(db.bills).get();
      // 账本含 4 个种子账户 + 自建账户，按自建账户 ID 断言
      final cash = accounts.firstWhere((a) => a.id == 'acc-1');
      expect(cash.name, '现金');
      expect(cash.currentBalance, 100);
      expect(bills.single.amount, 50);
    });
  });

  group('RestoreService 追加恢复', () {
    test('追加恢复导入为新账本，现有数据不动', () async {
      final bookId = await manager.createBook(name: '甲');
      final db = await manager.openBook(bookId);
      final now = DateTime.now().millisecondsSinceEpoch;
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'acc-1',
              name: '现金',
              category: 'fund',
              type: 'cash',
              initialBalance: const Value(100),
              currentBalance: const Value(100),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final json = await BackupService(manager).exportAll();
      await manager.createBook(name: '乙');

      await RestoreService(manager).restore(json, mode: RestoreMode.append);

      final books = await manager.listBooks();
      expect(books, hasLength(3)); // 甲 + 乙 + 备份导入的甲（新 ID）
      // 原账本 ID 保留一个，导入副本使用新 ID
      expect(books.where((b) => b.id == bookId), hasLength(1));
      final imported = books.firstWhere((b) => b.name == '甲' && b.id != bookId);
      final importedDb = await manager.openBook(imported.id);
      final accounts = await importedDb.select(importedDb.accounts).get();
      // 导入副本同样含种子账户，按自建账户 ID 断言
      final cash = accounts.firstWhere((a) => a.id == 'acc-1');
      expect(cash.name, '现金');
      expect(cash.currentBalance, 100);
    });
  });

  group('RestoreService 格式校验', () {
    test('非本应用格式抛 UnsupportedBackupException', () {
      expect(
        () => RestoreService.inspect('{"foo": 1}'),
        throwsA(isA<UnsupportedBackupException>()),
      );
      expect(
        () => RestoreService.inspect('不是 JSON'),
        throwsA(isA<UnsupportedBackupException>()),
      );
      expect(
        () => RestoreService.inspect('[1, 2, 3]'),
        throwsA(isA<UnsupportedBackupException>()),
      );
    });

    test('版本过新 / 过旧均拒绝', () {
      final tooNew = '{"format": "xupurse-backup", "version": 99, "books": []}';
      final tooOld = '{"format": "xupurse-backup", "version": 1, "books": []}';
      expect(
        () => RestoreService.inspect(tooNew),
        throwsA(isA<UnsupportedBackupException>()),
      );
      expect(
        () => RestoreService.inspect(tooOld),
        throwsA(isA<UnsupportedBackupException>()),
      );
    });

    test('inspect 返回账本名与设置标记', () async {
      final json = await exportBookWithData('甲');
      final summary = RestoreService.inspect(json);
      expect(summary.bookNames, ['甲']);
      expect(summary.hasSettings, isTrue);
    });
  });

  group('RestoreService 设置与加密', () {
    test('覆盖恢复应用设置', () async {
      await manager.createBook(name: '甲');
      final json = await BackupService(manager).exportAll();
      // 改动现有设置，再覆盖恢复
      SharedPreferences.setMockInitialValues({
        'theme_current_id': 'preset_dark',
      });
      await RestoreService(
        manager,
      ).restore(json, mode: RestoreMode.overwrite, overwriteSettings: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_current_id'), 'preset_klein');
    });

    test('不勾选时不动应用设置', () async {
      await manager.createBook(name: '甲');
      final json = await BackupService(manager).exportAll();
      SharedPreferences.setMockInitialValues({
        'theme_current_id': 'preset_dark',
      });
      await RestoreService(
        manager,
      ).restore(json, mode: RestoreMode.overwrite, overwriteSettings: false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_current_id'), 'preset_dark');
    });

    test('加密备份解密后可恢复', () async {
      final json = await exportBookWithData('甲');
      final enc = await BackupService(
        manager,
      ).exportAll(password: 'password123');
      // 页面流程：识别加密 → 解密 → 校验 → 恢复
      final decrypted = await BackupEncryption.decryptJson(enc, 'password123');
      final summary = RestoreService.inspect(decrypted);
      expect(summary.bookNames, ['甲']);
      await RestoreService(
        manager,
      ).restore(decrypted, mode: RestoreMode.overwrite);
      expect(await manager.listBooks(), hasLength(1));
      expect(json, isNotEmpty);
    });
  });
}
