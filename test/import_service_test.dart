import 'dart:typed_data';

import 'package:drift/drift.dart' show Expression, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:xupurse/core/constants/enums.dart';
import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/data/database/database_manager.dart';
import 'package:xupurse/data/import/import_models.dart';
import 'package:xupurse/data/import/import_service.dart';
import 'package:xupurse/domain/services/bill_service.dart';

/// 构造第三方 .db 文件字节流（内存 VFS 建库后导出）。
Uint8List _buildDb(void Function(Database db) build) {
  final vfs = InMemoryFileSystem(
    name: 'test_src_${DateTime.now().microsecondsSinceEpoch}',
  );
  sqlite3.registerVirtualFileSystem(vfs);
  final db = sqlite3.open('/src.db', vfs: vfs.name);
  try {
    build(db);
    final file = vfs.fileData['/src.db']!;
    return Uint8List.fromList(file);
  } finally {
    db.dispose();
  }
}

/// 钱迹最小库：1 资产账户 + 1 分类 + 支出/收入/转账/债务账单
Uint8List _buildQianjiDb() {
  return _buildDb((db) {
    db.execute('''
      CREATE TABLE user_book (id INTEGER PRIMARY KEY, name TEXT, bookid INTEGER);
      CREATE TABLE user_asset (
        id INTEGER PRIMARY KEY, name TEXT, money REAL, type INTEGER, stype INTEGER,
        currency TEXT, createtime INTEGER, lastpaytime INTEGER, extra TEXT
      );
      CREATE TABLE category (
        id INTEGER PRIMARY KEY, name TEXT, type INTEGER, sort INTEGER, icon TEXT
      );
      CREATE TABLE user_bill (
        id INTEGER PRIMARY KEY, billid INTEGER, time INTEGER, type INTEGER,
        remark TEXT, money REAL, categoryid INTEGER, assetid INTEGER,
        fromid INTEGER, targetid INTEGER, extra TEXT
      );
    ''');
    db.execute("INSERT INTO user_book VALUES (1, '我的账本', 1)");
    db.execute('''
      INSERT INTO user_asset VALUES
        (1, '支付宝', 1000.50, 1, 13, 'CNY', 1700000000, 1701000000, '{"initmoney": 500}'),
        (2, '现金', 200, 1, 0, 'CNY', 1700000001, 0, NULL);
    ''');
    db.execute('''
      INSERT INTO category VALUES
        (1, '三餐', 0, 1, 'food'),
        (2, '工资', 1, 1, 'wage'),
        (3, '自定义支出', 0, 9, 'tag');
    ''');
    db.execute('''
      INSERT INTO user_bill VALUES
        (1, 101, 1700000100, 0, '午餐', 25.5, 1, 1, -1, -1, NULL),
        (2, 102, 1700000200, 1, '一月工资', 8000, 2, 1, -1, -1, NULL),
        (3, 103, 1700000300, 2, '转给现金', 300, -1, -1, 1, 2, NULL),
        (4, 104, 1700000400, 7, '借给朋友', 1000, -1, -1, 1, -1, NULL),
        (5, 105, 1700000500, 0, '自定义支出', 12, 3, 1, -1, -1, NULL);
    ''');
  });
}

