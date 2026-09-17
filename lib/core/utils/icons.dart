import 'package:flutter/material.dart';

/// Material Icons 语义名 → IconData 注册表。
///
/// 种子数据（分类/账户）与导入映射中的 icon 字段存的是语义名，
/// UI 层统一通过 [iconRegistry] 解析；未知名回退为书签图标。
const Map<String, IconData> iconRegistry = {
  // 账户
  'account_balance_wallet': Icons.account_balance_wallet,
  'account_balance': Icons.account_balance,
  'payments': Icons.payments,
  'chat': Icons.chat,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings,

  // 购物 / 生活
  'shopping_cart': Icons.shopping_cart,
  'checkroom': Icons.checkroom,
  'home': Icons.home,
  'face_retouching_natural': Icons.face_retouching_natural,
  'smartphone': Icons.smartphone,
  'blender': Icons.blender,
  'watch': Icons.watch,
  'child_care': Icons.child_care,
  'directions_run': Icons.directions_run,
  'pets': Icons.pets,
  'work': Icons.work,
  'construction': Icons.construction,
  'bookmark': Icons.bookmark,
  'inventory_2': Icons.inventory_2,
  'error_outline': Icons.error_outline,
  'query_stats': Icons.query_stats,
  'volunteer_activism': Icons.volunteer_activism,

  // 餐饮
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'dinner_dining': Icons.dinner_dining,
  'bakery_dining': Icons.bakery_dining,
  'lunch_dining': Icons.lunch_dining,
  'ramen_dining': Icons.ramen_dining,
  'local_bar': Icons.local_bar,
  'cookie': Icons.cookie,
  'set_meal': Icons.set_meal,
  'table_restaurant': Icons.table_restaurant,
  'grass': Icons.grass,

  // 交通
  'commute': Icons.commute,
  'pedal_bike': Icons.pedal_bike,
  'local_taxi': Icons.local_taxi,
  'directions_bus': Icons.directions_bus,
  'local_parking': Icons.local_parking,
  'local_gas_station': Icons.local_gas_station,
  'train': Icons.train,
  'flight': Icons.flight,
  'build': Icons.build,

  // 娱乐
  'sports_esports': Icons.sports_esports,
  'flatware': Icons.flatware,
  'swap_horiz': Icons.swap_horiz,
  'smart_toy': Icons.smart_toy,
  'vpn_key': Icons.vpn_key,
  'travel_luggage_and_bags': Icons.luggage,
  'mic': Icons.mic,
  'fitness_center': Icons.fitness_center,
  'spa': Icons.spa,
  'casino': Icons.casino,
  'local_drink': Icons.local_drink,
  'theater_comedy': Icons.theater_comedy,

  // 居家
  'cottage': Icons.cottage,
  'inventory': Icons.inventory,
  'store': Icons.store,
  'format_paint': Icons.format_paint,
  'phone_iphone': Icons.phone_iphone,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'local_fire_department': Icons.local_fire_department,
  'apartment': Icons.apartment,
  'house_siding': Icons.house_siding,
  'garage': Icons.garage,
  'cleaning_services': Icons.cleaning_services,

  // 教育 / 人情
  'school': Icons.school,
  'history_edu': Icons.history_edu,
  'menu_book': Icons.menu_book,
  'checklist': Icons.checklist,
  'celebration': Icons.celebration,
  'elderly': Icons.elderly,
  'redeem': Icons.redeem,
  'front_hand': Icons.front_hand,
  'card_giftcard': Icons.card_giftcard,
  'monetization_on': Icons.monetization_on,

  // 医疗 / 健身
  'local_hospital': Icons.local_hospital,
  'local_pharmacy': Icons.local_pharmacy,
  'medication': Icons.medication,
  'monitor_heart': Icons.monitor_heart,
  'content_cut': Icons.content_cut,

  // 收入 / 转账
  'north_east': Icons.north_east,
  'south_west': Icons.south_west,
  'balance': Icons.balance,
  'assignment_return': Icons.assignment_return,
  'work_history': Icons.work_history,
};

/// 解析语义名为图标；未知名称回退书签图标。
IconData resolveIcon(String? name) =>
    iconRegistry[name] ?? Icons.bookmark_outline;
