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
import 'qianji_parser.dart';

/// 钱迹 → XuPurse 映射（对齐 cent-xyx qianji/mapper.ts，转账改单条模型）。
///
/// - 金额「元」→ 万分之元；时间为**秒** → ×1000 转毫秒。
/// - 账单幂等 key 用 `billid`（非行 id）。
/// - 分类优先复用 XuPurse 种子分类（[qianjiExpenseCategoryNameToDefaultId] 等），
///   未命中才新建分类。
/// - type=7 债权债务：按资金流向生成借出/收回账单（extra 标记方向），不写 Lends 表。
MappedImport mapQianjiToXuPurse(
  QianjiParsedData data,
  IdMapper idMapper,
  MapperContext ctx,
) {
  final stats = ImportStats();
  final warnings = <String>[];

  // 每个账户最新账单时间（Account.updatedAt 来源；秒→毫秒）
  final latestBillTimeByAccount = <int, int>{};
  for (final bill in data.bills) {
    final accountId =
        asInt(bill['assetid']) ??
        asInt(bill['fromid']) ??
        asInt(bill['targetid']);
    if (accountId == null) continue;
    final t = (asInt(bill['time']) ?? 0) * 1000;
    final cur = latestBillTimeByAccount[accountId] ?? 0;
    if (t > cur) latestBillTimeByAccount[accountId] = t;
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
    final type = asInt(acc['type']) ?? 1;
    final category = type == 5 ? AccountCategory.debt : AccountCategory.fund;
    final extra = safeParseJson(acc['extra']);
    final initmoney = asDouble(extra['initmoney']);
    final money = asDouble(acc['money']) ?? 0;
    final now = ctx.now;
    final createTime = (asInt(acc['createtime']) ?? 0) * 1000;
    final lastPayTime = (asInt(acc['lastpaytime']) ?? 0) * 1000;
    final updatedAt = lastPayTime > 0
        ? lastPayTime
        : latestBillTimeByAccount[idNum] ?? now;
    final color = asString(acc['color']);

    accounts.add(
      AccountsCompanion(
        id: Value(id),
        name: Value(name.isEmpty ? '未命名账户' : name),
        category: Value(category.name),
        type: Value(_mapAccountType(acc).name),
        icon: const Value(null),
        color: Value(color.isEmpty ? null : '#$color'),
        initialBalance: Value(yuanToAmount(initmoney ?? money)),
        currentBalance: Value(yuanToAmount(money)),
        currency: Value(
          asString(acc['currency']).isEmpty ? 'CNY' : asString(acc['currency']),
        ),
        includeInAssets: Value(true),
        creditLimit: const Value(null),
        cardCode: const Value(null),
        statementDate: const Value(null),
        repaymentDate: const Value(null),
        remark: Value(
          asString(acc['remark']).isEmpty ? null : asString(acc['remark']),
        ),
        enabled: Value(true),
        qianjiAssetId: Value(idNum),
        createdAt: Value(createTime > 0 ? createTime : now),
        updatedAt: Value(updatedAt),
      ),
    );
    if (isNew) {
      stats.addCreated('account');
    } else {
      stats.addUpdated('account');
    }
  }

  // ---------- 分类（优先复用种子分类） ----------
  final categories = <CategoriesCompanion>[];
  final qianjiCategoryById = <int, Map<String, Object?>>{
    for (final c in data.categories)
      if (asInt(c['id']) != null) asInt(c['id'])!: c,
  };

  for (final cat in data.categories) {
    final idNum = asInt(cat['id']);
    if (idNum == null) continue;
    final catType = asInt(cat['type']) ?? 0;
    final isIncome = catType == 1;
    final name = asString(cat['name']);
    final seedKey = _resolveDefaultCategoryKey(name, isIncome);
    final seedCategory = seedKey == null
        ? null
        : ctx.categoryBySeedKey(seedKey);

    String id;
    if (seedCategory != null) {
      id = seedCategory.id;
      idMapper.register('category', '$idNum', id);
      stats.addUpdated('category');
    } else {
      id = idMapper.getOrCreateSync('category', '$idNum', genId);
      categories.add(
        CategoriesCompanion(
          id: Value(id),
          type: Value(isIncome ? BillType.income.name : BillType.expense.name),
          name: Value(name.isEmpty ? '未命名分类' : name),
          icon: const Value(null),
          color: Value(_mapCategoryColor(name)),
          parentId: const Value(null),
          customName: Value(true),
          defaultSelect: const Value(false),
          sort: Value(asInt(cat['sort']) ?? 0),
          seedKey: const Value(null),
          createdAt: Value(ctx.now),
          updatedAt: Value(ctx.now),
        ),
      );
      if (idMapper.wasCreated('category', '$idNum')) {
        stats.addCreated('category');
      } else {
        stats.addUpdated('category');
      }
    }
  }

  // ---------- 账单 ----------
  final bills = <BillsCompanion>[];
  final billTagIds = <String, List<String>>{};
  final transferCatId =
      ctx.fallbackCategoryId(BillType.transfer, ['transfer']) ?? '';
  final lendCatId =
      ctx.fallbackCategoryId(BillType.expense, ['loan-out']) ?? '';
  final collectCatId =
      ctx.fallbackCategoryId(BillType.income, ['other-income', 'yimu-901']) ??
      '';

  String resolveCategoryId(Map<String, Object?> qianjiBill, BillType type) {
    final categoryId = asInt(qianjiBill['categoryid']) ?? 0;
    if (categoryId <= 0) return _fallbackCategory(ctx, type);
    final qjCat = qianjiCategoryById[categoryId];
    if (qjCat != null) {
      final seedKey = _resolveDefaultCategoryKey(
        asString(qjCat['name']),
        asInt(qjCat['type']) == 1,
      );
      final seed = seedKey == null ? null : ctx.categoryBySeedKey(seedKey);
      if (seed != null) return seed.id;
    }
    return idMapper.find('category', '$categoryId') ??
        _fallbackCategory(ctx, type);
  }

  for (final qianjiBill in data.bills) {
    final billid = asInt(qianjiBill['billid']);
    if (billid == null || billid == 0) continue;
    final type = asInt(qianjiBill['type']) ?? 0;
    final sourceId = '$billid';
    final billExists = idMapper.find('bill', sourceId) != null;
    final id = idMapper.getOrCreateSync('bill', sourceId, genId);
    final isNew = !billExists;
    final sharedExtra = <String, Object?>{'qianjiBillId': billid};

    switch (type) {
      case 0: // 支出
        final accountId = idMapper.find(
          'account',
          '${asInt(qianjiBill['assetid']) ?? -1}',
        );
        if (accountId == null) {
          warnings.add('支出账单 $billid 账户缺失，已跳过');
          stats.addCreated('skipped');
          continue;
        }
        bills.add(
          _buildBill(
            id: id,
            type: BillType.expense,
            categoryId: resolveCategoryId(qianjiBill, BillType.expense),
            amount: yuanToAmount(asDouble(qianjiBill['money']) ?? 0),
            accountId: accountId,
            time: _billTimeMs(qianjiBill, ctx.now),
            comment: _billComment(qianjiBill),
            currency: _parseBillCurrency(qianjiBill),
            extra: BillExtra(isQianji: true, other: sharedExtra).encode(),
          ),
        );
        break;
      case 1: // 收入
        final accountId = idMapper.find(
          'account',
          '${asInt(qianjiBill['assetid']) ?? -1}',
        );
        if (accountId == null) {
          warnings.add('收入账单 $billid 账户缺失，已跳过');
          stats.addCreated('skipped');
          continue;
        }
        bills.add(
          _buildBill(
            id: id,
            type: BillType.income,
            categoryId: resolveCategoryId(qianjiBill, BillType.income),
            amount: yuanToAmount(asDouble(qianjiBill['money']) ?? 0),
            accountId: accountId,
            time: _billTimeMs(qianjiBill, ctx.now),
            comment: _billComment(qianjiBill),
            currency: _parseBillCurrency(qianjiBill),
            extra: BillExtra(isQianji: true, other: sharedExtra).encode(),
          ),
        );
        break;
      case 2: // 转账（单条模型）
        final fromAccountId = idMapper.find(
          'account',
          '${asInt(qianjiBill['fromid']) ?? -1}',
        );
        final toAccountId = idMapper.find(
          'account',
          '${asInt(qianjiBill['targetid']) ?? -1}',
        );
        if (fromAccountId == null || toAccountId == null) {
          warnings.add('转账账单 $billid 账户缺失，已跳过');
          stats.addCreated('skipped');
          continue;
        }
        bills.add(
          _buildBill(
            id: id,
            type: BillType.transfer,
            categoryId: transferCatId,
            amount: yuanToAmount(asDouble(qianjiBill['money']) ?? 0),
            accountId: fromAccountId,
            incomeAccountId: toAccountId,
            time: _billTimeMs(qianjiBill, ctx.now),
            comment: _billComment(qianjiBill),
            currency: _parseBillCurrency(qianjiBill),
            extra: BillExtra(
              isQianji: true,
              other: {...sharedExtra, 'qianjiTransferDirection': 'out'},
            ).encode(),
          ),
        );
        break;
      case 7: // 债权债务：借出=支出，收回=收入
        final fromAccountId = idMapper.find(
          'account',
          '${asInt(qianjiBill['fromid']) ?? -1}',
        );
        final toAccountId = idMapper.find(
          'account',
          '${asInt(qianjiBill['targetid']) ?? -1}',
        );
        final debtAssetId = asInt(qianjiBill['assetid']);
        if (fromAccountId != null && debtAssetId != null) {
          bills.add(
            _buildBill(
              id: id,
              type: BillType.expense,
              categoryId: lendCatId,
              amount: yuanToAmount(asDouble(qianjiBill['money']) ?? 0),
              accountId: fromAccountId,
              time: _billTimeMs(qianjiBill, ctx.now),
              comment: _billComment(qianjiBill),
              currency: _parseBillCurrency(qianjiBill),
              extra: BillExtra(
                isQianji: true,
                other: {
                  ...sharedExtra,
                  'qianjiDebtAccountId': debtAssetId,
                  'qianjiDebtDirection': 'lend',
                },
              ).encode(),
            ),
          );
        } else if (toAccountId != null && debtAssetId != null) {
          bills.add(
            _buildBill(
              id: id,
              type: BillType.income,
              categoryId: collectCatId,
              amount: yuanToAmount(asDouble(qianjiBill['money']) ?? 0),
              accountId: toAccountId,
              time: _billTimeMs(qianjiBill, ctx.now),
              comment: _billComment(qianjiBill),
              currency: _parseBillCurrency(qianjiBill),
              extra: BillExtra(
                isQianji: true,
                other: {
                  ...sharedExtra,
                  'qianjiDebtAccountId': debtAssetId,
                  'qianjiDebtDirection': 'collect',
                },
              ).encode(),
            ),
          );
        } else {
          warnings.add('债权债务账单 $billid 账户缺失，已跳过');
          stats.addCreated('skipped');
          continue;
        }
        break;
      default:
        warnings.add('未知账单类型 $type，账单 $billid 已跳过');
        stats.addCreated('skipped');
        continue;
    }

    if (isNew) {
      stats.addCreated('bill');
    } else {
      stats.addUpdated('bill');
    }
  }

  return MappedImport(
    stats: stats,
    warnings: warnings,
    accounts: accounts,
    categories: categories,
    bills: bills,
    billTagIds: billTagIds,
  );
}

