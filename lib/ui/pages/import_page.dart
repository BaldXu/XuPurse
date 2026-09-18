import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../data/import/import_models.dart';
import '../../state/providers.dart';

/// 数据导入页（一木 / 昼虎 / 钱迹）。
///
/// 三步流程：选择来源与文件 → 预览统计与同名账户合并候选 → 确认导入并展示结果。
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  ImportSource? _source;
  PlatformFile? _file;
  ImportPreview? _preview;
  final Set<String> _mergeSelections = {};
  bool _importing = false;
  ImportWriteResult? _result;
  String? _error;

  static const _sourceInfo = {
    ImportSource.yimu: (name: '一木记账', desc: '导入 一木记账 的备份 .db 文件'),
    ImportSource.zhouhu: (name: '昼虎记账', desc: '导入 昼虎记账 的备份 .db 文件'),
    ImportSource.qianji: (name: '钱迹', desc: '导入 钱迹 的备份 .db 文件'),
  };

  static const _entityNames = {
    'account': '账户',
    'category': '分类',
    'tag': '标签',
    'bill': '账单',
    'snapshot': '快照',
    'transfer': '转账',
    'lend': '借贷',
    'refund': '退款',
    'reimbursement': '报销',
    'instalment': '分期',
    'budget': '预算',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据导入')),
      body: _result != null
          ? _buildResult()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSourceSelector(),
                const SizedBox(height: 16),
                _buildFilePicker(),
                if (_error != null) _buildError(),
                if (_preview != null) ...[
                  const SizedBox(height: 16),
                  _buildPreview(),
                  if (_preview!.mergeCandidates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildMergeCandidates(),
                  ],
                  if (_preview!.mapped.warnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildWarnings(),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _importing ? null : _import,
                    icon: _importing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_done),
                    label: Text(_importing ? '导入中…' : '确认导入'),
                  ),
                ],
              ],
            ),
    );
  }

  // ---------- 步骤 1：来源 ----------

  Widget _buildSourceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择来源', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        RadioGroup<ImportSource>(
          groupValue: _source,
          onChanged: (v) => setState(() {
            _source = v;
            _file = null;
            _preview = null;
            _result = null;
            _error = null;
          }),
          child: Column(
            children: [
              for (final entry in _sourceInfo.entries)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<ImportSource>(
                    value: entry.key,
                    title: Text(entry.value.name),
                    subtitle: Text(entry.value.desc),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- 步骤 1：文件 ----------

  Widget _buildFilePicker() {
    final enabled = _source != null;
    return Card(
      child: ListTile(
        enabled: enabled,
        leading: const Icon(Icons.folder_open),
        title: Text(_file?.name ?? '选择备份文件'),
        subtitle: Text(
          _file == null
              ? '支持 .db 备份文件（需 ${_source == null ? '先选择来源' : '${_sourceInfo[_source]!.name} 导出的数据库'}）'
              : '${_file!.size} 字节',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: enabled ? _pickFile : null,
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      // 用 FileType.any 而非 custom+db：部分平台不支持 db 扩展名过滤
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!file.name.toLowerCase().endsWith('.db')) {
        setState(() {
          _error = '请选择 .db 备份文件（当前文件：${file.name}）';
          _file = null;
        });
        return;
      }
      setState(() {
        _file = file;
        _preview = null;
        _result = null;
        _error = null;
      });
      await _doPreview();
    } catch (e) {
      setState(() => _error = '读取文件失败：$e');
    }
  }

  Future<void> _doPreview() async {
    final file = _file;
    final source = _source;
    if (file == null || source == null || file.bytes == null) return;
    setState(() {
      _preview = null;
      _error = null;
    });
    try {
      final preview = await ref
          .read(importServiceProvider)
          .preview(source: source, bytes: file.bytes!, fileName: file.name);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        // 默认勾选可自动合并的同名候选（时间范围不冲突）：用户以第三方权威
        // 数据为准，同名账户默认应合并而非新增重复账户；时间范围冲突的候选
        // 需用户逐条确认，不预选。
        _mergeSelections
          ..clear()
          ..addAll(
            preview.mergeCandidates
                .where((c) => c.autoMerge)
                .map((c) => c.sourceId),
          );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '解析失败，请确认文件为 ${_sourceInfo[source]!.name} 备份：$e');
    }
  }

  Widget _buildError() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!)),
          ],
        ),
      ),
    );
  }

  // ---------- 步骤 2：预览 ----------

  Widget _buildPreview() {
    final preview = _preview!;
    final stats = preview.mapped.stats;
    final names = <String, int>{};
    for (final type in stats.createdTypes) {
      names[type] = stats.createdOf(type);
    }
    for (final type in stats.updatedTypes) {
      names[type] = (names[type] ?? 0) + stats.updatedOf(type);
    }
    final ordered = names.keys.toList()
      ..sort((a, b) => (_entityNames[a] ?? a).compareTo(_entityNames[b] ?? b));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('预览', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '共 ${stats.totalCreated} 新增 · ${stats.totalUpdated} 更新',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in ordered)
                  Chip(
                    label: Text('${_entityNames[type] ?? type} ${names[type]}'),
                    avatar: stats.createdOf(type) > 0
                        ? const Icon(Icons.add, size: 16)
                        : const Icon(Icons.refresh, size: 16),
                  ),
                if (preview.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('未检测到可导入的数据'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 步骤 2：同名账户合并 ----------

  Widget _buildMergeCandidates() {
    final preview = _preview!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('同名账户合并', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '检测到与现有账户同名的账户。合并方向按数据时间戳决定（更新更晚的'
              '账户作为保留方）；勾选后账单将归入保留账户且不会新增重复账户。'
              '保留账户继承导入数据的权威余额，其余引用一并转移。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final c in preview.mergeCandidates)
              CheckboxListTile(
                value: _mergeSelections.contains(c.sourceId),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _mergeSelections.add(c.sourceId);
                  } else {
                    _mergeSelections.remove(c.sourceId);
                  }
                }),
                title: Text('「${c.name}」→「${c.targetName ?? '新账户'}」'),
                subtitle: c.autoMerge
                    ? null
                    : Text(
                        '${c.conflictReason ?? '存在冲突'}，请确认是否合并',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
          ],
        ),
      ),
    );
  }

  // ---------- 步骤 2：警告 ----------

  Widget _buildWarnings() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('导入提示', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            for (final w in _preview!.mapped.warnings)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $w',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- 步骤 3：导入 ----------

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      final mergeMap = {
        for (final c in preview.mergeCandidates)
          if (_mergeSelections.contains(c.sourceId)) c.sourceId: c.targetId,
      };
      final result = await ref
          .read(importServiceProvider)
          .write(preview, mergeMap: mergeMap);
      if (!mounted) return;
      setState(() {
        _result = result;
        _importing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _error = '导入失败：$e';
      });
    }
  }

  Widget _buildResult() {
    final r = _result!;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('导入完成', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            _ResultRow(label: '新增', value: '${r.created}'),
            _ResultRow(label: '更新', value: '${r.updated}'),
            if (r.skippedAccounts > 0)
              _ResultRow(label: '跳过（账户缺失）', value: '${r.skippedAccounts}'),
            if (r.mergedAccounts > 0)
              _ResultRow(label: '合并账户', value: '${r.mergedAccounts}'),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
