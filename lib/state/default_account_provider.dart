import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 默认账户偏好：记账弹窗打开时自动带出的支出 / 收入账户。
///
/// 值为账户 id；null = 未设置，由记账弹窗在可用账户里自动兜底一个。
/// 账户是否仍属于当前账本由消费端校验（账本切换后旧 id 会被忽略）。
class DefaultAccountPrefs {
  const DefaultAccountPrefs({this.expenseAccountId, this.incomeAccountId});

  final String? expenseAccountId;
  final String? incomeAccountId;

  @override
  bool operator ==(Object other) =>
      other is DefaultAccountPrefs &&
      other.expenseAccountId == expenseAccountId &&
      other.incomeAccountId == incomeAccountId;

  @override
  int get hashCode => Object.hash(expenseAccountId, incomeAccountId);
}

/// 全局默认账户设置（偏好，跨账本持久化到 SharedPreferences）。
final defaultAccountProvider =
    NotifierProvider<DefaultAccountNotifier, DefaultAccountPrefs>(
      DefaultAccountNotifier.new,
    );

class DefaultAccountNotifier extends Notifier<DefaultAccountPrefs> {
  static const _keyExpense = 'default_expense_account_id';
  static const _keyIncome = 'default_income_account_id';

  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 需要同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  @override
  DefaultAccountPrefs build() => DefaultAccountPrefs(
    expenseAccountId: _prefsCache?.getString(_keyExpense),
    incomeAccountId: _prefsCache?.getString(_keyIncome),
  );

  /// 设置默认支出账户；null 表示恢复「自动」。
  Future<void> setExpense(String? id) async {
    if (state.expenseAccountId == id) return;
    state = DefaultAccountPrefs(
      expenseAccountId: id,
      incomeAccountId: state.incomeAccountId,
    );
    await _write(_keyExpense, id);
  }

  /// 设置默认收入账户；null 表示恢复「自动」。
  Future<void> setIncome(String? id) async {
    if (state.incomeAccountId == id) return;
    state = DefaultAccountPrefs(
      expenseAccountId: state.expenseAccountId,
      incomeAccountId: id,
    );
    await _write(_keyIncome, id);
  }

  Future<void> _write(String key, String? id) async {
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    if (id == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, id);
    }
  }
}