/// 钱迹支出分类名 → XuPurse 种子 key
const qianjiExpenseCategoryNameToDefaultId = <String, String>{
  '三餐': 'food',
  '零食': 'snack',
  '衣服': 'clothing',
  '交通': 'transport',
  '旅行': 'travel',
  '孩子': 'baby-toys',
  '宠物': 'pet-supplies',
  '话费网费': 'phone-broadband',
  '烟酒': 'drinks',
  '学习': 'education',
  '日用品': 'daily-necessities',
  '住房': 'rent-mortgage',
  '美妆': 'beauty-care',
  '医疗': 'medical',
  '发红包': 'hongbao',
  '汽车/加油': 'gas-up',
  '娱乐': 'entertainment',
  '请客送礼': 'relationship',
  '电器数码': 'electronics',
  '运动': 'fitness',
  '水电煤': 'housing',
  '其它': 'other-expenses',
};

/// 钱迹收入分类名 → XuPurse 种子 key
const qianjiIncomeCategoryNameToDefaultId = <String, String>{
  '工资': 'wage',
  '生活费': 'other-income',
  '收红包': 'gift-money',
  '外快': 'part-time',
  '股票基金': 'invest-profit',
  '奖金': 'bonus',
  '报销': 'yimu-901',
  '理财': 'invest-profit',
  '兼职': 'part-time',
  '其它': 'other-income',
};

