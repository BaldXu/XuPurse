import '../../core/constants/enums.dart';

/// 默认分类种子数据（继承自 cent-xyx 用户实际使用的分类结构）。
///
/// [key] 为固定业务键（幂等：账本初始化时若已存在同 key 分类则跳过）。
/// [icon] 为 Material Icons 语义名，UI 层通过 iconRegistry 解析为 IconData。

class SeedCategory {
  const SeedCategory({
    required this.key,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.parentKey,
    this.defaultSelect = false,
    this.sort = 0,
  });

  final String key;
  final String name;
  final BillType type;
  final String? parentKey;
  final String icon;
  final String color;
  final bool defaultSelect;
  final int sort;
}

const _shopping = '#fac858';
const _other = '#4d3c77';
const _food = '#5470c6';
const _transport = '#91cc75';
const _entertainment = '#73c0de';
const _housing = '#ee6666';
const _education = '#9a60b4';
const _relationship = '#ea7ccc';
const _medical = '#3ba272';
const _beauty = '#f472b6';
const _adjust = '#f59e0b';
const _transfer = '#2563eb';

/// 支出分类
const List<SeedCategory> seedExpenseCategories = [
  // 购物消费
  SeedCategory(key: 'shopping', name: '购物消费', type: BillType.expense, icon: 'shopping_cart', color: _shopping, sort: 100),
  SeedCategory(key: 'clothing', name: '服装', type: BillType.expense, icon: 'checkroom', color: _shopping, parentKey: 'shopping', sort: 1),
  SeedCategory(key: 'household', name: '日常家居', type: BillType.expense, icon: 'home', color: _shopping, parentKey: 'shopping', sort: 2),
  SeedCategory(key: 'beauty-care', name: '个护美妆', type: BillType.expense, icon: 'face_retouching_natural', color: _shopping, parentKey: 'shopping', sort: 3),
  SeedCategory(key: 'electronics', name: '手机数码', type: BillType.expense, icon: 'smartphone', color: _shopping, parentKey: 'shopping', sort: 4),
  SeedCategory(key: 'virtual-topup', name: '虚拟充值', type: BillType.expense, icon: 'credit_card', color: _shopping, parentKey: 'shopping', sort: 5),
  SeedCategory(key: 'appliances', name: '生活电器', type: BillType.expense, icon: 'blender', color: _shopping, parentKey: 'shopping', sort: 6),
  SeedCategory(key: 'accessories', name: '配饰腕表', type: BillType.expense, icon: 'watch', color: _shopping, parentKey: 'shopping', sort: 7),
  SeedCategory(key: 'baby-toys', name: '母婴玩具', type: BillType.expense, icon: 'child_care', color: _shopping, parentKey: 'shopping', sort: 8),
  SeedCategory(key: 'sports-wear', name: '服饰运动', type: BillType.expense, icon: 'directions_run', color: _shopping, parentKey: 'shopping', sort: 9),
  SeedCategory(key: 'pet-supplies', name: '宠物用品', type: BillType.expense, icon: 'pets', color: _shopping, parentKey: 'shopping', sort: 10),
  SeedCategory(key: 'office-supplies', name: '办公用品', type: BillType.expense, icon: 'work', color: _shopping, parentKey: 'shopping', sort: 11),
  SeedCategory(key: 'renovation', name: '装修装饰', type: BillType.expense, icon: 'construction', color: _shopping, parentKey: 'shopping', sort: 12),

  // 其他
  SeedCategory(key: 'other-expenses', name: '其他', type: BillType.expense, icon: 'bookmark', color: _other, sort: 900),
  SeedCategory(key: 'fengchao-rent', name: '丰巢长租', type: BillType.expense, icon: 'inventory_2', color: _other, parentKey: 'other-expenses', sort: 1),
  SeedCategory(key: 'government', name: '政府办理', type: BillType.expense, icon: 'account_balance', color: _other, parentKey: 'other-expenses', sort: 2),
  SeedCategory(key: 'fines-compensation', name: '罚款赔偿', type: BillType.expense, icon: 'error_outline', color: _other, parentKey: 'other-expenses', sort: 3),
  SeedCategory(key: 'investment-expense', name: '理财支出', type: BillType.expense, icon: 'query_stats', color: _other, parentKey: 'other-expenses', sort: 4),
  SeedCategory(key: 'charity', name: '慈善捐助', type: BillType.expense, icon: 'volunteer_activism', color: _other, parentKey: 'other-expenses', sort: 5),

  // 食品餐饮
  SeedCategory(key: 'food', name: '食品餐饮', type: BillType.expense, icon: 'restaurant', color: _food, sort: 200, defaultSelect: true),
  SeedCategory(key: 'luckin', name: '瑞幸', type: BillType.expense, icon: 'local_cafe', color: _food, parentKey: 'food', sort: 1),
  SeedCategory(key: 'group-dining', name: '聚餐', type: BillType.expense, icon: 'dinner_dining', color: _food, parentKey: 'food', sort: 2),
  SeedCategory(key: 'breakfast', name: '早餐', type: BillType.expense, icon: 'bakery_dining', color: _food, parentKey: 'food', sort: 3),
  SeedCategory(key: 'lunch', name: '午餐', type: BillType.expense, icon: 'lunch_dining', color: _food, parentKey: 'food', sort: 4),
  SeedCategory(key: 'dinner', name: '晚餐', type: BillType.expense, icon: 'ramen_dining', color: _food, parentKey: 'food', sort: 5),
  SeedCategory(key: 'drinks', name: '饮料酒水', type: BillType.expense, icon: 'local_bar', color: _food, parentKey: 'food', sort: 6),
  SeedCategory(key: 'snack', name: '休闲零食', type: BillType.expense, icon: 'cookie', color: _food, parentKey: 'food', sort: 7),
  SeedCategory(key: 'fresh-food', name: '生鲜食品', type: BillType.expense, icon: 'set_meal', color: _food, parentKey: 'food', sort: 8),
  SeedCategory(key: 'treat-guests', name: '请客吃饭', type: BillType.expense, icon: 'table_restaurant', color: _food, parentKey: 'food', sort: 9),
  SeedCategory(key: 'grain-oil', name: '粮油调味', type: BillType.expense, icon: 'grass', color: _food, parentKey: 'food', sort: 10),

  // 出行交通
  SeedCategory(key: 'transport', name: '出行交通', type: BillType.expense, icon: 'commute', color: _transport, sort: 300),
  SeedCategory(key: 'bike-share', name: '共享单车', type: BillType.expense, icon: 'pedal_bike', color: _transport, parentKey: 'transport', sort: 1),
  SeedCategory(key: 'taxi', name: '打车', type: BillType.expense, icon: 'local_taxi', color: _transport, parentKey: 'transport', sort: 2),
  SeedCategory(key: 'public-transport', name: '公共交通', type: BillType.expense, icon: 'directions_bus', color: _transport, parentKey: 'transport', sort: 3),
  SeedCategory(key: 'parking', name: '停车费', type: BillType.expense, icon: 'local_parking', color: _transport, parentKey: 'transport', sort: 4),
  SeedCategory(key: 'gas-up', name: '加油', type: BillType.expense, icon: 'local_gas_station', color: _transport, parentKey: 'transport', sort: 5),
  SeedCategory(key: 'train', name: '火车', type: BillType.expense, icon: 'train', color: _transport, parentKey: 'transport', sort: 6),
  SeedCategory(key: 'airplane', name: '飞机', type: BillType.expense, icon: 'flight', color: _transport, parentKey: 'transport', sort: 7),
  SeedCategory(key: 'car-maintenance', name: '保养修车', type: BillType.expense, icon: 'build', color: _transport, parentKey: 'transport', sort: 8),

  // 休闲娱乐
  SeedCategory(key: 'entertainment', name: '休闲娱乐', type: BillType.expense, icon: 'sports_esports', color: _entertainment, sort: 400),
  SeedCategory(key: 'dining-out', name: '食饭', type: BillType.expense, icon: 'flatware', color: _entertainment, parentKey: 'entertainment', sort: 1),
  SeedCategory(key: 'entertainment-other', name: '其他', type: BillType.expense, icon: 'bookmark', color: _entertainment, parentKey: 'entertainment', sort: 2),
  SeedCategory(key: 'currency-exchange', name: '兑汇', type: BillType.expense, icon: 'swap_horiz', color: _entertainment, parentKey: 'entertainment', sort: 3),
  SeedCategory(key: 'steam', name: 'steam', type: BillType.expense, icon: 'sports_esports', color: _entertainment, parentKey: 'entertainment', sort: 4),
  SeedCategory(key: 'vpn', name: 'vpn', type: BillType.expense, icon: 'vpn_key', color: _entertainment, parentKey: 'entertainment', sort: 5),
  SeedCategory(key: 'mobile-games', name: '手游', type: BillType.expense, icon: 'smart_toy', color: _entertainment, parentKey: 'entertainment', sort: 6),
  SeedCategory(key: 'travel', name: '旅游度假', type: BillType.expense, icon: 'travel_luggage_and_bags', color: _entertainment, parentKey: 'entertainment', sort: 7),
  SeedCategory(key: 'movies-singing', name: '电影唱歌', type: BillType.expense, icon: 'mic', color: _entertainment, parentKey: 'entertainment', sort: 8),
  SeedCategory(key: 'fitness', name: '运动健身', type: BillType.expense, icon: 'fitness_center', color: _entertainment, parentKey: 'entertainment', sort: 9),
  SeedCategory(key: 'spa-massage', name: '足浴按摩', color: _entertainment, icon: 'spa', type: BillType.expense, parentKey: 'entertainment', sort: 10),
  SeedCategory(key: 'board-games', name: '棋牌桌游', type: BillType.expense, icon: 'casino', color: _entertainment, parentKey: 'entertainment', sort: 11),
  SeedCategory(key: 'bar', name: '酒吧', type: BillType.expense, icon: 'local_drink', color: _entertainment, parentKey: 'entertainment', sort: 12),
  SeedCategory(key: 'performance', name: '演出', type: BillType.expense, icon: 'theater_comedy', color: _entertainment, parentKey: 'entertainment', sort: 13),

  // 居家生活
  SeedCategory(key: 'housing', name: '居家生活', type: BillType.expense, icon: 'cottage', color: _housing, sort: 500),
  SeedCategory(key: 'daily-necessities', name: '日用', type: BillType.expense, icon: 'inventory', color: _housing, parentKey: 'housing', sort: 1),
  SeedCategory(key: 'mall', name: '商城', type: BillType.expense, icon: 'store', color: _housing, parentKey: 'housing', sort: 2),
  SeedCategory(key: 'home-renovation', name: '装修', type: BillType.expense, icon: 'format_paint', color: _housing, parentKey: 'housing', sort: 3),
  SeedCategory(key: 'phone-broadband', name: '话费宽带', type: BillType.expense, icon: 'phone_iphone', color: _housing, parentKey: 'housing', sort: 4),
  SeedCategory(key: 'electricity', name: '电费', type: BillType.expense, icon: 'bolt', color: _housing, parentKey: 'housing', sort: 5),
  SeedCategory(key: 'water', name: '水费', type: BillType.expense, icon: 'water_drop', color: _housing, parentKey: 'housing', sort: 6),
  SeedCategory(key: 'gas', name: '燃气费', type: BillType.expense, icon: 'local_fire_department', color: _housing, parentKey: 'housing', sort: 7),
  SeedCategory(key: 'mgmt-fee', name: '物业费', type: BillType.expense, icon: 'apartment', color: _housing, parentKey: 'housing', sort: 8),
  SeedCategory(key: 'rent-mortgage', name: '房租还贷', type: BillType.expense, icon: 'house_siding', color: _housing, parentKey: 'housing', sort: 9),
  SeedCategory(key: 'parking-fee', name: '车位费', type: BillType.expense, icon: 'garage', color: _housing, parentKey: 'housing', sort: 10),
  SeedCategory(key: 'housekeeping', name: '家政清洁', type: BillType.expense, icon: 'cleaning_services', color: _housing, parentKey: 'housing', sort: 11),

  // 文化教育
  SeedCategory(key: 'education', name: '文化教育', type: BillType.expense, icon: 'school', color: _education, sort: 600),
  SeedCategory(key: 'tuition', name: '学费', type: BillType.expense, icon: 'history_edu', color: _education, parentKey: 'education', sort: 1),
  SeedCategory(key: 'books-magazines', name: '书报杂志', type: BillType.expense, icon: 'menu_book', color: _education, parentKey: 'education', sort: 2),
  SeedCategory(key: 'training-exam', name: '培训考试', type: BillType.expense, icon: 'checklist', color: _education, parentKey: 'education', sort: 3),

  // 送礼人情
  SeedCategory(key: 'relationship', name: '送礼人情', type: BillType.expense, icon: 'celebration', color: _relationship, sort: 700),
  SeedCategory(key: 'family', name: '孝敬长辈', type: BillType.expense, icon: 'elderly', color: _relationship, parentKey: 'relationship', sort: 1),
  SeedCategory(key: 'gifts', name: '礼物', type: BillType.expense, icon: 'redeem', color: _relationship, parentKey: 'relationship', sort: 2),
  SeedCategory(key: 'loan-out', name: '借出', type: BillType.expense, icon: 'front_hand', color: _relationship, parentKey: 'relationship', sort: 3),
  SeedCategory(key: 'hongbao', name: '红包', type: BillType.expense, icon: 'card_giftcard', color: _relationship, parentKey: 'relationship', sort: 4),
  SeedCategory(key: 'tips', name: '打赏', type: BillType.expense, icon: 'monetization_on', color: _relationship, parentKey: 'relationship', sort: 5),

  // 健康医疗
  SeedCategory(key: 'medical', name: '健康医疗', type: BillType.expense, icon: 'local_hospital', color: _medical, sort: 800),
  SeedCategory(key: 'nursing', name: '护理', type: BillType.expense, icon: 'monitor_heart', color: _medical, parentKey: 'medical', sort: 1),
  SeedCategory(key: 'supplements', name: '滋补保健', type: BillType.expense, icon: 'medication', color: _medical, parentKey: 'medical', sort: 2),
  SeedCategory(key: 'hospital', name: '医院', type: BillType.expense, icon: 'local_hospital', color: _medical, parentKey: 'medical', sort: 3),
  SeedCategory(key: 'pharmacy', name: '买药', type: BillType.expense, icon: 'local_pharmacy', color: _medical, parentKey: 'medical', sort: 4),

  // 理发美容
  SeedCategory(key: 'beauty', name: '理发美容', type: BillType.expense, icon: 'content_cut', color: _beauty, sort: 850),

  // 调账专用（支出方向）
  SeedCategory(
    key: 'balance_adjustment_expense',
    name: '余额调整',
    type: BillType.expense,
    icon: 'balance',
    color: _adjust,
    parentKey: 'other-expenses',
    sort: 99,
  ),
];

