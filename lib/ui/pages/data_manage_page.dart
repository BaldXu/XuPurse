import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backup/backup_service.dart';
import '../../data/backup/saver.dart';
import '../../state/providers.dart';
import 'import_page.dart';

/// 数据管理页：第三方数据导入 + 备份导出。
class DataManagePage extends ConsumerStatefulWidget {
  const DataManagePage({super.key});

  @override
  ConsumerState<DataManagePage> createState() => _DataManagePageState();
}

class _DataManagePageState extends ConsumerState<DataManagePage> {
  bool _exporting = false;

  Future<void> _exportBackup() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final mgr = ref.read(databaseManagerProvider);
      final bookId = mgr.currentBookId;
      if (bookId == null) return;
      final global = await mgr.global();
      final json = await BackupService(ref.read(dbProvider), global).exportBook(
        bookId,
      );
      final name = 'xupurse_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final path = await saveBackupFile(name, json);
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('备份已导出：$path')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('备份失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('数据导入'),
                  subtitle: const Text('导入一木 / 昼虎 / 钱迹备份 .db 文件'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ImportPage()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('备份导出'),
                  subtitle: const Text('导出当前账本全部数据为 JSON 文件'),
                  trailing: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right, size: 20),
                  onTap: _exportBackup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
