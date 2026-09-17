import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import 'db_reader.dart';
import 'id_mapping.dart';
import 'import_models.dart';
import 'qianji_mapper.dart';
import 'qianji_parser.dart';
import 'yimu_mapper.dart';
import 'yimu_parser.dart';
import 'zhouhu_mapper.dart';
import 'zhouhu_parser.dart';

/// 第三方导入引擎主入口（算法七：parse → map → preview → write → mapping）。
///
/// - [preview]：读取 .db 字节流 → 解析 → 映射 → 产出预览（统计 + 合并候选）。
/// - [write]：把预览结果在单个事务内写库（账单以第三方权威余额为准，不触发
///   余额自动加减），末尾统一落表 import_mappings 保证幂等。
class ImportService {
  ImportService(this._db);

  final AppDatabase _db;

  /// 解析并映射，产出预览结果（不写库）。
  Future<ImportPreview> preview({
    required ImportSource source,
    required Uint8List bytes,
    String fileName = '',
  }) async {
    final parsed = _parse(source, bytes);
    final idMapper = IdMapper(_db, source);
    await idMapper.loadAll();
    final ctx = MapperContext(
      accounts: await (_db.select(_db.accounts)).get(),
      categories: await (_db.select(_db.categories)).get(),
    );
    final mapped = _map(source, parsed, idMapper, ctx);
    final candidates = _detectMergeCandidates(ctx.accounts, mapped.accounts);
    return ImportPreview(
      source: source,
      fileName: fileName,
      mapped: mapped,
      idMapper: idMapper,
      mergeCandidates: candidates,
    );
  }

  /// 把 [preview] 的结果写入数据库（单事务）。
  ///
  /// [mergeMap]：本次确认执行的同名账户合并，key=本次导入的新账户 id，
  /// value=保留的现有账户 id（算法八）。
  Future<ImportWriteResult> write(
    ImportPreview preview, {
    Map<String, String> mergeMap = const {},
  }) async {
    final mapped = preview.mapped;
    final idMapper = preview.idMapper;
    final merge = Map<String, String>.from(mergeMap);
    final mergedIncoming = merge.keys.toSet();

    var created = 0;
    var updated = 0;

    String? r(String? id) => id == null ? null : merge[id] ?? id;

    await _db.transaction(() async {
      // 0. 合并账户：把被合并账户的第三方映射重定向到保留账户（幂等），
      //    并记录 incoming 的第三方权威余额，供下方步骤 1.5 转给保留账户。
      final inheritBalances = <String, ({int initial, int current})>{};
      for (final c in mapped.accounts) {
        final id = c.id.value;
        if (!mergedIncoming.contains(id)) continue;
        final srcId =
            c.yimuAssetId.value ??
            c.zhouhuAccountId.value ??
            c.qianjiAssetId.value;
        final target = merge[id];
        if (srcId != null && target != null) {
          idMapper.overrideTargetSync('account', '$srcId', target);
        }
        if (target != null) {
          inheritBalances[id] = (
            initial: c.initialBalance.present ? c.initialBalance.value : 0,
            current: c.currentBalance.present ? c.currentBalance.value : 0,
          );
        }
      }

      // 1. 账户
      for (final c in mapped.accounts) {
        if (mergedIncoming.contains(c.id.value)) continue;
        created += await _upsert(_db.accounts, c, idMapper);
      }

      // 1.5 合并余额继承（必须在账单写入前判断 target 是否已有流水）：
      //     导入不触发余额自动加减，incoming 的权威余额只存在于账户字段中，
      //     若不转移，保留账户（如默认支付宝/微信）合并后余额仍为 0。
      //     - target 无任何账单（空账户）：直接继承第三方权威余额（含初始余额）。
      //     - target 已有账单：叠加 incoming 的净变化（current - initial），
      //       初始余额不动；与手动调账配合可进一步校正。
      for (final e in inheritBalances.entries) {
        final targetId = merge[e.key]!;
        final incoming = e.value;
        final targetRow = await (_db.select(
          _db.accounts,
        )..where((t) => t.id.equals(targetId))).getSingleOrNull();
        if (targetRow == null) continue;
        final billCount = await _db
            .customSelect(
              'SELECT COUNT(*) AS c FROM bills '
              'WHERE account_id = ? OR income_account_id = ?',
              variables: [Variable(targetId), Variable(targetId)],
            )
            .getSingle();
        final hasBills = (billCount.data['c'] as int) > 0;
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(targetId))).write(
          hasBills
              ? AccountsCompanion(
                  currentBalance: Value(
                    targetRow.currentBalance +
                        incoming.current -
                        incoming.initial,
                  ),
                  updatedAt: Value(nowMs()),
                )
              : AccountsCompanion(
                  initialBalance: Value(incoming.initial),
                  currentBalance: Value(incoming.current),
                  updatedAt: Value(nowMs()),
                ),
        );
      }

      // 2. 分类
      for (final c in mapped.categories) {
        created += await _upsert(_db.categories, c, idMapper);
      }

      // 3. 标签
      for (final c in mapped.tags) {
        created += await _upsert(_db.tags, c, idMapper);
      }

      // 4. 账单 + 标签关联（合并替换账户引用）
      for (final c in mapped.bills) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(
            accountId: Value<String?>(r(c.accountId.value)),
            incomeAccountId: Value<String?>(r(c.incomeAccountId.value)),
          );
        }
        created += await _upsert(_db.bills, cc, idMapper);
        final tagIds = mapped.billTagIds[cc.id.value];
        if (tagIds != null && tagIds.isNotEmpty) {
          await (_db.delete(
            _db.billTags,
          )..where((t) => t.billId.equals(cc.id.value))).go();
          for (final tagId in tagIds) {
            await _db
                .into(_db.billTags)
                .insert(
                  BillTagsCompanion.insert(billId: cc.id.value, tagId: tagId),
                  mode: InsertMode.insertOrIgnore,
                );
          }
        }
      }

      // 5. 快照
      for (final c in mapped.snapshots) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(accountId: Value<String>(r(c.accountId.value) ?? ''));
        }
        created += await _upsert(_db.balanceSnapshots, cc, idMapper);
      }

      // 6. 转账扩展
      for (final c in mapped.transfers) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(
            fromAccountId: Value<String>(r(c.fromAccountId.value) ?? ''),
            toAccountId: Value<String>(r(c.toAccountId.value) ?? ''),
          );
        }
        created += await _upsert(_db.transfers, cc, idMapper);
      }

      // 7. 借贷
      for (final c in mapped.lends) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(
            accountId: Value<String>(r(c.accountId.value) ?? ''),
            repaymentAccountId: Value<String?>(r(c.repaymentAccountId.value)),
          );
        }
        created += await _upsert(_db.lends, cc, idMapper);
      }

      // 8. 退款 / 报销 / 分期（引用账单与账户，合并时替换账户引用）
      for (final c in mapped.refunds) {
        created += await _upsert(_db.refunds, c, idMapper);
      }
      for (final c in mapped.reimbursements) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(
            accountId: Value<String?>(r(c.accountId.value)),
            reimbursementAccountId: Value<String?>(
              r(c.reimbursementAccountId.value),
            ),
          );
        }
        created += await _upsert(_db.reimbursements, cc, idMapper);
      }
      for (final c in mapped.instalments) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(accountId: Value<String>(r(c.accountId.value) ?? ''));
        }
        created += await _upsert(_db.instalments, cc, idMapper);
      }

      // 9. 预算
      for (final c in mapped.budgets) {
        created += await _upsert(_db.budgets, c, idMapper);
      }

      // 10. 映射写回（幂等保证）
      await idMapper.flush();
    });

    return ImportWriteResult(
      created: created,
      updated: updated,
      skippedAccounts: mapped.stats.createdOf('skipped'),
      mergedAccounts: mergedIncoming.length,
    );
  }

  /// 新增则 insert、已存在则 update；返回本次新增数（0/1）。
  ///
  /// 用 dynamic 统一处理各表（全部表都有 id 主键），集中一处避免 14 份重复代码。
  Future<int> _upsert(dynamic table, dynamic entry, IdMapper idMapper) async {
    final id = (entry.id as Value<String>).value;
    final isNew = idMapper.createdTargetIds.contains(id);
    if (isNew) {
      await _db.into(table).insert(entry);
      return 1;
    }
    await (_db.update(
      table,
    )..where((t) => (t as dynamic).id.equals(id))).write(entry);
    return 0;
  }
}

