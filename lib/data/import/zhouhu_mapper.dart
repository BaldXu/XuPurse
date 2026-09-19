import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/bill_extra.dart';
import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import 'db_reader.dart';
import 'id_mapping.dart';
import 'category_fuzzy_matcher.dart';
import 'import_models.dart';
import 'zhouhu_parser.dart';

/// 昼虎记账 → XuPurse 映射（对齐 cent-xyx zhouhu/mapper.ts，转账改单条模型）。
///
/// - 金额「元」→ 万分之元；时间为毫秒直接使用。
/// - 转账：单条 Bill（accountId + incomeAccountId）+ extra 标记方向。
/// - 快照：account_change_log 升序累加 runningBalance，按天取最后一条。
MappedImport mapZhouhuToXuPurse(
  ZhouhuParsedData data,
  IdMapper idMapper,
  MapperContext ctx,
) {
  final stats = ImportStats();
  final warnings = <String>[];

  // 每个账户最新变动时间（Account.updatedAt 真实来源）
  final latestChangeTimeByAccount = <int, int>{};
  for (final log in data.changeLogs) {
    final accountId = asInt(log['accountId']);
    if (accountId == null) continue;
    final t = asInt(log['createTime']) ?? 0;
    final cur = latestChangeTimeByAccount[accountId] ?? 0;
    if (t > cur) latestChangeTimeByAccount[accountId] = t;
  }

  // ---------- 账户 ----------
  final accounts = <AccountsCompanion>[];
  for (final acc in data.accounts) {
    final idNum = asInt(acc['id']);
    if (idNum == null) continue;
    final sourceId = '$idNum';
    final id = idMapper.getOrCreateSync('account', sourceId, genId);
    final isNew = idMapper.wasCreated('account', sourceId);
    final name = asString(acc['name']);
    final accountType = asInt(acc['accountType']) ?? 0;
    final category = accountType == 5
        ? AccountCategory.record
        : accountType == 6
        ? AccountCategory.debt
        : AccountCategory.fund;
    final now = ctx.now;
    final latestTime = latestChangeTimeByAccount[idNum] ?? now;
    final balance = yuanToAmount(asDouble(acc['balance']) ?? 0);

    accounts.add(
      AccountsCompanion(
        id: Value(id),
        name: Value(name.isEmpty ? '未命名账户' : name),
        category: Value(category.name),
        type: Value(_mapAccountType(acc).name),
        icon: const Value(null),
        color: const Value(null),
        initialBalance: Value(balance),
        currentBalance: Value(balance),
        currency: Value(
          asString(acc['currencyCode']).isEmpty
              ? 'CNY'
              : asString(acc['currencyCode']),
        ),
        includeInAssets: Value(
          category == AccountCategory.debt
              ? asInt(acc['notProperty']) != 1
              : category != AccountCategory.record,
        ),
        creditLimit: const Value(null),
        cardCode: const Value(null),
        statementDate: Value<int?>(asInt(acc['billDay'])),
        repaymentDate: Value<int?>(asInt(acc['refundDay'])),
        remark: Value(
          asString(acc['note']).isEmpty ? null : asString(acc['note']),
        ),
        enabled: Value(asInt(acc['disuse']) != 1),
        zhouhuAccountId: Value(idNum),
        createdAt: Value(latestTime),
        updatedAt: Value(latestTime),
      ),
    );
    if (isNew) {
      stats.addCreated('account');
    } else {
      stats.addUpdated('account');
    }
  }

  // ---------- 分类 ----------
  final categories = <CategoriesCompanion>[];
  for (final cat in data.categories) {
    final idNum = asInt(cat['id']);
    if (idNum == null) continue;
    final sourceId = '$idNum';
    final id = idMapper.getOrCreateSync('category', sourceId, genId);
    final isNew = idMapper.wasCreated('category', sourceId);
    final rawName = asString(cat['name']);
    final name = rawName.isEmpty ? '未命名分类' : rawName;
    final type = asInt(cat['type']) == 2 ? BillType.income : BillType.expense;
    // 优先挂靠一木体系种子分类（精确 key → 模糊包含匹配）
    final seedKey = _zhouhuSeedKey(rawName) ??
        CategoryFuzzyMatcher.seedKeyByContain(rawName, type);
    final seed = seedKey == null ? null : ctx.categoryBySeedKey(seedKey);
    if (seed != null) {
      idMapper.register('category', sourceId, seed.id);
      stats.addUpdated('category');
      continue;
    }
    categories.add(
      CategoriesCompanion(
        id: Value(id),
        type: Value(type.name),
        name: Value(name),
        icon: const Value(null),
        color: Value(_mapCategoryColor(name)),
        parentId: const Value(null),
        customName: Value(true),
        defaultSelect: const Value(false),
        sort: Value(asInt(cat['index']) ?? 0),
        seedKey: const Value(null),
        createdAt: Value(ctx.now),
        updatedAt: Value(ctx.now),
      ),
    );
    if (isNew) {
      stats.addCreated('category');
    } else {
      stats.addUpdated('category');
    }
  }

  // ---------- 账单（转账单条模型） ----------
  final bills = <BillsCompanion>[];
  final billTagIds = <String, List<String>>{};
  final transferCatId =
      ctx.fallbackCategoryId(BillType.transfer, ['transfer']) ?? '';

  for (final zhBill in data.bills) {
    final idNum = asInt(zhBill['id']);
    if (idNum == null) continue;
    final accountId = idMapper.find(
      'account',
      '${asInt(zhBill['accountId']) ?? -1}',
    );
    if (accountId == null) continue;
    final sourceId = '$idNum';
    final id = idMapper.getOrCreateSync('bill', sourceId, genId);
    final isNew = idMapper.wasCreated('bill', sourceId);
    final now = ctx.now;
    final time = asInt(zhBill['createTime']) ?? now;
    final comment = asString(zhBill['note']).isEmpty
        ? null
        : asString(zhBill['note']);
    final extdata = safeParseJson(zhBill['extdata']);
    final images = _extractImages(extdata);
    final categoryId =
        idMapper.find('category', '${asInt(zhBill['categoryId']) ?? -1}') ?? '';

    final transferToId = asInt(zhBill['transferToId']);
    final extraOther = <String, Object?>{
      'zhouhuBillId': idNum,
      'zhouhuAccountId': asInt(zhBill['accountId']) ?? -1,
    };

    if (transferToId != null && transferToId > 0) {
      final toAccountId = idMapper.find('account', '$transferToId');
      if (toAccountId == null) {
        warnings.add('转账账单 $idNum 转入账户缺失，已跳过');
        continue;
      }
      bills.add(
        _buildBill(
          id: id,
          type: BillType.transfer,
          categoryId: transferCatId,
          amount: yuanToAmount(asDouble(zhBill['money']) ?? 0),
          accountId: accountId,
          incomeAccountId: toAccountId,
          time: time,
          comment: comment,
          images: images,
          extra: BillExtra(
            isZhouhu: true,
            other: {...extraOther, 'zhouhuTransferDirection': 'out'},
          ).encode(),
        ),
      );
    } else {
      final type = asInt(zhBill['billType']) == 2
          ? BillType.income
          : BillType.expense;
      bills.add(
        _buildBill(
          id: id,
          type: type,
          categoryId: categoryId,
          amount: yuanToAmount(asDouble(zhBill['money']) ?? 0),
          accountId: accountId,
          time: time,
          comment: comment,
          images: images,
          extra: BillExtra(isZhouhu: true, other: extraOther).encode(),
        ),
      );
    }
    if (isNew) {
      stats.addCreated('bill');
    } else {
      stats.addUpdated('bill');
    }
  }

  // ---------- 预算 ----------
  final budgets = <BudgetsCompanion>[];
  final primaryBook = data.accountBooks.isEmpty
      ? const <String, Object?>{}
      : data.accountBooks.first;
  final bookExtdata = safeParseJson(primaryBook['extdata']);
  final monthBudgetFromBook = asDouble(bookExtdata['monthBudget']);

  for (final b in data.budgets) {
    final idNum = asInt(b['id']);
    if (idNum == null) continue;
    final sourceId = 'zh_$idNum';
    final id = idMapper.getOrCreateSync('budget', sourceId, genId);
    final isNew = idMapper.wasCreated('budget', sourceId);
    final rawName = asString(b['name']);
    final now = ctx.now;
    budgets.add(
      BudgetsCompanion(
        id: Value(id),
        name: Value(
          _translateCategoryName(rawName).isEmpty
              ? '月度预算'
              : _translateCategoryName(rawName),
        ),
        categoryId: const Value(null),
        type: Value(
          asInt(b['billType']) == 2
              ? BillType.income.name
              : BillType.expense.name,
        ),
        periodType: Value(BudgetPeriodType.month.name),
        amount: Value(yuanToAmount(asDouble(b['defaultAmount']) ?? 0)),
        startTime: Value<int?>(asInt(b['startTime']) ?? now),
        endTime: Value<int?>(asInt(b['endTime'])),
        enabled: const Value(true),
        yimuBudgetId: const Value(null),
        createdAt: Value(asInt(b['createTime']) ?? now),
        updatedAt: Value(asInt(b['modifyTime']) ?? now),
      ),
    );
    if (isNew) {
      stats.addCreated('budget');
    } else {
      stats.addUpdated('budget');
    }
  }

  // 预算表为空但账本 extdata.monthBudget > 0 → 生成月度预算兜底
  if (data.budgets.isEmpty &&
      monthBudgetFromBook != null &&
      monthBudgetFromBook > 0) {
    final sourceId = 'zh_book_monthly';
    final id = idMapper.getOrCreateSync('budget', sourceId, genId);
    if (idMapper.wasCreated('budget', sourceId)) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final end = DateTime(now.year, now.month + 1, 0).millisecondsSinceEpoch;
      budgets.add(
        BudgetsCompanion(
          id: Value(id),
          name: Value(
            _translateCategoryName(asString(primaryBook['name'])).isEmpty
                ? '月度预算'
                : _translateCategoryName(asString(primaryBook['name'])),
          ),
          categoryId: const Value(null),
          type: Value(BillType.expense.name),
          periodType: Value(BudgetPeriodType.month.name),
          amount: Value(yuanToAmount(monthBudgetFromBook)),
          startTime: Value(start),
          endTime: Value(end),
          enabled: const Value(true),
          yimuBudgetId: const Value(null),
          createdAt: Value(ctx.now),
          updatedAt: Value(ctx.now),
        ),
      );
      stats.addCreated('budget');
    }
  }

  // ---------- 快照（changeLogs 升序累加，按天取最后一条，跳过相同余额） ----------
  final snapshots = <BalanceSnapshotsCompanion>[];
  final logsByAccount = <int, List<Map<String, Object?>>>{};
  for (final log in data.changeLogs) {
    final accountId = asInt(log['accountId']);
    if (accountId == null) continue;
    (logsByAccount[accountId] ??= []).add(log);
  }

  for (final entry in logsByAccount.entries) {
    final accountBusinessId = entry.key;
    final accountId = idMapper.find('account', '$accountBusinessId');
    if (accountId == null) continue;
    final logs = entry.value;
    logs.sort(
      (a, b) =>
          (asInt(a['createTime']) ?? 0).compareTo(asInt(b['createTime']) ?? 0),
    );

    // 每天只保留最后一条用于生成快照
    final dailyLast = <String, Map<String, Object?>>{};
    for (final log in logs) {
      final t = asInt(log['createTime']) ?? 0;
      if (t == 0) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(t);
      final key = '${date.year}_${date.month}_${date.day}';
      dailyLast[key] = log;
    }

    var runningBalance = 0;
    int? lastBalance;
    for (final log in logs) {
      final change = asInt(log['change']) ?? 0;
      runningBalance += change;
      final t = asInt(log['createTime']) ?? 0;
      if (t == 0) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(t);
      final key = '${date.year}_${date.month}_${date.day}';
      final logId = asInt(log['id']);
      if (dailyLast[key] == null || dailyLast[key]!['id'] != logId) continue;
      if (lastBalance == runningBalance) continue;
      lastBalance = runningBalance;

      final sourceId = '${logId ?? t}';
      final id = idMapper.getOrCreateSync('snapshot', sourceId, genId);
      final isNew = idMapper.wasCreated('snapshot', sourceId);
      final logType = asInt(log['type']) ?? 0;
      final type = logType == 3
          ? SnapshotType.manual
          : change > 0
          ? SnapshotType.income
          : SnapshotType.expense;
      final content = asString(log['content']);

      snapshots.add(
        BalanceSnapshotsCompanion(
          id: Value(id),
          accountId: Value(accountId),
          balance: Value(yuanToAmount(runningBalance.toDouble())),
          timestamp: Value(t),
          note: Value(content.isEmpty ? null : content),
          isValid: const Value(true),
          billId: const Value(null),
          type: Value(type),
          yimuAssetHistoryId: const Value(null),
        ),
      );
      if (isNew) {
        stats.addCreated('snapshot');
      } else {
        stats.addUpdated('snapshot');
      }
    }

    // 无任何变动记录但账户有余额 → 生成一条当前余额快照
    if (logs.isEmpty) {
      Account? account;
      for (final a in ctx.accounts) {
        if (a.id == accountId) {
          account = a;
          break;
        }
      }
      if (account != null && account.currentBalance != 0) {
        final sourceId = 'zh_balance_$accountBusinessId';
        final id = idMapper.getOrCreateSync('snapshot', sourceId, genId);
        if (idMapper.wasCreated('snapshot', sourceId)) {
          snapshots.add(
            BalanceSnapshotsCompanion(
              id: Value(id),
              accountId: Value(accountId),
              balance: Value(account.currentBalance),
              timestamp: Value(ctx.now),
              note: const Value('账户余额'),
              isValid: const Value(true),
              billId: const Value(null),
              type: Value(SnapshotType.manual),
              yimuAssetHistoryId: const Value(null),
            ),
          );
          stats.addCreated('snapshot');
        }
      }
    }
  }

  return MappedImport(
    stats: stats,
    warnings: warnings,
    accounts: accounts,
    categories: categories,
    bills: bills,
    billTagIds: billTagIds,
    snapshots: snapshots,
    budgets: budgets,
  );
}

