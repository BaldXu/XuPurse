import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xupurse/data/backup/auto_backup_store.dart';

/// 定时备份落盘行为测试（Android 分支，通道用 mock 顶替原生实现）。
///
/// 关键约束：备份必须写到应用沙箱之外，否则卸载即丢。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('xupurse/public_backup');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;
  late List<Map<String, Object?>> files;

  void mockChannel() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = (call.arguments as Map?) ?? const {};
      switch (call.method) {
        case 'save':
          final name = args['name'] as String;
          files.add({'name': name, 'size': 10, 'modified': 0});
          return 'Download/XuPurse/$name';
        case 'saveTo':
          final name = args['name'] as String;
          files.add({'name': name, 'size': 10, 'modified': 0});
          return name;
        case 'list':
        case 'listIn':
          return files;
        case 'delete':
        case 'deleteIn':
          final name = args['name'] as String;
          files.removeWhere((f) => f['name'] == name);
          return true;
        case 'read':
        case 'readFrom':
          return '{"bills":[]}';
        case 'location':
          return 'Download/XuPurse/';
        case 'pickTree':
          return 'content://com.android.externalstorage.documents/tree/primary%3A1111%2F记账%2Fxupurse';
        case 'treeLabel':
          return 'primary:1111/记账/xupurse';
      }
      return null;
    });
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    files = [];
    mockChannel();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('Android 上备份写入公共目录，文件名带时间戳', () async {
    expect(usesPublicBackupDir, isTrue);

    final path = await saveAutoBackup('{"a":1}');

    expect(path, startsWith('Download/XuPurse/xupurse_auto_'));
    expect(path, endsWith('.json'));
    final saved = calls.firstWhere((c) => c.method == 'save');
    expect(
      (saved.arguments as Map)['name'],
      matches(RegExp(r'^xupurse_auto_\d{8}_\d{6}\.json$')),
    );
  });

  test('轮换只删多余的自有备份，不碰手动备份文件', () async {
    // 已有 7 份自动备份 + 1 份手动备份
    files = [
      for (var i = 1; i <= 7; i++)
        {
          'name': 'xupurse_auto_2026100${i}_120000.json',
          'size': 1,
          'modified': 0,
        },
      {'name': 'xupurse_manual_20261001.json', 'size': 1, 'modified': 0},
    ];

    await saveAutoBackup('{}'); // 新增 1 份 → 8 份，保留 5

    final deleted = calls
        .where((c) => c.method == 'delete')
        .map((c) => (c.arguments as Map)['name'] as String)
        .toList();
    expect(deleted, contains('xupurse_auto_20261001_120000.json'));
    expect(deleted, contains('xupurse_auto_20261002_120000.json'));
    expect(deleted, contains('xupurse_auto_20261003_120000.json'));
    expect(deleted, isNot(contains('xupurse_manual_20261001.json')));
  });

  test('配置了自选目录（SAF 树 URI）就写该目录，并显示人话路径', () async {
    const tree =
        'content://com.android.externalstorage.documents/tree/primary%3A1111%2F记账%2Fxupurse';

    final path = await saveAutoBackup('{}', dir: tree);

    final saved = calls.firstWhere((c) => c.method == 'saveTo');
    expect((saved.arguments as Map)['tree'], tree);
    expect(path, startsWith('内部存储/1111/记账/xupurse/xupurse_auto_'));
    expect(path, endsWith('.json'));
    // 没有走默认公共目录
    expect(calls.where((c) => c.method == 'save'), isEmpty);
  });

  test('自选目录不可用时自动退回默认公共目录，不丢这次备份', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = (call.arguments as Map?) ?? const {};
      if (call.method == 'saveTo') {
        throw PlatformException(code: 'public_backup_failed', message: 'no access');
      }
      if (call.method == 'listIn') {
        throw PlatformException(code: 'public_backup_failed', message: 'no access');
      }
      if (call.method == 'save') return 'Download/XuPurse/${args['name']}';
      if (call.method == 'list') return <Map<String, Object?>>[];
      return null;
    });

    final path = await saveAutoBackup('{}', dir: 'content://tree/nope');

    expect(path, startsWith('Download/XuPurse/xupurse_auto_'));
    expect(calls.where((c) => c.method == 'save'), isNotEmpty);
  });

  test('树 URI 转人话：内部存储 / SD 卡卷', () {
    expect(
      treeDirLabel(
        'content://x/tree/primary%3A1111%2F记账%2Fxupurse',
      ),
      '内部存储/1111/记账/xupurse',
    );
    expect(
      treeDirLabel('content://x/tree/1A2B-3C4D%3A记账'),
      '存储卡 1A2B-3C4D/记账',
    );
    expect(isTreeUri('content://x/tree/primary%3Aabc'), isTrue);
    expect(isTreeUri('/sdcard/XuPurse'), isFalse);
  });

  test('读取时优先自选目录里最新的一份', () async {
    const tree = 'content://x/tree/primary%3Aaa';
    files = [
      {'name': 'xupurse_auto_20261003_120000.json', 'size': 1, 'modified': 0},
      {'name': 'xupurse_auto_20261001_120000.json', 'size': 1, 'modified': 0},
    ];

    final content = await readAutoBackup(dir: tree);

    expect(content, '{"bills":[]}');
    final read = calls.firstWhere((c) => c.method == 'readFrom');
    expect((read.arguments as Map)['name'], 'xupurse_auto_20261003_120000.json');
  });
}
