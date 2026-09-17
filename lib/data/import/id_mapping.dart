import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/ids.dart';
import '../database/app_database.dart';

/// 第三方业务 ID → XuPurse UUID 的幂等映射（算法七核心）。
///
/// 基于 `import_mappings` 表（provider + entityType + sourceId 唯一索引）。
/// 一次导入会话内先读入全部存量映射到内存缓存，新生成的映射登记在
/// [upserts] 中，写库事务末尾统一落表，避免逐条查询。
class IdMapper {
  IdMapper(this._db, this.provider);

  final AppDatabase _db;
  final ImportSource provider;

  String get _providerName => provider.dbName;

  final Map<String, String> _map = {};
  bool _loaded = false;

  /// 本次会话新建的映射（provider+entityType+sourceId → targetId）
  final Map<String, ImportMappingsCompanion> _upserts = {};

  /// 本次会话新建的 targetId 集合（用于判断实体「新增 vs 更新」）
  final Set<String> createdTargetIds = {};

  static String _key(String entityType, String sourceId) =>
      '$entityType\u0000$sourceId';

  /// 惰性加载该 provider 的全部存量映射。
  Future<void> loadAll() async {
    if (_loaded) return;
    _loaded = true;
    final rows = await (_db.select(
      _db.importMappings,
    )..where((t) => t.provider.equals(_providerName))).get();
    for (final r in rows) {
      _map[_key(r.entityType, r.sourceId)] = r.targetId;
    }
  }

  /// 查已有映射（未加载则先加载）。
  String? find(String entityType, String sourceId) {
    return _map[_key(entityType, sourceId)];
  }

  /// 本次会话中该 key 是否为新建（getOrCreate 首次生成）。
  bool wasCreated(String entityType, String sourceId) {
    return createdTargetIds.contains(_map[_key(entityType, sourceId)]);
  }

  /// 有映射则复用，无则调用 [createId] 生成并登记待写回。
  Future<String> getOrCreate(
    String entityType,
    String sourceId,
    String Function() createId,
  ) async {
    await loadAll();
    return getOrCreateSync(entityType, sourceId, createId);
  }

  /// 同步版 [getOrCreate]；调用方必须已调用 [loadAll]（preview 入口保证）。
  String getOrCreateSync(
    String entityType,
    String sourceId,
    String Function() createId,
  ) {
    final k = _key(entityType, sourceId);
    final existing = _map[k];
    if (existing != null) return existing;
    final id = createId();
    _map[k] = id;
    createdTargetIds.add(id);
    _upserts[k] = _companion(entityType, sourceId, id);
    return id;
  }

  /// 覆盖映射目标（同名账户合并：把本次新账户的映射指向现有账户）。
  Future<void> overrideTarget(
    String entityType,
    String sourceId,
    String newTargetId,
  ) async {
    await loadAll();
    overrideTargetSync(entityType, sourceId, newTargetId);
  }

  /// 同步版 [overrideTarget]；调用方必须已 [loadAll]。
  void overrideTargetSync(
    String entityType,
    String sourceId,
    String newTargetId,
  ) {
    final k = _key(entityType, sourceId);
    final old = _map[k];
    if (old != null && old == newTargetId) return;
    _map[k] = newTargetId;
    createdTargetIds.remove(old);
    _upserts[k] = _companion(entityType, sourceId, newTargetId);
  }

  /// 登记「复用已有目标 ID」的映射（如钱迹分类复用种子分类，不新建实体）。
  /// 要求调用方已 [loadAll]。
  void register(String entityType, String sourceId, String targetId) {
    final k = _key(entityType, sourceId);
    if (_map[k] == targetId) return;
    _map[k] = targetId;
    _upserts[k] = _companion(entityType, sourceId, targetId);
  }

  ImportMappingsCompanion _companion(
    String entityType,
    String sourceId,
    String targetId,
  ) {
    final now = nowMs();
    return ImportMappingsCompanion.insert(
      id: genId(),
      provider: _providerName,
      entityType: entityType,
      sourceId: sourceId,
      targetId: targetId,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 把本次会话全部新映射写入 `import_mappings` 表（先删后插，保证幂等）。
  /// 必须在写库事务内调用。
  Future<void> flush() async {
    if (_upserts.isEmpty) return;
    await _db.batch((batch) {
      for (final c in _upserts.values) {
        batch.deleteWhere(
          _db.importMappings,
          (t) =>
              t.provider.equals(c.provider.value) &
              t.entityType.equals(c.entityType.value) &
              t.sourceId.equals(c.sourceId.value),
        );
        batch.insert(_db.importMappings, c);
      }
    });
  }
}