/// 昼虎 basedata.* 资源 key → 中文分类名
/// 昼虎分类 key → XuPurse 种子 key（一木体系；直接挂靠，不再新建翻译名分类）。
const _zhouhuCategoryKeyMap = <String, String>{
  'basedata.diet': 'food',           // 餐饮 → 食品餐饮
  'basedata.daily': 'daily-necessities', // 日常 → 日用
  'basedata.traffic': 'transport',   // 交通 → 出行交通
  'basedata.social': 'relationship', // 社交 → 送礼人情
  'basedata.residential': 'housing', // 居住 → 居家生活
  'basedata.gift': 'gifts',          // 礼物
  'basedata.communication': 'phone-broadband', // 通讯 → 话费宽带
  'basedata.dress': 'clothing',      // 服饰 → 服装
  'basedata.recreation': 'entertainment', // 娱乐 → 休闲娱乐
  'basedata.beautify': 'beauty',     // 美容 → 理发美容
  'basedata.medical': 'medical',     // 医疗 → 健康医疗
  'basedata.tax': 'other-expenses',  // 税费 → 其他
  'basedata.education': 'education', // 教育 → 文化教育
  'basedata.baby': 'baby-toys',      // 育儿 → 母婴玩具
  'basedata.pet': 'pet-supplies',    // 宠物 → 宠物用品
  'basedata.travel': 'travel',       // 旅行 → 旅游度假
  'basedata.wage': 'wage',           // 工资
  'basedata.bonus': 'bonus',         // 奖金
  'basedata.investment': 'invest-profit', // 投资 → 理财盈利
  'basedata.parttime_job': 'part-time',   // 兼职 → 兼职外快
  'basedata.myself': 'other-income', // 自己 → 其他
  'basedata.wife': 'other-income',   // 妻子 → 其他
  'basedata.husband': 'other-income', // 丈夫 → 其他
  'basedata.child': 'other-income',  // 孩子 → 其他
  'basedata.parent': 'other-income', // 父母 → 其他
  'basedata.home': 'other-income',   // 家庭 → 其他
  'basedata.monthly': 'other-expenses', // 月度预算 → 其他
};

