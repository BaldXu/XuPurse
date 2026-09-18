/// 第三方导入的统一数据结构与统计。
///
/// 设计对齐 docs/algorithms.md 算法七：parse → map → preview → write → mapping。
/// 所有金额已转换为万分之元整数，时间为毫秒。
library;

import '../../core/constants/enums.dart';
import '../database/app_database.dart';
import 'id_mapping.dart';

/// 导入统计（按实体类型计数，entityType 见 [IdMapper] 的约定字符串）。
class ImportStats {
  ImportStats();

  final Map<String, int> _created = {};
  final Map<String, int> _updated = {};

  void addCreated(String entityType, [int n = 1]) =>
      _created[entityType] = (_created[entityType] ?? 0) + n;

  void addUpdated(String entityType, [int n = 1]) =>
      _updated[entityType] = (_updated[entityType] ?? 0) + n;

  int createdOf(String entityType) => _created[entityType] ?? 0;
  int updatedOf(String entityType) => _updated[entityType] ?? 0;

  int get totalCreated => _created.values.fold(0, (a, b) => a + b);
  int get totalUpdated => _updated.values.fold(0, (a, b) => a + b);

  Set<String> get createdTypes => _created.keys.toSet();
  Set<String> get updatedTypes => _updated.keys.toSet();
}

/// 映射阶段产出的全部实体（drift Companion，可直接写库）。
class MappedImport {
  MappedImport({
    required this.stats,
    required this.warnings,
    this.accounts = const [],
    this.categories = const [],
    this.tags = const [],
    this.bills = const [],
    this.billTagIds = const {},
    this.snapshots = const [],
    this.transfers = const [],
    this.lends = const [],
    this.refunds = const [],
    this.reimbursements = const [],
    this.instalments = const [],
    this.budgets = const [],
  });

  final ImportStats stats;
  final List<String> warnings;

  final List<AccountsCompanion> accounts;
  final List<CategoriesCompanion> categories;
  final List<TagsCompanion> tags;
  final List<BillsCompanion> bills;

  /// billId → 标签 ID 列表（bill_tags 关联）
  final Map<String, List<String>> billTagIds;

  final List<BalanceSnapshotsCompanion> snapshots;
  final List<TransfersCompanion> transfers;
  final List<LendsCompanion> lends;
  final List<RefundsCompanion> refunds;
  final List<ReimbursementsCompanion> reimbursements;
  final List<InstalmentsCompanion> instalments;
  final List<BudgetsCompanion> budgets;
}

/// 同名账户合并候选（算法八）。
///
/// 合并方向由数据时间戳决定（docs/algorithms.md 算法八）：`updatedAt` 更早的
/// 一方为 source（被合并），更晚的一方为 target（保留）。source / target 都
/// 可能是「本次导入的新账户」或「现有账户」。
class AccountMergeCandidate {
  const AccountMergeCandidate({
    required this.sourceId,
    required this.targetId,
    required this.name,
    required this.autoMerge,
    this.targetName,
    this.conflictReason,
  });

  /// 被合并方账户 id（现有账户或本次导入的新账户，写入时其引用替换为 target）
  final String sourceId;

  /// 保留方账户 id（现有账户或本次导入的新账户）
  final String targetId;

  /// 被合并方账户名（用于 UI 展示合并方向）
  final String name;

  /// 保留方账户名（用于 UI 展示合并方向；为导入账户时也可能为 null）
  final String? targetName;

  /// 时间范围不冲突时可自动合并，否则需用户确认
  final bool autoMerge;

  /// 冲突原因（账单时间范围重叠时为非空，UI 用于提示）
  final String? conflictReason;
}

/// 导入预览结果（preview 产出，write 消费）。
class ImportPreview {
  ImportPreview({
    required this.source,
    required this.fileName,
    required this.mapped,
    required this.idMapper,
    required this.mergeCandidates,
  });

  final ImportSource source;
  final String fileName;
  final MappedImport mapped;
  final IdMapper idMapper;
  final List<AccountMergeCandidate> mergeCandidates;

  bool get isEmpty =>
      mapped.stats.totalCreated + mapped.stats.totalUpdated == 0;
}

/// 写库结果。
class ImportWriteResult {
  const ImportWriteResult({
    required this.created,
    required this.updated,
    required this.skippedAccounts,
    required this.mergedAccounts,
  });

  final int created;
  final int updated;

  /// 因账户映射缺失被跳过的账单数（不含账户缺失的转账等）
  final int skippedAccounts;

  /// 实际执行合并的账户对数
  final int mergedAccounts;
}

/// 映射阶段共享的现有数据上下文（预加载到内存，避免 mapper 中逐条查库）。
class MapperContext {
  MapperContext({required this.accounts, required this.categories}) {
    for (final c in categories) {
      if (c.seedKey != null && c.seedKey!.isNotEmpty) {
        bySeedKey[c.seedKey!] = c;
      }
      byTypeName['${c.type}:${c.name}'] = c;
    }
    for (final a in accounts) {
      accountNames.add(a.name);
    }
  }

  final List<Account> accounts;
  final List<Category> categories;

  final Map<String, Category> bySeedKey = {};
  final Map<String, Category> byTypeName = {};
  final Set<String> accountNames = {};

  int get now => DateTime.now().millisecondsSinceEpoch;

  /// 按种子 key 查分类（钱迹分类复用种子分类）。
  Category? categoryBySeedKey(String seedKey) => bySeedKey[seedKey];

  /// 按 类型+名称 查分类。
  Category? categoryByTypeName(BillType type, String name) =>
      byTypeName['${type.name}:$name'];

  /// 某类型的默认兜底分类（优先种子，其次类型内第一个，最后 null）。
  String? fallbackCategoryId(BillType type, List<String> preferredSeedKeys) {
    for (final key in preferredSeedKeys) {
      final c = bySeedKey[key];
      if (c != null && c.type == type.name) return c.id;
    }
    for (final c in categories) {
      if (c.type == type.name) return c.id;
    }
    return null;
  }
}
