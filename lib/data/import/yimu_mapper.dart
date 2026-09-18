import 'package:drift/drift.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/amount.dart';
import '../../core/utils/bill_extra.dart';
import '../../core/utils/ids.dart';
import '../database/app_database.dart';
import 'db_reader.dart';
import 'id_mapping.dart';
import 'import_models.dart';
import 'yimu_parser.dart';

/// 一木记账 → XuPurse 映射（对齐 cent-xyx yimu/mapper.ts，转账改单条模型）。
///
/// 设计约定：
/// - 金额「元」→ 万分之元（[yuanToAmount]）；时间毫秒直接使用。
/// - 转账：单条 Bill（accountId=转出, incomeAccountId=转入）+ Transfers 表存扩展。
/// - 所有实体按第三方业务 ID 经 [IdMapper] 幂等映射。
MappedImport mapYimuToXuPurse(
  YimuParsedData data,
  IdMapper idMapper,
  MapperContext ctx,
) {
  final stats = ImportStats();
  final warnings = <String>[];

  // 一木的收入父分类：categoryid=9 或名称含「收入」，其下子分类均为收入
  final incomeCategoryIds = <int>{};
  for (final parent in data.parentCategories) {
    final id = asInt(parent['categoryid']) ?? 0;
    final name = asString(parent['categoryname']);
    if (id == 9 || name.contains('收入')) incomeCategoryIds.add(id);
  }

  // ---------- 账户 ----------
  final accounts = <AccountsCompanion>[];
  for (final asset in data.assets) {
    final assetId = asInt(asset['assetid']);
    if (assetId == null) continue;
    final sourceId = '$assetId';
    final id = awaitMap(idMapper, 'account', sourceId);
    final isNew = idMapper.wasCreated('account', sourceId);
    final assetType = asInt(asset['assettype']) ?? 0;
    final category = assetType == 6
        ? AccountCategory.debt
        : assetType == 3
        ? AccountCategory.record
        : AccountCategory.fund;
    final name = asString(asset['assetname']);
    final now = ctx.now;
    final updatetime = asInt(asset['updatetime']) ?? now;
    final includeInAssets =
        category == AccountCategory.debt || category == AccountCategory.record
        ? asInt(asset['intototalasset']) == 1
        : asInt(asset['intototalasset']) != 0;
    accounts.add(
      AccountsCompanion(
        id: Value(id),
        name: Value(name.isEmpty ? '未命名账户' : name),
        category: Value(category.name),
        type: Value(_mapAccountType(asset).name),
        icon: const Value(null),
        color: const Value(null),
        initialBalance: Value(
          yuanToAmount(asDouble(asset['assetnumber']) ?? 0),
        ),
        currentBalance: Value(
          yuanToAmount(asDouble(asset['assetnumber']) ?? 0),
        ),
        currency: Value(
          asString(asset['currency']).isEmpty
              ? 'CNY'
              : asString(asset['currency']),
        ),
        includeInAssets: Value(includeInAssets),
        creditLimit: Value(
          asInt(asset['totalquota']) == null || asInt(asset['totalquota']) == 0
              ? null
              : yuanToAmount(asDouble(asset['totalquota'])!),
        ),
        cardCode: Value(
          asString(asset['cardcode']).isEmpty
              ? null
              : asString(asset['cardcode']),
        ),
        statementDate: Value<int?>(_parseDay(asString(asset['inaccountdate']))),
        repaymentDate: Value<int?>(
          _parseDay(asString(asset['outaccountdate'])),
        ),
        remark: Value(
          asString(asset['remark']).isEmpty ? null : asString(asset['remark']),
        ),
        enabled: Value(asInt(asset['hide']) != 1),
        yimuAssetId: Value(assetId),
        createdAt: Value(updatetime),
        updatedAt: Value(updatetime),
      ),
    );
    if (isNew) {
      stats.addCreated('account');
    } else {
      stats.addUpdated('account');
    }
  }

  // ---------- 分类（先父后子） ----------
  final categories = <CategoriesCompanion>[];
  for (final parent in data.parentCategories) {
    final cid = asInt(parent['categoryid']);
    if (cid == null) continue;
    final sourceId = 'parent_$cid';
    final id = awaitMap(idMapper, 'category', sourceId);
    final isNew = idMapper.wasCreated('category', sourceId);
    final name = asString(parent['categoryname']);
    final isIncome = incomeCategoryIds.contains(cid);
    categories.add(
      CategoriesCompanion(
        id: Value(id),
        type: Value(isIncome ? BillType.income.name : BillType.expense.name),
        name: Value(name),
        icon: const Value(null),
        color: Value(_mapCategoryColor(name)),
        parentId: const Value(null),
        customName: Value(true),
        defaultSelect: const Value(false),
        sort: Value(asInt(parent['positionweight']) ?? 0),
        seedKey: const Value(null),
        createdAt: Value(asInt(parent['updatetime']) ?? ctx.now),
        updatedAt: Value(asInt(parent['updatetime']) ?? ctx.now),
      ),
    );
    if (isNew) {
      stats.addCreated('category');
    } else {
      stats.addUpdated('category');
    }
  }
  for (final child in data.childCategories) {
    final cid = asInt(child['categoryid']);
    if (cid == null) continue;
    final sourceId = 'child_$cid';
    final id = awaitMap(idMapper, 'category', sourceId);
    final isNew = idMapper.wasCreated('category', sourceId);
    final parentId = idMapper.find(
      'category',
      'parent_${asInt(child['parentcategoryid']) ?? -1}',
    );
    final name = asString(child['categoryname']);
    final isIncome = incomeCategoryIds.contains(
      asInt(child['parentcategoryid']) ?? -1,
    );
    if (isIncome) incomeCategoryIds.add(cid);
    categories.add(
      CategoriesCompanion(
        id: Value(id),
        type: Value(isIncome ? BillType.income.name : BillType.expense.name),
        name: Value(name),
        icon: const Value(null),
        color: Value(_mapCategoryColor(name)),
        parentId: Value(parentId),
        customName: Value(true),
        defaultSelect: const Value(false),
        sort: Value(asInt(child['positionweight']) ?? 0),
        seedKey: const Value(null),
        createdAt: Value(asInt(child['updatetime']) ?? ctx.now),
        updatedAt: Value(asInt(child['updatetime']) ?? ctx.now),
      ),
    );
    if (isNew) {
      stats.addCreated('category');
    } else {
      stats.addUpdated('category');
    }
  }

  // ---------- 标签 ----------
  final tags = <TagsCompanion>[];
  for (final tag in data.tags) {
    final tagId = asInt(tag['tagid']);
    if (tagId == null) continue;
    final sourceId = '$tagId';
    final id = awaitMap(idMapper, 'tag', sourceId);
    final isNew = idMapper.wasCreated('tag', sourceId);
    final name = asString(tag['tagname']);
    if (name.isEmpty) continue;
    tags.add(
      TagsCompanion(
        id: Value(id),
        name: Value(name),
        color: const Value(null),
        groupId: const Value(null),
        preferCurrency: const Value(null),
        sort: Value(asInt(tag['positionweight']) ?? 0),
        createdAt: Value(asInt(tag['updatetime']) ?? ctx.now),
        updatedAt: Value(asInt(tag['updatetime']) ?? ctx.now),
      ),
    );
    if (isNew) {
      stats.addCreated('tag');
    } else {
      stats.addUpdated('tag');
    }
  }

  // ---------- 账单标签关联（bill_tags.bill_id 是 bill 表行 id，非 billid） ----------
  final tagIdsByRowId = <int, List<int>>{};
  for (final rel in data.billTags) {
    final billRowId = asInt(rel['bill_id']);
    final tagBid = asInt(rel['tags']);
    if (billRowId == null || tagBid == null) continue;
    (tagIdsByRowId[billRowId] ??= []).add(tagBid);
  }

  // ---------- 账单（可变 draft，退款抵扣金额） ----------
  final bills = <BillsCompanion>[];
  final billDrafts = <String, _BillDraft>{};
  final billTagIds = <String, List<String>>{};
  final transferCatId =
      ctx.fallbackCategoryId(BillType.transfer, ['transfer']) ?? '';
  final lendCatId =
      ctx.fallbackCategoryId(BillType.expense, ['loan-out']) ?? '';
  final collectCatId =
      ctx.fallbackCategoryId(BillType.income, ['other-income', 'refund']) ?? '';
  final instalmentCatId =
      ctx.fallbackCategoryId(BillType.expense, ['other-expenses']) ?? '';

  for (final yimuBill in data.bills) {
    final billid = asInt(yimuBill['billid']);
    if (billid == null) continue;
    final sourceId = '$billid';
    final id = awaitMap(idMapper, 'bill', sourceId);
    final isNew = idMapper.wasCreated('bill', sourceId);

    final isIncome =
        incomeCategoryIds.contains(asInt(yimuBill['parentcategoryid']) ?? -1) ||
        ((asInt(yimuBill['childcategoryid']) ?? 0) > 0 &&
            incomeCategoryIds.contains(asInt(yimuBill['childcategoryid'])));
    final type = asInt(yimuBill['billtype']) == 1 || isIncome
        ? BillType.income
        : BillType.expense;
    final categoryId = (asInt(yimuBill['childcategoryid']) ?? 0) > 0
        ? idMapper.find(
            'category',
            'child_${asInt(yimuBill['childcategoryid'])}',
          )
        : idMapper.find(
            'category',
            'parent_${asInt(yimuBill['parentcategoryid']) ?? -1}',
          );
    final accountId = idMapper.find(
      'account',
      '${asInt(yimuBill['assetid']) ?? -1}',
    );

    final tagIds = (tagIdsByRowId[asInt(yimuBill['id'])] ?? [])
        .map((tb) => idMapper.find('tag', '$tb'))
        .whereType<String>()
        .toList();

    final extraMap = <String, Object?>{
      'yimuBillId': billid,
      if (asInt(yimuBill['notintobudget']) == 1) 'notInBudget': true,
      if ((asInt(yimuBill['discountnumber']) ?? 0) != 0)
        'discountAmount': yuanToAmount(
          asDouble(yimuBill['discountnumber']) ?? 0,
        ),
      if (asInt(yimuBill['reimbursement']) == 1)
        'reimbursement': asInt(yimuBill['reimbursementend']) == 1
            ? 'done'
            : 'pending',
      if (asString(yimuBill['poiaddress']).isNotEmpty)
        'addressText': asString(yimuBill['poiaddress']),
    };

    final draft = _BillDraft(
      id: id,
      type: type,
      categoryId: categoryId ?? '',
      amount: yuanToAmount(asDouble(yimuBill['cost']) ?? 0),
      accountId: accountId,
      time: asInt(yimuBill['time']) ?? asInt(yimuBill['recordtime']) ?? ctx.now,
      comment: asString(yimuBill['remark']).isEmpty
          ? null
          : asString(yimuBill['remark']),
      extra: BillExtra(
        isYimu: true,
        // 一木「不计入收支」→ excludeFromStats，导入后保持不计入收支统计
        excludeFromStats: asInt(yimuBill['notintototal']) == 1,
        other: extraMap,
      ).encode(),
      currency: _parseCurrencyInfo(
        asString(yimuBill['currencyinfo']),
        fallbackAmount: asDouble(yimuBill['cost']) ?? 0,
      ),
    );
    billDrafts[id] = draft;
    if (tagIds.isNotEmpty) billTagIds[id] = tagIds;
    if (isNew) {
      stats.addCreated('bill');
    } else {
      stats.addUpdated('bill');
    }
  }

  // ---------- 转账（单条 Bill + Transfers 表） ----------
  final transfers = <TransfersCompanion>[];
  for (final t in data.transfers) {
    final transferId = asInt(t['transferid']);
    if (transferId == null) continue;
    final from = idMapper.find('account', '${asInt(t['fromassetid']) ?? -1}');
    final to = idMapper.find('account', '${asInt(t['toassetid']) ?? -1}');
    if (from == null || to == null) {
      warnings.add('转账 $transferId 因账户缺失被跳过');
      continue;
    }
    final sourceId = 'transfer_$transferId';
    final billId = awaitMap(idMapper, 'bill', sourceId);
    final isNew = idMapper.wasCreated('bill', sourceId);
    final transferIdX = idMapper.getOrCreateSync('transfer', sourceId, genId);
    final transferIsNew = idMapper.wasCreated('transfer', sourceId);
    final now = ctx.now;
    final time = asInt(t['time']) ?? now;
    final comment = asString(t['remark']).isEmpty
        ? null
        : asString(t['remark']);

    billDrafts[billId] = _BillDraft(
      id: billId,
      type: BillType.transfer,
      categoryId: transferCatId,
      amount: yuanToAmount(asDouble(t['cost']) ?? 0),
      accountId: from,
      incomeAccountId: to,
      time: time,
      comment: comment,
      extra: BillExtra(
        isYimu: true,
        other: {'yimuTransferId': transferId, 'yimuTransferDirection': 'out'},
      ).encode(),
    );
    transfers.add(
      TransfersCompanion(
        id: Value(transferIdX),
        billId: Value(billId),
        fromAccountId: Value(from),
        toAccountId: Value(to),
        amount: Value(yuanToAmount(asDouble(t['cost']) ?? 0)),
        toAmount: Value(yuanToAmount(asDouble(t['tocost']) ?? 0)),
        fee: Value(yuanToAmount(asDouble(t['servicecharge']) ?? 0)),
        time: Value(time),
        comment: Value(comment),
        yimuTransferId: Value(transferId),
        createdAt: Value(asInt(t['updatetime']) ?? now),
        updatedAt: Value(now),
      ),
    );
    if (isNew) {
      stats.addCreated('bill');
    } else {
      stats.addUpdated('bill');
    }
    if (transferIsNew) {
      stats.addCreated('transfer');
    } else {
      stats.addUpdated('transfer');
    }
  }

  // ---------- 借贷 ----------
  final lends = <LendsCompanion>[];
  for (final l in data.lends) {
    final lendId = asInt(l['lendid']);
    if (lendId == null) continue;
    final accountId = idMapper.find('account', '${asInt(l['assetid']) ?? -1}');
    if (accountId == null) continue;
    final sourceId = '$lendId';
    final id = awaitMap(idMapper, 'lend', sourceId);
    final isNew = idMapper.wasCreated('lend', sourceId);
    final isLend = asInt(l['type']) != 2;
    final now = ctx.now;
    final time = asInt(l['outtime']) ?? asInt(l['intime']) ?? now;
    final amount = yuanToAmount(asDouble(l['number']) ?? 0);
    final comment = asString(l['remark']).isEmpty
        ? null
        : asString(l['remark']);

    lends.add(
      LendsCompanion(
        id: Value(id),
        type: Value(isLend ? LendType.lend.name : LendType.collect.name),
        accountId: Value(accountId),
        repaymentAccountId: Value(
          idMapper.find('account', '${asInt(l['repaymentassetid']) ?? -1}'),
        ),
        amount: Value(amount),
        interest: Value(yuanToAmount(asDouble(l['interest']) ?? 0)),
        originalAmount: Value(yuanToAmount(asDouble(l['fromcost']) ?? 0)),
        billId: const Value(null),
        time: Value(time),
        comment: Value(comment),
        yimuLendId: Value(lendId),
        createdAt: Value(asInt(l['createtime']) ?? now),
        updatedAt: Value(asInt(l['updatetime']) ?? now),
      ),
    );
    // 生成借贷对应账单
    final billSourceId = 'lend_$lendId';
    final billId = awaitMap(idMapper, 'bill', billSourceId);
    final billIsNew = idMapper.wasCreated('bill', billSourceId);
    billDrafts[billId] = _BillDraft(
      id: billId,
      type: isLend ? BillType.expense : BillType.income,
      categoryId: isLend ? lendCatId : collectCatId,
      amount: amount,
      accountId: accountId,
      time: time,
      comment: comment ?? (isLend ? '借出' : '收回'),
      extra: BillExtra(
        isYimu: true,
        other: {'yimuLendId': lendId, 'isYimuLend': true},
      ).encode(),
    );
    if (isNew) {
      stats.addCreated('lend');
    } else {
      stats.addUpdated('lend');
    }
    if (billIsNew) {
      stats.addCreated('bill');
    } else {
      stats.addUpdated('bill');
    }
  }

  // ---------- 退款（抵扣原账单金额；原账单金额为 0 时生成收入账单） ----------
  final refunds = <RefundsCompanion>[];
  for (final r in data.refunds) {
    final refundId = asInt(r['refundid']);
    if (refundId == null) continue;
    final originalBillId = idMapper.find('bill', '${asInt(r['billid']) ?? -1}');
    if (originalBillId == null) continue;
    final sourceId = '$refundId';
    final id = awaitMap(idMapper, 'refund', sourceId);
    final isNew = idMapper.wasCreated('refund', sourceId);
    final now = ctx.now;
    final amount = yuanToAmount(asDouble(r['refundnum']) ?? 0);
    final refundTime = asInt(r['updatetime']) ?? now;

    refunds.add(
      RefundsCompanion(
        id: Value(id),
        billId: Value(originalBillId),
        amount: Value(amount),
        time: Value(refundTime),
        comment: const Value(null),
        yimuRefundId: Value(refundId),
        createdAt: Value(refundTime),
        updatedAt: Value(now),
      ),
    );
    if (isNew) {
      stats.addCreated('refund');
    } else {
      stats.addUpdated('refund');
    }

    final original = billDrafts[originalBillId];
    if (original != null && original.accountId != null) {
      if (original.amount > 0) {
        final refundAmount = amount > original.amount
            ? original.amount
            : amount;
        original.amount -= refundAmount;
        original.extra = BillExtra(
          isYimu: true,
          other: {
            ...original.extraOther,
            'isYimuRefund': true,
            'yimuRefundId': refundId,
            'yimuRefundAmount':
                (original.extraOther['yimuRefundAmount'] as int? ?? 0) +
                refundAmount,
          },
        ).encode();
      } else {
        final billSourceId = 'refund_$refundId';
        final billId = awaitMap(idMapper, 'bill', billSourceId);
        final billIsNew = idMapper.wasCreated('bill', billSourceId);
        billDrafts[billId] = _BillDraft(
          id: billId,
          type: BillType.income,
          categoryId: ctx.fallbackCategoryId(BillType.income, ['refund']) ?? '',
          amount: amount,
          accountId: original.accountId,
          time: refundTime,
          comment: '退款',
          extra: BillExtra(
            isYimu: true,
            other: {
              'isYimuRefund': true,
              'yimuRefundId': refundId,
              'refundBillId': originalBillId,
            },
          ).encode(),
        );
        if (billIsNew) {
          stats.addCreated('bill');
        } else {
          stats.addUpdated('bill');
        }
      }
    }
  }

  // ---------- 报销 ----------
  final reimbursements = <ReimbursementsCompanion>[];
  for (final r in data.reimbursements) {
    final rid = asInt(r['reimbursementid']);
    if (rid == null) continue;
    final originalBillId = idMapper.find('bill', '${asInt(r['billid']) ?? -1}');
    if (originalBillId == null) continue;
    final sourceId = '$rid';
    final id = awaitMap(idMapper, 'reimbursement', sourceId);
    final isNew = idMapper.wasCreated('reimbursement', sourceId);
    final now = ctx.now;
    final createTime = asInt(r['createtime']) ?? now;
    final accountId = idMapper.find('account', '${asInt(r['assetid']) ?? -1}');
    final reimbursementAccountId = idMapper.find(
      'account',
      '${asInt(r['reimbursementassetid']) ?? -1}',
    );
    final amount = yuanToAmount(asDouble(r['reimbursementnum']) ?? 0);

    reimbursements.add(
      ReimbursementsCompanion(
        id: Value(id),
        billId: Value(originalBillId),
        amount: Value(amount),
        accountId: Value(accountId),
        reimbursementAccountId: Value(reimbursementAccountId),
        ended: Value(asInt(r['end_lpcolumn']) == 1),
        time: Value(createTime),
        comment: const Value(null),
        yimuReimbursementId: Value(rid),
        createdAt: Value(createTime),
        updatedAt: Value(asInt(r['updatetime']) ?? now),
      ),
    );
    if (isNew) {
      stats.addCreated('reimbursement');
    } else {
      stats.addUpdated('reimbursement');
    }

    final targetAccountId = reimbursementAccountId ?? accountId;
    if (targetAccountId != null) {
      final billSourceId = 'reimbursement_$rid';
      final billId = awaitMap(idMapper, 'bill', billSourceId);
      final billIsNew = idMapper.wasCreated('bill', billSourceId);
      billDrafts[billId] = _BillDraft(
        id: billId,
        type: BillType.income,
        categoryId:
            ctx.fallbackCategoryId(BillType.income, ['other-income']) ?? '',
        amount: amount,
        accountId: targetAccountId,
        time: createTime,
        comment: '报销',
        extra: BillExtra(
          isYimu: true,
          other: {'isYimuReimbursement': true, 'yimuReimbursementId': rid},
        ).encode(),
      );
      if (billIsNew) {
        stats.addCreated('bill');
      } else {
        stats.addUpdated('bill');
      }
    }
  }

  // ---------- 分期 ----------
  final instalments = <InstalmentsCompanion>[];
  for (final i in data.instalments) {
    final iid = asInt(i['instalmentid']);
    if (iid == null) continue;
    final originalBillId = idMapper.find('bill', '${asInt(i['billid']) ?? -1}');
    final accountId = idMapper.find('account', '${asInt(i['assetid']) ?? -1}');
    if (originalBillId == null || accountId == null) continue;
    final sourceId = '$iid';
    final id = awaitMap(idMapper, 'instalment', sourceId);
    final isNew = idMapper.wasCreated('instalment', sourceId);
    final now = ctx.now;
    final total = yuanToAmount(asDouble(i['totalnumber']) ?? 0);
    final fee = yuanToAmount(asDouble(i['servicenumber']) ?? 0);
    final time = asInt(i['inassettime']) ?? now;

    instalments.add(
      InstalmentsCompanion(
        id: Value(id),
        billId: Value(originalBillId),
        accountId: Value(accountId),
        totalAmount: Value(total),
        serviceFee: Value(fee),
        periods: Value(asInt(i['periods']) ?? 0),
        accountMonth: Value(
          asString(i['accountmonth']).isEmpty
              ? null
              : asString(i['accountmonth']),
        ),
        time: Value(time),
        yimuInstalmentId: Value(iid),
        createdAt: Value(asInt(i['updatetime']) ?? now),
        updatedAt: Value(asInt(i['updatetime']) ?? now),
      ),
    );
    if (isNew) {
      stats.addCreated('instalment');
    } else {
      stats.addUpdated('instalment');
    }

    final billSourceId = 'instalment_$iid';
    final billId = awaitMap(idMapper, 'bill', billSourceId);
    final billIsNew = idMapper.wasCreated('bill', billSourceId);
    billDrafts[billId] = _BillDraft(
      id: billId,
      type: BillType.expense,
      categoryId: instalmentCatId,
      amount: total + fee,
      accountId: accountId,
      time: time,
      comment: '分期',
      extra: BillExtra(
        isYimu: true,
        other: {'isYimuInstalment': true, 'yimuInstalmentId': iid},
      ).encode(),
    );
    if (billIsNew) {
      stats.addCreated('bill');
    } else {
      stats.addUpdated('bill');
    }
  }

  // ---------- 预算 ----------
  final budgets = <BudgetsCompanion>[];
  for (final b in data.budgets) {
    final budgetId = asInt(b['budgetid']);
    final year = asInt(b['year']) ?? DateTime.now().year;
    final month = asInt(b['month']) ?? 0;
    final hasBusinessId = budgetId != null && budgetId > 0;
    final sourceId = hasBusinessId ? '$budgetId' : '${year}_$month';
    final id = awaitMap(idMapper, 'budget', sourceId);
    final isNew = idMapper.wasCreated('budget', sourceId);
    final start = DateTime(year, month, 1).millisecondsSinceEpoch;
    final end = DateTime(year, month + 1, 0).millisecondsSinceEpoch;
    final name = asString(b['budgetname']).isEmpty
        ? '$year年${month + 1}月预算'
        : asString(b['budgetname']);

    budgets.add(
      BudgetsCompanion(
        id: Value(id),
        name: Value(name),
        categoryId: const Value(null),
        type: Value(BillType.expense.name),
        periodType: Value(BudgetPeriodType.month.name),
        amount: Value(yuanToAmount(asDouble(b['num']) ?? 0)),
        startTime: Value(start),
        endTime: Value(end),
        enabled: const Value(true),
        yimuBudgetId: Value(budgetId),
        createdAt: Value(asInt(b['updatetime']) ?? ctx.now),
        updatedAt: Value(asInt(b['updatetime']) ?? ctx.now),
      ),
    );
    if (isNew) {
      stats.addCreated('budget');
    } else {
      stats.addUpdated('budget');
    }
  }

  // ---------- 快照（按 账户+本地日 分组，每天取 time 最新一条） ----------
  final snapshots = <BalanceSnapshotsCompanion>[];
  final groups = <String, Map<String, Object?>>{};
  for (final h in data.assetHistories) {
    final time = asInt(h['time']) ?? 0;
    if (time == 0) continue;
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    final key =
        '${asInt(h['assetid']) ?? -1}_${date.year}_${date.month}_${date.day}';
    final prev = groups[key];
    if (prev == null || time > (asInt(prev['time']) ?? 0)) {
      groups[key] = h;
    }
  }
  for (final entry in groups.entries) {
    final latest = entry.value;
    final assetId = asInt(latest['assetid']);
    final accountId = idMapper.find('account', '${assetId ?? -1}');
    if (accountId == null) continue;
    final ahId = asInt(latest['assethistoryid']);
    if (ahId == null) continue;
    final sourceId = '$ahId';
    final id = awaitMap(idMapper, 'snapshot', sourceId);
    final isNew = idMapper.wasCreated('snapshot', sourceId);
    final content = asString(latest['changecontent']);
    final changeNum = asInt(latest['changenum']) ?? 0;
    final time = asInt(latest['time']) ?? ctx.now;
    var type = SnapshotType.historical;
    if (content.contains('新增账单')) {
      type = changeNum > 0 ? SnapshotType.income : SnapshotType.expense;
    } else if (content.contains('转账')) {
      type = changeNum > 0 ? SnapshotType.transferIn : SnapshotType.transferOut;
    } else if (content.contains('资产账户编辑')) {
      type = SnapshotType.manual;
    }

    snapshots.add(
      BalanceSnapshotsCompanion(
        id: Value(id),
        accountId: Value(accountId),
        balance: Value(yuanToAmount(asDouble(latest['currentnum']) ?? 0)),
        timestamp: Value(time),
        note: Value(content.isEmpty ? null : content),
        isValid: const Value(true),
        billId: const Value(null),
        type: Value(type),
        yimuAssetHistoryId: Value(ahId),
      ),
    );
    if (isNew) {
      stats.addCreated('snapshot');
    } else {
      stats.addUpdated('snapshot');
    }
  }

  // ---------- 汇总输出 ----------
  for (final draft in billDrafts.values) {
    bills.add(draft.toCompanion());
  }

  return MappedImport(
    stats: stats,
    warnings: warnings,
    accounts: accounts,
    categories: categories,
    tags: tags,
    bills: bills,
    billTagIds: billTagIds,
    snapshots: snapshots,
    transfers: transfers,
    lends: lends,
    refunds: refunds,
    reimbursements: reimbursements,
    instalments: instalments,
    budgets: budgets,
  );
}