String? _resolveDefaultCategoryKey(String name, bool isIncome) {
  final map = isIncome
      ? qianjiIncomeCategoryNameToDefaultId
      : qianjiExpenseCategoryNameToDefaultId;
  return map[name] ??
      // 模糊匹配：种名与分类名双向包含（一木体系挂靠）
      CategoryFuzzyMatcher.seedKeyByContain(
        name,
        isIncome ? BillType.income : BillType.expense,
      );
}

String _fallbackCategory(MapperContext ctx, BillType type) =>
    ctx.fallbackCategoryId(
      type,
      type == BillType.income ? ['other-income'] : ['other-expenses'],
    ) ??
    '';

String _billComment(Map<String, Object?> bill) {
  final remark = asString(bill['remark']);
  if (remark.isNotEmpty) return remark;
  final descInfo = asString(bill['descinfo']);
  return descInfo.isEmpty ? '' : descInfo;
}

int _billTimeMs(Map<String, Object?> bill, int fallback) {
  final t = asInt(bill['time']) ?? 0;
  return t > 0 ? t * 1000 : fallback;
}

/// 解析钱迹 bill.extra.curr 多币种字段（bs 基础币种 / ss 目标币种 / sv 目标金额）。
({String currencyCode, int currencyAmount, String baseCurrency})?
_parseBillCurrency(Map<String, Object?> bill) {
  final extra = safeParseJson(bill['extra']);
  final curr = extra['curr'];
  if (curr is! Map) return null;
  final bs = curr['bs']?.toString() ?? '';
  final ss = curr['ss']?.toString() ?? '';
  final sv = asDouble(curr['sv']);
  if (bs.isEmpty || ss.isEmpty) return null;
  return (
    currencyCode: ss,
    currencyAmount: yuanToAmount(sv ?? asDouble(bill['money']) ?? 0),
    baseCurrency: bs,
  );
}

