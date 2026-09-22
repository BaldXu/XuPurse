/// 默认账户种子（新账本初始化时写入；用户可在账户页修改/删除）。
library;

class SeedAccount {
  const SeedAccount({
    required this.name,
    required this.category,
    required this.type,
    required this.icon,
    required this.color,
    this.initialBalance = 0,
  });

  final String name;
  final String category; // fund | record | debt
  final String type; // alipay | wechat | cash | bank | credit | ...
  final String icon;
  final String color;
  final int initialBalance; // 万分之元
}

const List<SeedAccount> defaultAccounts = [
  SeedAccount(
    name: '支付宝',
    category: 'fund',
    type: 'alipay',
    icon: 'account_balance_wallet',
    color: '#1677ff',
    initialBalance: 0,
  ),
  SeedAccount(
    name: '微信支付',
    category: 'fund',
    type: 'wechat',
    icon: 'chat',
    color: '#07c160',
    initialBalance: 0,
  ),
  SeedAccount(
    name: '现金',
    category: 'fund',
    type: 'cash',
    icon: 'payments',
    color: '#f59e0b',
    initialBalance: 0,
  ),
  SeedAccount(
    name: '银行卡',
    category: 'fund',
    type: 'bank',
    icon: 'account_balance',
    color: '#3b82f6',
    initialBalance: 0,
  ),
];