/// 昼虎分类 key → 种子 key（未命中返回 null，走模糊匹配/新建）。
String? _zhouhuSeedKey(String rawName) => _zhouhuCategoryKeyMap[rawName];

/// 账本名等非分类字段的翻译（保留原中文名映射）。
String _translateCategoryName(String name) => name;

/// 昼虎账户类型映射（对齐 zhouhu/mapper.ts mapAccountType）。
AccountType _mapAccountType(Map<String, Object?> account) {
  final name = asString(account['name']);
  final type = asInt(account['accountType']) ?? 0;
  if (type == 2) return AccountType.bank;
  if (type == 5) return AccountType.investment;
  if (type == 4) {
    if (name.contains('支付宝')) return AccountType.alipay;
    if (name.contains('微信')) return AccountType.wechat;
    return AccountType.other;
  }
  if (type == 6) {
    if (name.contains('信用') || name.contains('花呗') || name.contains('白条')) {
      return AccountType.credit;
    }
    return AccountType.other;
  }
  if (type == 1 || type == 3) {
    if (name.contains('现金')) return AccountType.cash;
    return AccountType.other;
  }
  return AccountType.other;
}

const _zhouhuCategoryColorMap = <String, String>{
  '餐饮': '#5470c6',
  '日常': '#91cc75',
  '交通': '#fac858',
  '社交': '#ee6666',
  '居住': '#73c0de',
  '礼物': '#ea7ccc',
  '通讯': '#3ba272',
  '服饰': '#fc8452',
  '娱乐': '#9a60b4',
  '美容': '#f472b6',
  '医疗': '#ff0000',
  '税费': '#4d3c77',
  '教育': '#9a60b4',
  '工资': '#fac858',
  '奖金': '#fac858',
  '投资': '#3ba272',
  '兼职': '#73c0de',
};

