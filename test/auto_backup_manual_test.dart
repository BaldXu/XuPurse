import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:xupurse/data/backup/auto_backup_service.dart';
import 'package:xupurse/data/database/database_manager.dart';

/// 「立即备份」语义：立刻写一份，但不改 24 小时节奏（下次自动备份时间不变）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('xupurse/public_backup');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late DatabaseManager mgr;
  late AutoBackupService service;
  // 上次自动备份：1 小时前（未到 24h）
  final lastAt = DateTime.now().millisecondsSinceEpoch - 3600 * 1000;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AutoBackupService.kEnabled: true,
      AutoBackupService.kLastAt: lastAt,
      AutoBackupService.kIncludeSettings: false,
    });
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = (call.arguments as Map?) ?? const {};
      switch (call.method) {
        case 'save':
          return 'Download/XuPurse/${args['name']}';
        case 'list':
          return <Map<String, Object?>>[];
        case 'delete':
          return true;
        case 'location':
          return 'Download/XuPurse/';
      }
      return null;
    });

    mgr = DatabaseManager.inMemory();
    await mgr.createBook(name: '测试账本');
    service = AutoBackupService(mgr);
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await mgr.dispose();
  });

  test('立即备份（manual）不更新上次自动备份时间', () async {
    final prefs = await SharedPreferences.getInstance();

    final info = await service.run(manual: true);

    expect(info, contains('xupurse_auto_'));
    expect(
      prefs.getInt(AutoBackupService.kLastAt),
      lastAt,
      reason: '立即备份不能占用 24 小时节奏，否则下次自动备份会被推迟',
    );
  });

  test('立即备份后，24 小时检查仍会在到期时触发', () async {
    // 上次自动备份改成 25 小时前 → 立即备份过也不影响 maybeRun 触发
    final old = DateTime.now().millisecondsSinceEpoch - 25 * 3600 * 1000;
    SharedPreferences.setMockInitialValues({
      AutoBackupService.kEnabled: true,
      AutoBackupService.kLastAt: old,
      AutoBackupService.kIncludeSettings: false,
    });

    await service.run(manual: true);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(AutoBackupService.kLastAt), old);

    await service.maybeRun(); // 到期 → 真的跑一次自动备份
    expect(prefs.getInt(AutoBackupService.kLastAt), isNot(old));
    expect(
      prefs.getInt(AutoBackupService.kLastAt)!,
      greaterThan(DateTime.now().millisecondsSinceEpoch - 60 * 1000),
    );
  });

  test('自动备份（非 manual）会更新时间戳', () async {
    final prefs = await SharedPreferences.getInstance();

    await service.run();

    expect(prefs.getInt(AutoBackupService.kLastAt), greaterThan(lastAt));
  });

  test('立即备份成功后清掉上次失败原因', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AutoBackupService.kLastError, '上次失败了');

    await service.run(manual: true);

    expect(prefs.getString(AutoBackupService.kLastError), isNull);
  });
}
