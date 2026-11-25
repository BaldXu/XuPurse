/// 清单内自动分类：按「账单备注 + 记账分类名」做本地关键词匹配。
///
/// 纯启发式、不联网、可解释；未命中返回 null（归入「未分类」），
/// 由用户手动调整。规则按优先级从上到下匹配。
class BillListItemClassifier {
  const BillListItemClassifier._();

  /// 分类名 → 关键词（命中任一即归类）。
  static const Map<String, List<String>> rules = {
    '前期准备': [
      '行李箱',
      '行李',
      '装备',
      '门票',
      '保险',
      '签证',
      '预订',
      '提前',
      '攻略',
      '泳衣',
      '防晒',
      '充电宝',
      '护照',
      '预订',
    ],
    '交通': [
      '机票',
      '动车',
      '高铁',
      '火车',
      '飞机',
      '航班',
      '打车',
      '滴滴',
      '出租',
      '地铁',
      '公交',
      '加油',
      '停车',
      '过路费',
      '高速',
      '机场',
      '大巴',
      '船票',
      '租车',
      '交通',
    ],
    '住宿': [
      '酒店',
      '民宿',
      '宾馆',
      '住宿',
      '青旅',
      '客栈',
      '房费',
      '客房',
    ],
    '餐饮': [
      '餐',
      '饭',
      '美食',
      '咖啡',
      '奶茶',
      '外卖',
      '火锅',
      '烧烤',
      '小吃',
      '早点',
      '早餐',
      '午餐',
      '晚餐',
      '零食',
      '饮料',
    ],
    '购物': [
      '购物',
      '超市',
      '商场',
      '淘宝',
      '京东',
      '拼多多',
      '免税',
      '纪念品',
      '特产',
      '便利店',
    ],
  };

  /// 返回匹配到的分类名；未命中返回 null。
  static String? classify({required String categoryName, String? comment}) {
    final text = '$categoryName ${comment ?? ''}'.replaceAll(' ', '');
    if (text.isEmpty) return null;
    for (final entry in rules.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) return entry.key;
      }
    }
    return null;
  }
}