/// 解析 .db 字节流（读取完立即释放连接）。
Object _parse(ImportSource source, Uint8List bytes) {
  final db = openDatabaseFromBytes(bytes);
  try {
    return switch (source) {
      ImportSource.yimu => parseYimuDB(db),
      ImportSource.zhouhu => parseZhouhuDB(db),
      ImportSource.qianji => parseQianjiDB(db),
    };
  } finally {
    db.dispose();
  }
}

MappedImport _map(
  ImportSource source,
  Object parsed,
  IdMapper idMapper,
  MapperContext ctx,
) {
  return switch (source) {
    ImportSource.yimu => mapYimuToXuPurse(
      parsed as YimuParsedData,
      idMapper,
      ctx,
    ),
    ImportSource.zhouhu => mapZhouhuToXuPurse(
      parsed as ZhouhuParsedData,
      idMapper,
      ctx,
    ),
    ImportSource.qianji => mapQianjiToXuPurse(
      parsed as QianjiParsedData,
      idMapper,
      ctx,
    ),
  };
}

/// 同名账户合并候选检测（算法八，第一版：同名即候选，需用户确认）。
List<AccountMergeCandidate> _detectMergeCandidates(
  List<Account> existing,
  List<AccountsCompanion> incoming,
) {
  final result = <AccountMergeCandidate>[];
  if (existing.isEmpty || incoming.isEmpty) return result;

  final existingByName = <String, Account>{};
  for (final a in existing) {
    final key = _normalizeAccountName(a.name);
    if (key.isEmpty) continue;
    existingByName.putIfAbsent(key, () => a);
  }

  final seen = <String>{};
  for (final c in incoming) {
    final name = c.name.value;
    final key = _normalizeAccountName(name);
    if (key.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    final target = existingByName[key];
    if (target == null) continue;
    result.add(
      AccountMergeCandidate(
        sourceId: c.id.value,
        targetId: target.id,
        name: name,
        targetName: target.name,
        autoMerge: false,
      ),
    );
  }
  return result;
}

/// 账户名归一化：去括号内容、空格、卡号尾号、统一小写。
String _normalizeAccountName(String name) {
  var n = name.trim();
  n = n.replaceAll(RegExp(r'[（(].*?[）)]'), ''); // 「支付宝（尾号1234）」
  n = n.replaceAll(RegExp(r'(尾号|卡号|#)\s*\d{2,}'), ''); // 尾号8888
  n = n.replaceAll(RegExp(r'[#*]{2,}\d{2,}'), ''); // ****8888
  n = n.replaceAll(RegExp(r'\s+'), '');
  return n.toLowerCase();
}