String _mapCategoryColor(String name) =>
    _zhouhuCategoryColorMap[name] ?? '#4d3c77';

/// 从 extdata 提取图片 URL 列表（JSON 数组文本）。
String? _extractImages(Map<String, Object?> extdata) {
  final pictures = extdata['pictures'];
  if (pictures is List && pictures.isNotEmpty) {
    final urls = pictures.map((e) => e.toString()).toList();
    return jsonEncode(urls);
  }
  return null;
}

BillsCompanion _buildBill({
  required String id,
  required BillType type,
  required String categoryId,
  required int amount,
  required String? accountId,
  String? incomeAccountId,
  required int time,
  String? comment,
  String? images,
  required String? extra,
}) {
  return BillsCompanion(
    id: Value(id),
    type: Value(type.name),
    categoryId: Value(categoryId),
    amount: Value(amount),
    accountId: Value(accountId),
    incomeAccountId: Value(incomeAccountId),
    time: Value(time),
    comment: Value(comment),
    locationLat: const Value(null),
    locationLng: const Value(null),
    images: Value(images),
    currencyCode: const Value(null),
    currencyAmount: const Value(null),
    baseCurrency: const Value(null),
    extra: Value(extra),
    creatorId: const Value(null),
    createdAt: Value(time),
    updatedAt: Value(time),
  );
}
