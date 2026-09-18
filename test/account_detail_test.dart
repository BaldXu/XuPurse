import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/data/database/app_database.dart';
import 'package:xupurse/domain/services/account_service.dart';
import 'package:xupurse/state/providers.dart';
import 'package:xupurse/ui/pages/account_detail_page.dart';

/// 只记录调用、不落库的假 AccountService（widget 测试不依赖真实数据库，
/// 避免 drift 异步与 flutter_test fake-async 的相互干扰）。
class _FakeAccountService extends AccountService {
  _FakeAccountService(super.db);

  String? capturedAccountId;
  int? capturedBalance;
  int? capturedTimestamp;
  String? capturedNote;

  @override
  Future<void> addHistoricalSnapshot({
    required String accountId,
    required int balance,
    required int timestamp,
    String? note,
  }) async {
    capturedAccountId = accountId;
    capturedBalance = balance;
    capturedTimestamp = timestamp;
    capturedNote = note;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('账户详情页：手动添加历史快照（时间点 + 余额，不改当前余额）', (tester) async {
    final account = Account(
      id: 'acc-x',
      name: '支付宝',
      category: 'fund',
      type: 'alipay',
      initialBalance: 0,
      currentBalance: 0,
      currency: 'CNY',
      includeInAssets: true,
      enabled: true,
      createdAt: 1,
      updatedAt: 1,
    );
    final fake = _FakeAccountService(AppDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsProvider.overrideWith((ref) => Stream.value([account])),
          snapshotsProvider.overrideWith(
            (ref) => Stream.value(const <BalanceSnapshot>[]),
          ),
          accountServiceProvider.overrideWithValue(fake),
        ],
        child: MaterialApp(home: AccountDetailPage(account: account)),
      ),
    );
    await tester.pumpAndSettle();

    // 空快照提示
    expect(find.text('暂无快照'), findsOneWidget);

    // 打开添加历史快照弹窗（默认时间为现在）
    await tester.tap(find.text('添加历史快照'));
    await tester.pumpAndSettle();
    expect(find.text('添加历史快照 · 支付宝'), findsOneWidget);

    // 输入余额 100 元并保存
    await tester.enterText(find.byType(TextField).first, '100');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    // 假 Service 收到正确参数（100 元 = 1000000 万分之元）
    expect(fake.capturedAccountId, 'acc-x');
    expect(fake.capturedBalance, 1000000);
    expect(fake.capturedTimestamp, isNotNull);
    expect(fake.capturedNote, isNull);
  });
}