/// 一木最小库：账户 + 分类 + 账单 + 转账 + 快照 + 预算
Uint8List _buildYimuDb() {
  return _buildDb((db) {
    db.execute('''
      CREATE TABLE accountbook (id INTEGER PRIMARY KEY, bookname TEXT, delete_lpcolumn INTEGER);
      CREATE TABLE asset (
        id INTEGER PRIMARY KEY, assetid INTEGER, assetname TEXT, assetnumber REAL,
        assettype INTEGER, currency TEXT, hide INTEGER, intototalasset INTEGER,
        asseticon TEXT, delete_lpcolumn INTEGER
      );
      CREATE TABLE parentcategory (
        id INTEGER PRIMARY KEY, categoryid INTEGER, categoryname TEXT,
        categorytype INTEGER, delete_lpcolumn INTEGER
      );
      CREATE TABLE childcategory (
        id INTEGER PRIMARY KEY, categoryid INTEGER, categoryname TEXT,
        parentcategoryid INTEGER, delete_lpcolumn INTEGER
      );
      CREATE TABLE tag (id INTEGER PRIMARY KEY, tagid INTEGER, tagname TEXT, delete_lpcolumn INTEGER);
      CREATE TABLE bill (
        id INTEGER PRIMARY KEY, billid INTEGER, cost REAL, time INTEGER,
        remark TEXT, billtype INTEGER, assetid INTEGER, parentcategoryid INTEGER,
        childcategoryid INTEGER, delete_lpcolumn INTEGER
      );
      CREATE TABLE bill_tags (bill_id INTEGER, tags INTEGER);
      CREATE TABLE transfer (
        id INTEGER PRIMARY KEY, transferid INTEGER, fromassetid INTEGER,
        toassetid INTEGER, cost REAL, tocost REAL, servicecharge REAL, time INTEGER, delete_lpcolumn INTEGER
      );
      CREATE TABLE lend (
        id INTEGER PRIMARY KEY, lendid INTEGER, assetid INTEGER, type INTEGER,
        number REAL, interest REAL, fromcost REAL, outtime INTEGER, remark TEXT, delete_lpcolumn INTEGER
      );
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY, budgetid INTEGER, year INTEGER, month INTEGER,
        num REAL, budgetname TEXT, delete_lpcolumn INTEGER
      );
      CREATE TABLE assethistory (
        id INTEGER PRIMARY KEY, assethistoryid INTEGER, assetid INTEGER,
        currentnum REAL, changenum REAL, changecontent TEXT, time INTEGER, delete_lpcolumn INTEGER
      );
      CREATE TABLE refund (
        id INTEGER PRIMARY KEY, refundid INTEGER, billid INTEGER, refundnum REAL, delete_lpcolumn INTEGER
      );
      CREATE TABLE reimbursement (
        id INTEGER PRIMARY KEY, reimbursementid INTEGER, billid INTEGER,
        reimbursementnum REAL, assetid INTEGER, reimbursementassetid INTEGER, delete_lpcolumn INTEGER
      );
      CREATE TABLE instalment (
        id INTEGER PRIMARY KEY, instalmentid INTEGER, billid INTEGER, assetid INTEGER,
        totalnumber REAL, servicenumber REAL, periods INTEGER, inassettime INTEGER, delete_lpcolumn INTEGER
      );
    ''');
    db.execute("INSERT INTO accountbook VALUES (1, '一木账本', 0)");
    db.execute('''
      INSERT INTO asset VALUES
        (1, 11, '支付宝', 1000, 1, 'CNY', 0, 1, 'zhifubao', 0),
        (2, 12, '现金', 200, 1, 'CNY', 0, 1, 'xianjin', 0);
    ''');
    db.execute('''
      INSERT INTO parentcategory VALUES
        (1, 1, '食品餐饮', 1, 0),
        (2, 9, '收入', 1, 0);
    ''');
    db.execute('''
      INSERT INTO childcategory VALUES
        (1, 101, '午餐', 1, 0),
        (2, 102, '工资', 9, 0);
    ''');
    db.execute("INSERT INTO tag VALUES (1, 1001, '日常', 0)");
    db.execute('''
      INSERT INTO bill VALUES
        (1, 201, 30, 1700000100000, '午餐', 0, 11, 1, 101, 0),
        (2, 202, 8000, 1700000200000, NULL, 1, 11, 9, 102, 0),
        (3, 203, 50, 1700000300000, '打车', 0, 12, 1, 101, 0);
    ''');
    db.execute('INSERT INTO bill_tags VALUES (1, 1001)');
    db.execute('''
      INSERT INTO transfer VALUES
        (1, 301, 11, 12, 300, 298, 2, 1700000400000, 0);
    ''');
    db.execute('''
      INSERT INTO lend VALUES
        (1, 401, 11, 1, 1000, 0, 1000, 1700000500000, '借给朋友', 0);
    ''');
    db.execute("INSERT INTO budget VALUES (1, 501, 2026, 0, 5000, '1月预算', 0)");
    db.execute('''
      INSERT INTO assethistory VALUES
        (1, 601, 11, 1000, 0, '资产账户编辑', 1700000000000, 0),
        (2, 602, 11, 970, -30, '新增账单', 1700086400000, 0);
    ''');
    db.execute("INSERT INTO refund VALUES (1, 701, 201, 5, 0)");
    db.execute("INSERT INTO reimbursement VALUES (1, 801, 201, 50, 11, 12, 0)");
    db.execute(
      "INSERT INTO instalment VALUES (1, 901, 201, 11, 1200, 60, 12, 1700000600000, 0)",
    );
  });
}

