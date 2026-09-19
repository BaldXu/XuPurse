import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/account_name.dart';
import '../../core/utils/bill_extra.dart';
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
    final parsed = await _parse(source, bytes);
    final idMapper = IdMapper(_db, source);
    await idMapper.loadAll();
    final ctx = MapperContext(
      accounts: await (_db.select(_db.accounts)).get(),
      categories: await (_db.select(_db.categories)).get(),
    );
    final mapped = _map(source, parsed, idMapper, ctx);
    final existingBills = await (_db.select(_db.bills)).get();
    final candidates = _detectMergeCandidates(
      ctx.accounts,
      mapped.accounts,
      existingBills,
      mapped.bills,
    );
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
  /// [mergeMap]：本次确认执行的同名账户合并，key=被合并账户 id（可能是本次
  /// 导入的新账户或现有账户），value=保留账户 id（算法八，方向由 updatedAt
  /// 决定：更新更晚的一方为保留方）。
  ///
  /// [mode]：写库策略——覆盖（默认，已导入过的记录用本次数据覆盖）或增量
  /// （已导入过的记录跳过，只新增本次新数据）。
  Future<ImportWriteResult> write(
    ImportPreview preview, {
    Map<String, String> mergeMap = const {},
    ImportMode mode = ImportMode.overwrite,
  }) async {
    final mapped = preview.mapped;
    final idMapper = preview.idMapper;
    final merge = Map<String, String>.from(mergeMap);
    final skipExisting = mode == ImportMode.incremental;

    var created = 0;
    var updated = 0;
    var skipped = 0;
    void countSkip() => skipped++;
    void countUpdate() => updated++;

    String? r(String? id) => id == null ? null : merge[id] ?? id;

    // 覆盖模式：新增则 insert、已存在则 update；增量模式：已存在则跳过。
    Future<int> upsert(dynamic table, dynamic entry) => _upsert(
      table,
      entry,
      idMapper,
      skipExisting: skipExisting,
      onSkip: countSkip,
      onUpdate: countUpdate,
    );

    await _db.transaction(() async {
      // 0. 拆分合并方向：key 可能是「本次导入的新账户」（incoming 作为 source，
      //    现有账户保留，走下方 0b/1.5）或「现有账户」（existing 作为 source，
      //    本次导入的新账户保留，走 0a：重定向其在库中的全部引用并删除）。
      final incomingIds = {for (final c in mapped.accounts) c.id.value};
      final incomingSources = <String, String>{};
      final existingSources = <String, String>{};
      for (final e in merge.entries) {
        if (incomingIds.contains(e.key)) {
          incomingSources[e.key] = e.value;
        } else {
          existingSources[e.key] = e.value;
        }
      }
      final mergedIncoming = incomingSources.keys.toSet();
      // 0a. existing 作为 source：库内引用重定向到保留方（incoming 账户），
      //     删除被合并的现有账户行；保留方以自身权威余额为准，账单写入后
      //     反推 initialBalance（步骤 4.5）保证重算自洽。
      final backComputeInitial = <String>{};
      for (final e in existingSources.entries) {
        await _redirectExistingAccount(e.key, e.value);
        await (_db.delete(_db.accounts)..where((t) => t.id.equals(e.key))).go();
        backComputeInitial.add(e.value);
      }

      // 0b. incoming 作为 source：把被合并账户的第三方映射重定向到保留账户
      //     （幂等），并记录 incoming 的第三方权威余额，供下方步骤 1.5 转给保留账户。
      final inheritBalances = <String, ({int initial, int current})>{};
      for (final c in mapped.accounts) {
        final id = c.id.value;
        if (!mergedIncoming.contains(id)) continue;
        final srcId =
            c.yimuAssetId.value ??
            c.zhouhuAccountId.value ??
            c.qianjiAssetId.value;
        final target = incomingSources[id];
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

      // 1. 账户（非合并）：新建直接插入；已有账户（重复导入）由导入数据覆盖。
      //    一木/昼虎的 initial == current（权威快照，无真实「初始金额」概念），
      //    覆盖时把 initialBalance 反推为「权威值 - 本地账单净变化」，保证
      //    重算（initialBalance + Σ非 skipInRecalculate 账单）后余额依然等于
      //    第三方权威值——用户在第三方 App 里手动矫正过的余额以最新导入为准。
      for (final c in mapped.accounts) {
        if (mergedIncoming.contains(c.id.value)) continue;
        final id = c.id.value;
        if (idMapper.createdTargetIds.contains(id)) {
          await _db.into(_db.accounts).insert(c);
          created++;
        } else if (skipExisting) {
          countSkip();
        } else {
          final current = c.currentBalance.present ? c.currentBalance.value : 0;
          final initial = c.initialBalance.present ? c.initialBalance.value : 0;
          if (initial == current) {
            final delta = await _recalculateDelta(id);
            await (_db.update(_db.accounts)..where((t) => t.id.equals(id)))
                .write(c.copyWith(initialBalance: Value(current - delta)));
            countUpdate();
          } else {
            await (_db.update(
              _db.accounts,
            )..where((t) => t.id.equals(id))).write(c);
            countUpdate();
          }
        }
      }

      // 1.5 合并余额继承（必须在账单写入前判断 target 是否已有流水）：
      //     导入不触发余额自动加减，incoming 的权威余额只存在于账户字段中，
      //     若不转移，保留账户（如默认支付宝/微信）合并后余额仍为 0。
      //     - target 无任何账单（空账户）：直接继承第三方权威余额（含初始余额）。
      //     - target 已有账单且 incoming.initial == incoming.current（一木/昼虎
      //       权威快照，无真实「初始金额」）：直接以第三方当前余额覆盖 target，
      //       并反推 initialBalance 保证重算自洽（用户手动矫正过的余额以最新
      //       导入值为记录点，而非叠加一个恒为 0 的「变化量」）。
      //     - target 已有账单且 initial != current（钱迹等有真实初始金额）：
      //       叠加 incoming 净变化（current - initial），初始余额保留本地值。
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
        final AccountsCompanion patch;
        if (!hasBills) {
          patch = AccountsCompanion(
            initialBalance: Value(incoming.initial),
            currentBalance: Value(incoming.current),
            updatedAt: Value(nowMs()),
          );
        } else if (incoming.initial == incoming.current) {
          patch = AccountsCompanion(
            initialBalance: Value(
              incoming.current - await _recalculateDelta(targetId),
            ),
            currentBalance: Value(incoming.current),
            updatedAt: Value(nowMs()),
          );
        } else {
          patch = AccountsCompanion(
            currentBalance: Value(
              targetRow.currentBalance + incoming.current - incoming.initial,
            ),
            updatedAt: Value(nowMs()),
          );
        }
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(targetId))).write(patch);
      }

      // 2. 分类
      for (final c in mapped.categories) {
        created += await upsert(_db.categories, c);
      }

      // 3. 标签
      for (final c in mapped.tags) {
        created += await upsert(_db.tags, c);
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
        created += await upsert(_db.bills, cc);
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

      // 4.5 existing 作为 source 时，保留方（incoming 账户）以自身权威余额为准，
      //     反推 initialBalance 保证重算（initial + Σ非跳过账单）依然等于权威值
      //     （被合并现有账户的本地流水此时已重定向到保留方）。
      //     仅对「权威快照」型账户（initial == current，一木/昼虎）反推；
      //     钱迹等有真实初始金额（initial != current）的账户保留原值。
      for (final targetId in backComputeInitial) {
        final row = await (_db.select(
          _db.accounts,
        )..where((t) => t.id.equals(targetId))).getSingleOrNull();
        if (row == null || row.initialBalance != row.currentBalance) continue;
        final delta = await _recalculateDelta(targetId);
        await (_db.update(
          _db.accounts,
        )..where((t) => t.id.equals(targetId))).write(
          AccountsCompanion(
            initialBalance: Value(row.currentBalance - delta),
            updatedAt: Value(nowMs()),
          ),
        );
      }

      // 5. 快照
      for (final c in mapped.snapshots) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(accountId: Value<String>(r(c.accountId.value) ?? ''));
        }
        created += await upsert(_db.balanceSnapshots, cc);
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
        created += await upsert(_db.transfers, cc);
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
        created += await upsert(_db.lends, cc);
      }

      // 8. 退款 / 报销 / 分期（引用账单与账户，合并时替换账户引用）
      for (final c in mapped.refunds) {
        created += await upsert(_db.refunds, c);
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
        created += await upsert(_db.reimbursements, cc);
      }
      for (final c in mapped.instalments) {
        var cc = c;
        if (merge.isNotEmpty) {
          cc = c.copyWith(accountId: Value<String>(r(c.accountId.value) ?? ''));
        }
        created += await upsert(_db.instalments, cc);
      }

      // 9. 预算
      for (final c in mapped.budgets) {
        created += await upsert(_db.budgets, c);
      }

      // 10. 映射写回（幂等保证）
      await idMapper.flush();
    });

    return ImportWriteResult(
      created: created,
      updated: updated,
      skipped: skipped,
      skippedAccounts: mapped.stats.createdOf('skipped'),
      mergedAccounts: merge.length,
    );
  }

  /// 新增则 insert、已存在则 update（增量模式下已存在则跳过）；返回本次
  /// 新增数（0/1）。
  ///
  /// 用 dynamic 统一处理各表（全部表都有 id 主键），集中一处避免 14 份重复代码。
  Future<int> _upsert(
    dynamic table,
    dynamic entry,
    IdMapper idMapper, {
    bool skipExisting = false,
    void Function()? onSkip,
    void Function()? onUpdate,
  }) async {
    final id = (entry.id as Value<String>).value;
    final isNew = idMapper.createdTargetIds.contains(id);
    if (isNew) {
      await _db.into(table).insert(entry);
      return 1;
    }
    if (skipExisting) {
      onSkip?.call();
      return 0;
    }
    await (_db.update(
      table,
    )..where((t) => (t as dynamic).id.equals(id))).write(entry);
    onUpdate?.call();
    return 0;
  }

  /// 把某现有账户的全部引用重定向到另一账户（导入合并中 existing 作为
  /// source 时调用；与 AccountService._redirectReferences 同口径）。
  Future<void> _redirectExistingAccount(String fromId, String toId) async {
    await _db.customUpdate(
      'UPDATE bills SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.bills},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE bills SET income_account_id = ? WHERE income_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.bills},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE balance_snapshots SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.balanceSnapshots},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE transfers SET from_account_id = ? WHERE from_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.transfers},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE transfers SET to_account_id = ? WHERE to_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.transfers},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE lends SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.lends},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE lends SET repayment_account_id = ? WHERE repayment_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.lends},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE reimbursements SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.reimbursements},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE reimbursements SET reimbursement_account_id = ? '
      'WHERE reimbursement_account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.reimbursements},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE instalments SET account_id = ? WHERE account_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.instalments},
      updateKind: UpdateKind.update,
    );
    // 导入映射重定向（保证再次导入不产生重复账户）
    await _db.customUpdate(
      'UPDATE import_mappings SET target_id = ? WHERE target_id = ?',
      variables: [Variable(toId), Variable(fromId)],
      updates: {_db.importMappings},
      updateKind: UpdateKind.update,
    );
  }

  /// 账户上参与余额重算的账单净变化（与 BillService.recalculateAllBalances
  /// 同口径：跳过 extra.skipInRecalculate 的账单，即调账与第三方导入账单）。
  ///
  /// 用于权威快照来源（initial == current，一木/昼虎）覆盖余额时反推
  /// initialBalance，保证「重算 = initialBalance + Σ参与账单」依然等于权威值。
  Future<int> _recalculateDelta(String accountId) async {
    final rows =
        await (_db.select(_db.bills)..where(
              (t) =>
                  t.accountId.equals(accountId) |
                  t.incomeAccountId.equals(accountId),
            ))
            .get();
    var delta = 0;
    for (final b in rows) {
      final extra = BillExtra.fromJson(b.extra);
      if (extra.skipInRecalculate) continue;
      switch (BillType.values.byName(b.type)) {
        case BillType.expense:
          if (b.accountId == accountId) delta -= b.amount;
        case BillType.income:
          if (b.accountId == accountId) delta += b.amount;
        case BillType.transfer:
          if (b.accountId == accountId) delta -= b.amount;
          if (b.incomeAccountId == accountId) delta += b.amount;
      }
    }
    return delta;
  }
}