/// 同步辅助：idMapper.getOrCreate（preview 入口已 loadAll，故可同步调用）。
String awaitMap(IdMapper idMapper, String entityType, String sourceId) =>
    idMapper.getOrCreateSync(entityType, sourceId, genId);

AccountType _mapAccountType(Map<String, Object?> asset) {
  final icon = asString(asset['asseticon']);
  final name = asString(asset['assetname']);
  final assetType = asInt(asset['assettype']) ?? 0;
  if (icon.contains('zhifubao') || name.contains('支付宝')) {
    return AccountType.alipay;
  }
  if (icon.contains('weixin') || name.contains('微信')) {
    return AccountType.wechat;
  }
  if (icon.contains('xianjin') || name.contains('现金')) {
    return AccountType.cash;
  }
  if (icon.contains('fangzi') || name.contains('公积金') || assetType == 3) {
    return AccountType.investment;
  }
  if (icon.contains('jiechu') || assetType == 6) {
    return AccountType.other;
  }
  if (icon.contains('bank') || name.contains('银行')) {
    return AccountType.bank;
  }
  return AccountType.other;
}

const _categoryColorMap = <String, String>{
  '健康医疗': '#3ba272',
  '送礼人情': '#ea7ccc',
  '文化教育': '#9a60b4',
  '居家生活': '#ee6666',
  '休闲娱乐': '#73c0de',
  '出行交通': '#91cc75',
  '食品餐饮': '#5470c6',
  '收入': '#fac858',
  '其他': '#4d3c77',
  '购物消费': '#fac858',
  '理发美容': '#f472b6',
};