AccountType _mapAccountType(Map<String, Object?> account) {
  final name = asString(account['name']);
  final type = asInt(account['type']) ?? 1;
  if (type == 5) {
    if (name.contains('信用') || name.contains('花呗') || name.contains('白条')) {
      return AccountType.credit;
    }
    return AccountType.other;
  }
  switch (asInt(account['stype']) ?? 0) {
    case 13:
      return AccountType.alipay;
    case 14:
      return AccountType.wechat;
    case 12:
      return AccountType.bank;
    case 103:
    case 106:
      return AccountType.investment;
  }
  if (name.contains('支付宝')) return AccountType.alipay;
  if (name.contains('微信')) return AccountType.wechat;
  if (name.contains('现金')) return AccountType.cash;
  if (name.contains('银行')) return AccountType.bank;
  if (name.contains('余额宝') || name.contains('余利宝')) {
    return AccountType.investment;
  }
  return AccountType.other;
}

const _qianjiCategoryColorMap = <String, String>{
  '三餐': '#5470c6',
  '零食': '#91cc75',
  '衣服': '#fac858',
  '交通': '#73c0de',
  '旅行': '#ee6666',
  '孩子': '#ea7ccc',
  '宠物': '#fc8452',
  '话费网费': '#3ba272',
  '烟酒': '#ff0000',
  '学习': '#9a60b4',
  '日用品': '#91cc75',
  '住房': '#73c0de',
  '美妆': '#f472b6',
  '医疗': '#ff0000',
  '发红包': '#ee6666',
  '汽车/加油': '#fac858',
  '娱乐': '#9a60b4',
  '请客送礼': '#ea7ccc',
  '电器数码': '#5470c6',
  '运动': '#3ba272',
  '水电煤': '#fac858',
  '工资': '#fac858',
  '生活费': '#91cc75',
  '收红包': '#ee6666',
  '外快': '#73c0de',
  '股票基金': '#3ba272',
  '其它': '#4d3c77',
};

String _mapCategoryColor(String name) =>
    _qianjiCategoryColorMap[name] ?? '#4d3c77';

BillsCompanion _buildBill({
  required String id,
  required BillType type,
  required String categoryId,
  required int amount,
  required String? accountId,
  String? incomeAccountId,
  required int time,
  required String comment,
  ({String currencyCode, int currencyAmount, String baseCurrency})? currency,
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
    comment: Value(comment.isEmpty ? null : comment),
    locationLat: const Value(null),
    locationLng: const Value(null),
    images: const Value(null),
    currencyCode: Value(currency?.currencyCode),
    currencyAmount: Value(currency?.currencyAmount),
    baseCurrency: Value(currency?.baseCurrency),
    extra: Value(extra),
    creatorId: const Value(null),
    createdAt: Value(time),
    updatedAt: Value(time),
  );
}