/// 昼虎最小库：账户 + 分类 + 账单 + 变动记录 + 预算
Uint8List _buildZhouhuDb() {
  return _buildDb((db) {
    db.execute('''
      CREATE TABLE account_book (id INTEGER PRIMARY KEY, name TEXT, extdata TEXT);
      CREATE TABLE account (
        id INTEGER PRIMARY KEY, name TEXT, accountType INTEGER, balance REAL,
        currencyCode TEXT, note TEXT, disuse INTEGER, notProperty INTEGER,
        billDay INTEGER, refundDay INTEGER
      );
      CREATE TABLE category (id INTEGER PRIMARY KEY, name TEXT, type INTEGER, "index" INTEGER);
      CREATE TABLE bill (
        id INTEGER PRIMARY KEY, name TEXT, billType INTEGER, money REAL,
        accountId INTEGER, categoryId INTEGER, createTime INTEGER,
        transferToId INTEGER, note TEXT, extdata TEXT
      );
      CREATE TABLE account_change_log (
        id INTEGER PRIMARY KEY, accountId INTEGER, billId INTEGER, content TEXT,
        change REAL, type INTEGER, createTime INTEGER
      );
      CREATE TABLE budget (
        id INTEGER PRIMARY KEY, name TEXT, defaultAmount REAL, billType INTEGER,
        startTime INTEGER, endTime INTEGER, createTime INTEGER, modifyTime INTEGER
      );
    ''');
    db.execute(
      "INSERT INTO account_book VALUES (1, '昼虎账本', '{\"monthBudget\": 5000}')",
    );
    db.execute('''
      INSERT INTO account VALUES
        (1, '支付宝', 4, 1000, 'CNY', '', 0, 0, 5, 15),
        (2, '招商银行', 2, 2000, 'CNY', '', 0, 0, NULL, NULL);
    ''');
    db.execute(
      "INSERT INTO category VALUES (1, 'basedata.diet', 0, 1), (2, 'basedata.wage', 2, 1)",
    );
    db.execute('''
      INSERT INTO bill VALUES
        (1, '', 0, 25.5, 1, 1, 1700000100000, NULL, '午餐', NULL),
        (2, '', 2, 8000, 1, 2, 1700000200000, NULL, '工资', NULL),
        (3, '', 0, 300, 1, 1, 1700000300000, 2, '转账', NULL);
    ''');
    db.execute('''
      INSERT INTO account_change_log VALUES
        (1, 1, NULL, '初始', 1000, 3, 1700000000),
        (2, 1, 1, '午餐', -25.5, 1, 1700000100),
        (3, 2, NULL, '初始', 2000, 3, 1700000000);
    ''');
    db.execute(
      "INSERT INTO budget VALUES (1, 'basedata.monthly', 3000, 1, 1700000000000, 1702500000, 1700000000000, 1700000000)",
    );
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('钱迹导入', () {
    test('完整导入：账户/分类/账单/转账/债务 + 幂等', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      // 清空种子账户，避免与导入账户同名冲突
      await db.delete(db.accounts).go();
      final service = ImportService(db);

      final bytes = _buildQianjiDb();
      final preview = await service.preview(
        source: ImportSource.qianji,
        bytes: bytes,
        fileName: 'qianji.db',
      );

      // 账户 2 个、分类复用 2 个种子 + 新建 1 个、账单 5 条（转账 1 单条）
      expect(preview.mapped.accounts.length, 2);
      expect(preview.mapped.categories.length, 1, reason: '三餐/工资复用种子，仅自定义新建');
      expect(preview.mapped.bills.length, 5);

      final result = await service.write(preview);
      expect(result.created, greaterThan(0));
      expect(result.skippedAccounts, 0);

      // 金额无损：25.5 元 = 255000 万分之元
      final bills = await db.select(db.bills).get();
      expect(bills.length, 5);
      final lunch = bills.firstWhere((b) => b.comment == '午餐');
      expect(lunch.amount, 255000);
      // 时间秒 → 毫秒
      expect(lunch.time, 1700000100000);
      // 转账单条模型
      final transfer = bills.firstWhere((b) => b.type == 'transfer');
      expect(transfer.incomeAccountId, isNotNull);
      // 收入分类复用了种子分类 wage
      final wage = bills.firstWhere((b) => b.comment == '一月工资');
      final wageCategory = await (db.select(
        db.categories,
      )..where((t) => t.id.equals(wage.categoryId))).getSingle();
      expect(wageCategory.seedKey, 'wage');

      // 账户余额以第三方权威值
      final alipay = await (db.select(
        db.accounts,
      )..where((t) => t.name.equals('支付宝'))).getSingle();
      expect(alipay.currentBalance, 10005000);

      // ---------- 幂等：同一文件再次导入不产生重复 ----------
      final before = await db.select(db.bills).get();
      final preview2 = await service.preview(
        source: ImportSource.qianji,
        bytes: bytes,
      );
      await service.write(preview2);
      final after = await db.select(db.bills).get();
      expect(after.length, before.length, reason: '重复导入不应产生新账单');
    });

    test('增量模式跳过已有数据不覆盖本地修改；覆盖模式恢复第三方数据', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      // 清空种子账户，避免与导入账户同名冲突
      await db.delete(db.accounts).go();
      final service = ImportService(db);
      final bytes = _buildQianjiDb();

      // 第一次覆盖导入
      final preview1 = await service.preview(
        source: ImportSource.qianji,
        bytes: bytes,
      );
      final result1 = await service.write(preview1, mode: ImportMode.overwrite);
      expect(result1.skipped, 0, reason: '首次导入无已存在记录可跳过');
      final bill1 = (await db.select(db.bills).get()).first;
      final billCount = (await db.select(db.bills).get()).length;

      // 模拟本地修改：改一条账单备注
      await (db.update(db.bills)..where((t) => t.id.equals(bill1.id))).write(
        BillsCompanion(comment: Value('本地修改')),
      );

      // 增量导入：全部命中已有映射 → 跳过，本地修改保留
      final preview2 = await service.preview(
        source: ImportSource.qianji,
        bytes: bytes,
      );
      final result2 = await service.write(
        preview2,
        mode: ImportMode.incremental,
      );
      expect(result2.created, 0, reason: '无新实体');
      expect(result2.skipped, greaterThan(0), reason: '已导入记录全部跳过');
      expect(result2.updated, 0, reason: '增量模式不执行更新');
      expect((await db.select(db.bills).get()).length, billCount);
      final localBill = await (db.select(
        db.bills,
      )..where((t) => t.id.equals(bill1.id))).getSingle();
      expect(localBill.comment, '本地修改', reason: '增量模式不应覆盖本地修改');

      // 覆盖导入：用第三方数据覆盖本地修改
      final preview3 = await service.preview(
        source: ImportSource.qianji,
        bytes: bytes,
      );
      final result3 = await service.write(preview3, mode: ImportMode.overwrite);
      expect(result3.skipped, 0);
      expect(result3.updated, greaterThan(0), reason: '覆盖模式更新已存在记录');
      final restored = await (db.select(
        db.bills,
      )..where((t) => t.id.equals(bill1.id))).getSingle();
      expect(restored.comment, isNot('本地修改'), reason: '覆盖模式恢复第三方数据');
    });

    test('同名账户合并候选检测', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      // 清空种子账户，仅保留一个现有同名「支付宝」
      await db.delete(db.accounts).go();
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'existing-alipay',
              name: '支付宝',
              category: 'fund',
              type: 'alipay',
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      final service = ImportService(db);
      final preview = await service.preview(
        source: ImportSource.qianji,
        bytes: _buildQianjiDb(),
      );
      expect(preview.mergeCandidates, isNotEmpty);
      final candidate = preview.mergeCandidates.firstWhere(
        (c) => c.name == '支付宝',
      );
      // 钱迹账户 lastpaytime（1701000000000）晚于现有账户 updatedAt(1) →
      // 导入账户为保留方，现有「支付宝」被合并。
      expect(candidate.sourceId, 'existing-alipay');
      expect(candidate.targetId, isNot('existing-alipay'));

      // 确认合并：现有支付宝 → 导入支付宝，导入后不产生重复账户
      final mergeMap = {candidate.sourceId: candidate.targetId};
      await service.write(preview, mergeMap: mergeMap);
      final alipays = await (db.select(
        db.accounts,
      )..where((t) => t.name.equals('支付宝'))).get();
      expect(alipays.length, 1);
      expect(alipays.single.id, candidate.targetId);
      // 被合并的现有账户已删除，账单指向保留方（导入账户）
      final bills = await (db.select(
        db.bills,
      )..where((t) => t.accountId.equals(alipays.single.id))).get();
      expect(bills, isNotEmpty);
      // 保留方（导入账户）继承第三方权威余额与初始余额（钱迹 initmoney=500 元）
      expect(alipays.single.currentBalance, 10005000);
      expect(alipays.single.initialBalance, 5000000);
    });

    test('同名合并：existing 更新更晚为保留方，target 已有流水时叠加导入净变化', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      await db.delete(db.accounts).go();
      // 现有账户：初始 100 元，一笔 25.5 元支出 → 余额 74.5 元；
      // updatedAt（1701000000001）晚于钱迹账户 lastpaytime（1701000000000）→ 现有账户为保留方
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'existing-alipay',
              name: '支付宝',
              category: 'fund',
              type: 'alipay',
              initialBalance: const Value(1000000),
              currentBalance: const Value(745000),
              createdAt: 1,
              updatedAt: 1701000000001,
            ),
          );
      final cats = await db.select(db.categories).get();
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'b-local',
              type: 'expense',
              categoryId: cats.first.id,
              amount: 255000,
              accountId: const Value('existing-alipay'),
              time: 1700000100000,
              createdAt: 1700000100000,
              updatedAt: 1700000100000,
            ),
          );
      final service = ImportService(db);
      final preview = await service.preview(
        source: ImportSource.qianji,
        bytes: _buildQianjiDb(),
      );
      final candidate = preview.mergeCandidates.firstWhere(
        (c) => c.name == '支付宝',
      );
      await service.write(
        preview,
        mergeMap: {candidate.sourceId: candidate.targetId},
      );
      // 74.5 + (1000.50 - 500) = 575 元；初始余额保留本地值
      final merged = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals('existing-alipay'))).getSingle();
      expect(merged.currentBalance, 5750000);
      expect(merged.initialBalance, 1000000);
    });
  });

  group('一木导入', () {
    test('账户/分类/标签/账单/转账/借贷/退款/报销/分期/预算/快照全链路 + 幂等', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      final service = ImportService(db);

      final preview = await service.preview(
        source: ImportSource.yimu,
        bytes: _buildYimuDb(),
        fileName: 'yimu.db',
      );

      expect(preview.mapped.accounts.length, 2);
      expect(preview.mapped.categories.length, 0, reason: '分类全部名称命中一木体系种子，直接复用不新建');
      expect(preview.mapped.tags.length, 1);
      expect(preview.mapped.transfers.length, 1);
      expect(preview.mapped.lends.length, 1);
      expect(preview.mapped.refunds.length, 1);
      expect(preview.mapped.reimbursements.length, 1);
      expect(preview.mapped.instalments.length, 1);
      expect(preview.mapped.budgets.length, 1);
      expect(preview.mapped.snapshots.length, 2, reason: '按天分组取最新');

      final result = await service.write(preview);
      expect(result.created, greaterThan(0));

      final bills = await db.select(db.bills).get();
      // 3 原始账单 + 1 转账 + 1 借贷 + 1 报销 + 1 分期 = 7
      expect(bills.length, 7);

      // 退款抵扣：原午餐账单 30 - 5 = 25 元
      final lunch = bills.firstWhere((b) => b.comment == '午餐');
      expect(lunch.amount, 250000);
      expect(lunch.extra, contains('yimuRefundAmount'));

      // 转账单条 + Transfers 表
      final transfers = await db.select(db.transfers).get();
      expect(transfers.length, 1);
      expect(transfers.first.toAmount, 2980000);
      expect(transfers.first.fee, 20000);

      // 预算 month=0 → 2026-01
      final budgets = await db.select(db.budgets).get();
      expect(budgets.first.amount, 50000000);

      // 快照类型：第一条 manual（资产账户编辑），第二条 expense（新增账单 -30）
      final snapshots = await db.select(db.balanceSnapshots).get();
      expect(snapshots.length, 2);
      final sorted = [...snapshots]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      expect(sorted.first.type, SnapshotType.manual);
      expect(sorted.last.type, SnapshotType.expense);
      expect(sorted.last.balance, 9700000);

      // ---------- 幂等 ----------
      final before = await db.select(db.bills).get();
      final preview2 = await service.preview(
        source: ImportSource.yimu,
        bytes: _buildYimuDb(),
      );
      await service.write(preview2);
      final after = await db.select(db.bills).get();
      expect(after.length, before.length, reason: '重复导入不应产生新账单');

      // 重复导入后账户余额仍为一木权威值（initial==current 快照覆盖）。
      // 书中还有种子「支付宝」，因此按导入映射定位本次导入创建的账户。
      final mapping =
          await (db.select(db.importMappings)..where(
                (t) => Expression.and([
                  t.provider.equals('yimu'),
                  t.entityType.equals('account'),
                  t.sourceId.equals('11'),
                ]),
              ))
              .getSingle();
      final alipay2 = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals(mapping.targetId))).getSingle();
      expect(alipay2.currentBalance, 10000000);
      expect(alipay2.initialBalance, 10000000, reason: '无本地流水时反推值等于权威值');
    });

    test('一木同名合并：existing 更旧被并入导入账户（导入账户为保留方，反推初始）', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      await db.delete(db.accounts).go();
      // 现有账户：初始 100 元，本地支出 30 元 → 余额 70 元；updatedAt=1。
      // 一木库无 updatetime 列，导入账户 updatedAt=导入时刻 → 更晚，为保留方。
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'existing-alipay',
              name: '支付宝',
              category: 'fund',
              type: 'alipay',
              initialBalance: const Value(1000000),
              currentBalance: const Value(700000),
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      final cats = await db.select(db.categories).get();
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'b-local',
              type: 'expense',
              categoryId: cats.first.id,
              amount: 300000,
              accountId: const Value('existing-alipay'),
              time: 1700000100000,
              createdAt: 1700000100000,
              updatedAt: 1700000100000,
            ),
          );

      final service = ImportService(db);
      final preview = await service.preview(
        source: ImportSource.yimu,
        bytes: _buildYimuDb(),
      );
      final candidate = preview.mergeCandidates.firstWhere(
        (c) => c.name == '支付宝',
      );
      await service.write(
        preview,
        mergeMap: {candidate.sourceId: candidate.targetId},
      );

      // existing-alipay（更旧）被删除；保留方为导入的「支付宝」（assetnumber=1000 元）
      final remaining = await db.select(db.accounts).get();
      expect(remaining.where((a) => a.id == 'existing-alipay'), isEmpty);
      final mapping =
          await (db.select(db.importMappings)..where(
                (t) => Expression.and([
                  t.provider.equals('yimu'),
                  t.entityType.equals('account'),
                  t.sourceId.equals('11'),
                ]),
              ))
              .getSingle();
      final merged = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals(mapping.targetId))).getSingle();
      expect(merged.name, '支付宝');
      expect(merged.currentBalance, 10000000);
      // 本地支出 -30 元已重定向到保留方 → 反推初始 = 1000 - (-30) = 1030 元
      expect(merged.initialBalance, 10300000);
      final local = await (db.select(
        db.bills,
      )..where((t) => t.id.equals('b-local'))).getSingle();
      expect(local.accountId, merged.id, reason: '被合并账户的本地流水应重定向到保留方');

      // 全量重算后余额不变（一木导入账单 skipInRecalculate，本地账单参与）
      await BillService(db).recalculateAllBalances();
      final after = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals(merged.id))).getSingle();
      expect(after.currentBalance, 10000000, reason: '重算不应破坏权威余额');
    });

    test('一木同名合并：existing 空账户并入导入账户，直接继承权威余额', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      await db.delete(db.accounts).go();
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'existing-alipay',
              name: '支付宝',
              category: 'fund',
              type: 'alipay',
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      final service = ImportService(db);
      final preview = await service.preview(
        source: ImportSource.yimu,
        bytes: _buildYimuDb(),
      );
      final candidate = preview.mergeCandidates.firstWhere(
        (c) => c.name == '支付宝',
      );
      await service.write(
        preview,
        mergeMap: {candidate.sourceId: candidate.targetId},
      );
      // existing-alipay（空账户，更旧）被删除；保留方为导入账户（1000 元）
      final remaining = await db.select(db.accounts).get();
      expect(remaining.where((a) => a.id == 'existing-alipay'), isEmpty);
      final mapping =
          await (db.select(db.importMappings)..where(
                (t) => Expression.and([
                  t.provider.equals('yimu'),
                  t.entityType.equals('account'),
                  t.sourceId.equals('11'),
                ]),
              ))
              .getSingle();
      final merged = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals(mapping.targetId))).getSingle();
      expect(merged.currentBalance, 10000000);
      expect(merged.initialBalance, 10000000, reason: '无本地流水时反推值等于权威值');
    });

    test('同名合并候选：账单时间范围重叠 → autoMerge=false，不重叠 → autoMerge=true', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      await db.delete(db.accounts).go();
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: 'existing-alipay',
              name: '支付宝',
              category: 'fund',
              type: 'alipay',
              createdAt: 1,
              updatedAt: 1,
            ),
          );
      final cats = await db.select(db.categories).get();
      // 现有账单 2023-11-14，与导入账单（2023-11-14 ~ 11-16）重叠 → 冲突
      await db
          .into(db.bills)
          .insert(
            BillsCompanion.insert(
              id: 'b-overlap',
              type: 'expense',
              categoryId: cats.first.id,
              amount: 10000,
              accountId: const Value('existing-alipay'),
              time: 1700000100000,
              createdAt: 1700000100000,
              updatedAt: 1700000100000,
            ),
          );
      final service = ImportService(db);
      final preview = await service.preview(
        source: ImportSource.yimu,
        bytes: _buildYimuDb(),
      );
      final cand = preview.mergeCandidates.firstWhere((c) => c.name == '支付宝');
      expect(cand.autoMerge, isFalse, reason: '账单时间范围重叠不可自动合并');
      expect(cand.conflictReason, isNotNull);
      expect(cand.sourceId, 'existing-alipay', reason: 'existing 更旧为被合并方');
      expect(cand.targetId, isNot('existing-alipay'), reason: '导入账户为保留方');

      // 删除现有账单 → 时间范围不重叠 → 可自动合并
      await db.delete(db.bills).go();
      final preview2 = await service.preview(
        source: ImportSource.yimu,
        bytes: _buildYimuDb(),
      );
      final cand2 = preview2.mergeCandidates.firstWhere((c) => c.name == '支付宝');
      expect(cand2.autoMerge, isTrue);
    });
  });

  group('昼虎导入', () {
    test('账户/分类/账单/预算/快照 + 快照累加逻辑', () async {
      final mgr = DatabaseManager.inMemory();
      await mgr.createBook(name: '测试账本');
      final db = mgr.current;
      // 清空种子账户，避免同名冲突
      await db.delete(db.accounts).go();
      final service = ImportService(db);

      final preview = await service.preview(
        source: ImportSource.zhouhu,
        bytes: _buildZhouhuDb(),
        fileName: 'zhouhu.db',
      );

      expect(preview.mapped.accounts.length, 2);
      expect(
        preview.mapped.categories.length,
        0,
        reason: 'basedata.* 挂靠一木体系种子分类，不再新建',
      );
      expect(preview.mapped.bills.length, 3, reason: '转账为单条');
      expect(preview.mapped.snapshots.length, 2, reason: '同一天只保留最后一条快照');

      final result = await service.write(preview);
      expect(result.created, greaterThan(0));

      // 转账单条模型
      final transfer = await (db.select(
        db.bills,
      )..where((t) => t.type.equals('transfer'))).getSingle();
      expect(transfer.incomeAccountId, isNotNull);

      // 账户余额以第三方权威值
      final acc1 = await (db.select(
        db.accounts,
      )..where((t) => t.name.equals('支付宝'))).getSingle();
      expect(acc1.currentBalance, 10000000);

      // 预算：budgets 表有记录时不再生成 monthBudget 兜底
      final budgets = await db.select(db.budgets).get();
      expect(budgets.length, 1);
      expect(budgets.first.amount, 30000000);

      // ---------- 幂等 ----------
      final before = await db.select(db.bills).get();
      final preview2 = await service.preview(
        source: ImportSource.zhouhu,
        bytes: _buildZhouhuDb(),
      );
      await service.write(preview2);
      final after = await db.select(db.bills).get();
      expect(after.length, before.length);
    });
  });
}