String _mapCategoryColor(String name) => _categoryColorMap[name] ?? '#4d3c77';

/// 解析 yyyy-MM-dd / dd 为「日」；失败返回 null。
int? _parseDay(String v) {
  if (v.isEmpty) return null;
  final trimmed = v.trim();
  final last = trimmed.split('-').last;
  return int.tryParse(last);
}

/// 解析一木 currencyinfo JSON（{base, target, amount}）。
({String currencyCode, int currencyAmount, String baseCurrency})?
_parseCurrencyInfo(String json, {required double fallbackAmount}) {
  if (json.isEmpty) return null;
  final info = safeParseJson(json);
  final base = asString(info['base']);
  final target = asString(info['target']);
  if (base.isEmpty || target.isEmpty) return null;
  return (
    currencyCode: target,
    currencyAmount: yuanToAmount(asDouble(info['amount']) ?? fallbackAmount),
    baseCurrency: base,
  );
}

/// 可变账单草稿（退款抵扣需要修改 amount/extra）。
class _BillDraft {
  _BillDraft({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.accountId,
    this.incomeAccountId,
    required this.time,
    this.comment,
    required this.extra,
    this.currency,
  });

  final String id;
  final BillType type;
  final String categoryId;
  int amount;
  final String? accountId;
  String? incomeAccountId;
  final int time;
  String? comment;
  String? extra;
  ({String currencyCode, int currencyAmount, String baseCurrency})? currency;

  /// 当前 extra 中 other 字段（用于退款累计）
  Map<String, Object?> get extraOther {
    if (extra == null) return {};
    final decoded = BillExtra.fromJson(extra);
    return decoded.other;
  }

  BillsCompanion toCompanion() {
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
}