/// 解析 .db 字节流（读取完立即释放连接）。
Future<Object> _parse(ImportSource source, Uint8List bytes) async {
  final db = await openDatabaseFromBytes(bytes);
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

/// 同名账户合并候选检测（算法八，对齐 cent-xyx utils/account-merge.ts）。
///
/// - 归一化名称分组，组内「现有 × 导入」两两配对。
/// - **合并方向由时间戳决定**：`updatedAt` 更早的一方为 source（被合并），
///   更晚的一方为 target（保留）；source / target 都可能是现有或导入账户。
/// - 用各自账单时间范围 `[minTime, maxTime]` 判断是否重叠：重叠 →
///   `hasConflict = true`、`autoMerge = false`（需用户确认）。
List<AccountMergeCandidate> _detectMergeCandidates(
  List<Account> existing,
  List<AccountsCompanion> incoming,
  List<Bill> existingBills,
  List<BillsCompanion> incomingBills,
) {
  final result = <AccountMergeCandidate>[];
  if (existing.isEmpty || incoming.isEmpty) return result;

  final existingByKey = <String, List<Account>>{};
  for (final a in existing) {
    final key = normalizeAccountName(a.name);
    if (key.isEmpty) continue;
    (existingByKey[key] ??= []).add(a);
  }
  final incomingByKey = <String, List<AccountsCompanion>>{};
  for (final c in incoming) {
    final key = normalizeAccountName(c.name.value);
    if (key.isEmpty) continue;
    (incomingByKey[key] ??= []).add(c);
  }

  final keys = {...existingByKey.keys, ...incomingByKey.keys};
  final seenSources = <String>{};
  for (final key in keys) {
    final ex = existingByKey[key] ?? const <Account>[];
    final inc = incomingByKey[key] ?? const <AccountsCompanion>[];
    for (final e in ex) {
      for (final c in inc) {
        final incomingId = c.id.value;
        if (e.id == incomingId) continue; // 幂等命中同一账户，非合并候选
        // 更新时间更晚的一方为保留方（target）
        final existingIsOlder = e.updatedAt <= c.updatedAt.value;
        final sourceId = existingIsOlder ? e.id : incomingId;
        final targetId = existingIsOlder ? incomingId : e.id;
        if (seenSources.contains(sourceId)) continue; // 每个账户最多作为一个合并源
        seenSources.add(sourceId);
        final eRange = _billTimeRange(existingBills, e.id);
        final cRange = _companionBillTimeRange(incomingBills, incomingId);
        final hasConflict = _rangesOverlap(eRange, cRange);
        result.add(
          AccountMergeCandidate(
            sourceId: sourceId,
            targetId: targetId,
            name: existingIsOlder ? e.name : c.name.value,
            targetName: existingIsOlder ? c.name.value : e.name,
            autoMerge: !hasConflict,
            conflictReason: hasConflict ? '账单时间范围重叠' : null,
          ),
        );
      }
    }
  }
  return result;
}

/// 现有账户账单时间范围 [min, max]（无账单返回 null）。
({int min, int max})? _billTimeRange(List<Bill> bills, String accountId) {
  int? min, max;
  for (final b in bills) {
    if (b.accountId != accountId && b.incomeAccountId != accountId) continue;
    if (min == null || b.time < min) min = b.time;
    if (max == null || b.time > max) max = b.time;
  }
  if (min == null || max == null) return null;
  return (min: min, max: max);
}

/// 导入账户账单时间范围 [min, max]（无账单返回 null）。
({int min, int max})? _companionBillTimeRange(
  List<BillsCompanion> bills,
  String accountId,
) {
  int? min, max;
  for (final b in bills) {
    final aid = b.accountId.value;
    final iid = b.incomeAccountId.value;
    if (aid != accountId && iid != accountId) continue;
    final t = b.time.value;
    if (min == null || t < min) min = t;
    if (max == null || t > max) max = t;
  }
  if (min == null || max == null) return null;
  return (min: min, max: max);
}

bool _rangesOverlap(({int min, int max})? a, ({int min, int max})? b) {
  if (a == null || b == null) return false;
  return a.min <= b.max && b.min <= a.max;
}