/// 收入分类
const List<SeedCategory> seedIncomeCategories = [
  SeedCategory(key: 'wage', name: '工资', type: BillType.income, icon: 'payments', color: _food, sort: 100),
  SeedCategory(key: 'part-time', name: '兼职', type: BillType.income, icon: 'work_history', color: _transport, parentKey: 'wage', sort: 1),
  SeedCategory(key: 'other-income', name: '其他收入', type: BillType.income, icon: 'bookmark', color: _education, sort: 900),
  SeedCategory(key: 'hongbao-income', name: '红包收入', type: BillType.income, icon: 'redeem', color: _relationship, parentKey: 'other-income', sort: 1),
  SeedCategory(key: 'refund', name: '退款', type: BillType.income, icon: 'assignment_return', color: _housing, parentKey: 'other-income', sort: 2),
  SeedCategory(
    key: 'balance_adjustment_income',
    name: '余额调整',
    type: BillType.income,
    icon: 'balance',
    color: _adjust,
    parentKey: 'other-income',
    sort: 99,
  ),
];

/// 转账分类
const List<SeedCategory> seedTransferCategories = [
  SeedCategory(key: 'transfer', name: '转账', type: BillType.transfer, icon: 'swap_horiz', color: _transfer, sort: 100),
  SeedCategory(key: 'transfer_out', name: '转出', type: BillType.transfer, icon: 'north_east', color: _transfer, parentKey: 'transfer', sort: 1),
  SeedCategory(key: 'transfer_in', name: '转入', type: BillType.transfer, icon: 'south_west', color: _transfer, parentKey: 'transfer', sort: 2),
];

/// 全部种子分类
const List<SeedCategory> allSeedCategories = [
  ...seedExpenseCategories,
  ...seedIncomeCategories,
  ...seedTransferCategories,
];

/// 调账专用分类 key
abstract final class AdjustmentCategoryKeys {
  static const income = 'balance_adjustment_income';
  static const expense = 'balance_adjustment_expense';
}
