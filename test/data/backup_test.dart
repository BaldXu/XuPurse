/// Argon2id（64 MiB）派生在测试并行负载下较慢，放宽单测超时。
@Timeout.factor(4)
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xupurse/data/backup/backup_service.dart';
import 'package:xupurse/data/backup/encryption_service.dart';
import 'package:xupurse/data/database/database_manager.dart';

void main() {
  // 并行测试负载下标准 Argon2id 派生极慢，用轻量参数保证套件稳定。
  BackupEncryption.fastKdf = true;

  group('BackupEncryption 加密解密', () {
    test('加密后解密还原原文', () async {
      const plain = '{"hello":"world","n":42}';
      final enc = await BackupEncryption.encryptJson(plain, 'password123');
      // 信封自描述 + 密文与原文不同
      final map = jsonDecode(enc) as Map<String, dynamic>;
      expect(map['format'], BackupEncryption.formatName);
      expect(map['enc'], BackupEncryption.envelopeMagic);
      expect(map['data'], isNot(contains('world')));

      final dec = await BackupEncryption.decryptJson(enc, 'password123');
      expect(dec, plain);
    });

    test('同一密码两次加密密文不同（随机 salt/nonce）', () async {
      const plain = 'same content';
      final a = await BackupEncryption.encryptJson(plain, 'password123');
      final b = await BackupEncryption.encryptJson(plain, 'password123');
      expect(a, isNot(b));
    });

    test('错误密码抛 InvalidPasswordException', () async {
      final enc = await BackupEncryption.encryptJson('secret', 'password123');
      await expectLater(
        BackupEncryption.decryptJson(enc, 'wrongpass1'),
        throwsA(isA<InvalidPasswordException>()),
      );
    });

    test('未加密内容抛 FormatException', () async {
      await expectLater(
        BackupEncryption.decryptJson('{"a":1}', 'password123'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('BackupService 全量导出', () {
    late DatabaseManager manager;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'theme_current_id': 'preset_klein',
        'ui_transition_blur': false,
      });
      manager = DatabaseManager.inMemory();
    });

    tearDown(() async {
      await manager.dispose();
    });

    test('导出全部账本 + 设置', () async {
      await manager.createBook(name: '账本A');
      await manager.createBook(name: '账本B');

      final json = await BackupService(manager).exportAll();
      final map = jsonDecode(json) as Map<String, dynamic>;

      expect(map['format'], BackupEncryption.formatName);
      expect(map['version'], BackupEncryption.formatVersion);
      expect(map['books'], hasLength(2));
      final firstBook = (map['books'] as List).first as Map<String, dynamic>;
      expect(firstBook['data'], isA<Map>());
      expect((firstBook['data'] as Map)['accounts'], isA<List>());
      expect((firstBook['data'] as Map)['categories'], isA<List>());

      final settings = map['settings'] as Map<String, dynamic>;
      expect(settings['theme_current_id'], 'preset_klein');
      expect(settings['ui_transition_blur'], false);
    });

    test('加密导出可用密码还原为同一负载', () async {
      await manager.createBook(name: '账本A');
      await manager.createBook(name: '账本B');

      final plain = await BackupService(manager).exportAll();
      final enc = await BackupService(
        manager,
      ).exportAll(password: 'password123');

      // 密文负载不含明文特征
      final encMap = jsonDecode(enc) as Map<String, dynamic>;
      expect(encMap['enc'], BackupEncryption.envelopeMagic);

      // 解密后与明文导出等价（books 内容一致）
      final dec = await BackupEncryption.decryptJson(enc, 'password123');
      final decMap = jsonDecode(dec) as Map<String, dynamic>;
      final plainMap = jsonDecode(plain) as Map<String, dynamic>;
      expect(decMap['books'], plainMap['books']);
      expect(decMap['settings'], plainMap['settings']);
    });
  });
}
