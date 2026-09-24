import 'package:colorful_iconify_flutter/icons/twemoji.dart' as tw;
import 'package:flutter/material.dart';

/// 语义名 → Twitter Emoji（twemoji）SVG 映射。
///
/// 语义名与 [iconRegistry]（Material Icons）逐一对齐，并额外覆盖
/// 种子分类里使用但 Material 注册表缺失的少数名称（如 verified_user 等），
/// 以及界面级语义图标（底部导航 / 设置入口 / 统计分区等）。
/// 未覆盖的名称在 twemoji 图标包下回退到简约图标渲染。
const Map<String, String> twemojiIconRegistry = {
  // ---- 账户 ----
  'account_balance_wallet': tw.Twemoji.purse,
  'account_balance': tw.Twemoji.bank,
  'payments': tw.Twemoji.money_with_wings,
  'chat': tw.Twemoji.speech_balloon,
  'credit_card': tw.Twemoji.credit_card,
  'savings': tw.Twemoji.pig,

  // ---- 购物 / 生活 ----
  'shopping_cart': tw.Twemoji.shopping_cart,
  'checkroom': tw.Twemoji.t_shirt,
  'home': tw.Twemoji.house,
  'face_retouching_natural': tw.Twemoji.lipstick,
  'smartphone': tw.Twemoji.mobile_phone,
  'blender': tw.Twemoji.cup_with_straw,
  'watch': tw.Twemoji.watch,
  'child_care': tw.Twemoji.baby_bottle,
  'directions_run': tw.Twemoji.person_running,
  'pets': tw.Twemoji.paw_prints,
  'work': tw.Twemoji.briefcase,
  'construction': tw.Twemoji.construction,
  'bookmark': tw.Twemoji.bookmark,
  'inventory_2': tw.Twemoji.package,
  'error_outline': tw.Twemoji.warning,
  'query_stats': tw.Twemoji.chart_increasing,
  'volunteer_activism': tw.Twemoji.handshake,

  // ---- 餐饮 ----
  'restaurant': tw.Twemoji.fork_and_knife_with_plate,
  'local_cafe': tw.Twemoji.hot_beverage,
  'dinner_dining': tw.Twemoji.shallow_pan_of_food,
  'bakery_dining': tw.Twemoji.croissant,
  'lunch_dining': tw.Twemoji.hamburger,
  'ramen_dining': tw.Twemoji.steaming_bowl,
  'local_bar': tw.Twemoji.clinking_beer_mugs,
  'cookie': tw.Twemoji.cookie,
  'set_meal': tw.Twemoji.cut_of_meat,
  'table_restaurant': tw.Twemoji.pot_of_food,
  'grass': tw.Twemoji.herb,

  // ---- 交通 ----
  'commute': tw.Twemoji.automobile,
  'pedal_bike': tw.Twemoji.bicycle,
  'local_taxi': tw.Twemoji.taxi,
  'directions_bus': tw.Twemoji.bus,
  'local_parking': tw.Twemoji.p_button,
  'local_gas_station': tw.Twemoji.fuel_pump,
  'train': tw.Twemoji.train,
  'flight': tw.Twemoji.airplane,
  'build': tw.Twemoji.wrench,

  // ---- 娱乐 ----
  'sports_esports': tw.Twemoji.video_game,
  'flatware': tw.Twemoji.fork_and_knife,
  'swap_horiz': tw.Twemoji.left_right_arrow,
  'smart_toy': tw.Twemoji.robot,
  'vpn_key': tw.Twemoji.key,
  'travel_luggage_and_bags': tw.Twemoji.luggage,
  'mic': tw.Twemoji.microphone,
  'fitness_center': tw.Twemoji.person_lifting_weights,
  'spa': tw.Twemoji.person_getting_massage,
  'casino': tw.Twemoji.game_die,
  'local_drink': tw.Twemoji.wine_glass,
  'theater_comedy': tw.Twemoji.performing_arts,

  // ---- 居家 ----
  'cottage': tw.Twemoji.house_with_garden,
  'inventory': tw.Twemoji.package,
  'store': tw.Twemoji.convenience_store,
  'format_paint': tw.Twemoji.paintbrush,
  'phone_iphone': tw.Twemoji.mobile_phone,
  'bolt': tw.Twemoji.high_voltage,
  'water_drop': tw.Twemoji.droplet,
  'local_fire_department': tw.Twemoji.fire,
  'apartment': tw.Twemoji.office_building,
  'house_siding': tw.Twemoji.house,
  'garage': tw.Twemoji.p_button,
  'cleaning_services': tw.Twemoji.broom,

  // ---- 教育 / 人情 ----
  'school': tw.Twemoji.school,
  'history_edu': tw.Twemoji.scroll,
  'menu_book': tw.Twemoji.open_book,
  'checklist': tw.Twemoji.clipboard,
  'celebration': tw.Twemoji.party_popper,
  'elderly': tw.Twemoji.older_adult,
  'redeem': tw.Twemoji.wrapped_gift,
  'front_hand': tw.Twemoji.raised_hand,
  'card_giftcard': tw.Twemoji.wrapped_gift,
  'monetization_on': tw.Twemoji.money_bag,

  // ---- 医疗 / 健身 ----
  'local_hospital': tw.Twemoji.hospital,
  'local_pharmacy': tw.Twemoji.pill,
  'medication': tw.Twemoji.pill,
  'monitor_heart': tw.Twemoji.beating_heart,
  'content_cut': tw.Twemoji.scissors,

  // ---- 收入 / 转账 ----
  'north_east': tw.Twemoji.up_right_arrow,
  'south_west': tw.Twemoji.down_left_arrow,
  'balance': tw.Twemoji.balance_scale,
  'assignment_return': tw.Twemoji.right_arrow_curving_left,
  'work_history': tw.Twemoji.briefcase,

  // ---- 种子分类使用但 Material 注册表未收录的名称 ----
  'verified_user': tw.Twemoji.shield,
  'attach_money': tw.Twemoji.coin,
  'recycling': tw.Twemoji.label,
  'emoji_events': tw.Twemoji.trophy,
  'military_tech': tw.Twemoji.military_medal,
  'price_check': tw.Twemoji.dollar_banknote,
  'trending_up': tw.Twemoji.chart_increasing,

  // ---- 界面级语义图标（底部导航 / 设置入口 / 统计分区等） ----
  'receipt': tw.Twemoji.receipt,
  'bar_chart': tw.Twemoji.bar_chart,
  'person': tw.Twemoji.bust_in_silhouette,
  'open_file_folder': tw.Twemoji.open_file_folder,
  'artist_palette': tw.Twemoji.artist_palette,
  'gear': tw.Twemoji.gear,
  'information': tw.Twemoji.information,
  'triangular_ruler': tw.Twemoji.triangular_ruler,
  'label': tw.Twemoji.label,
  'currency_exchange': tw.Twemoji.dollar_banknote,
  'handshake': tw.Twemoji.handshake,
  'chart_increasing': tw.Twemoji.chart_increasing,
  'speech_balloon': tw.Twemoji.speech_balloon,
  'antenna_bars': tw.Twemoji.antenna_bars,
  'brain': tw.Twemoji.brain,
  'floppy_disk': tw.Twemoji.floppy_disk,
  'inbox_tray': tw.Twemoji.inbox_tray,
  'link': tw.Twemoji.link,
  'calendar': tw.Twemoji.calendar,
  'spiral_notepad': tw.Twemoji.spiral_notepad,
  'mag': tw.Twemoji.magnifying_glass_tilted_right,
  'eye': tw.Twemoji.eye,
  'crescent_moon': tw.Twemoji.crescent_moon,
  'sparkles': tw.Twemoji.sparkles,
  'grinning_face': tw.Twemoji.grinning_face,
};

/// Material Icons → 语义名映射（界面图标，值复用 [twemojiIconRegistry] 的键）。
///
/// 用于 [AppIcon] 以 [IconData] 入参时按图标包切换；未收录的图标
/// （纯操作符号如 chevron/close/check 等）保持 Material 渲染。
final Map<IconData, String> materialEmojiNames = {
  // 底部导航
  Icons.receipt_long: 'receipt',
  Icons.receipt_long_outlined: 'receipt',
  Icons.account_balance_wallet: 'account_balance_wallet',
  Icons.account_balance_wallet_outlined: 'account_balance_wallet',
  Icons.pie_chart: 'bar_chart',
  Icons.pie_chart_outline: 'bar_chart',
  Icons.person: 'person',
  Icons.person_outline: 'person',

  // 我的页入口
  Icons.account_balance: 'account_balance',
  Icons.account_balance_outlined: 'account_balance',
  Icons.folder_open: 'open_file_folder',
  Icons.folder_open_outlined: 'open_file_folder',
  Icons.palette_outlined: 'artist_palette',
  Icons.settings_outlined: 'gear',
  Icons.smart_toy: 'smart_toy',
  Icons.smart_toy_outlined: 'smart_toy',
  Icons.info_outline: 'information',

  // 设置页入口
  Icons.category_outlined: 'triangular_ruler',
  Icons.label: 'label',
  Icons.label_outline: 'label',
  Icons.label_rounded: 'label',
  Icons.savings: 'savings',
  Icons.savings_outlined: 'savings',
  Icons.handshake_outlined: 'handshake',
  Icons.currency_exchange: 'currency_exchange',

  // 图表 / 数据 / 备份
  Icons.bar_chart: 'bar_chart',
  Icons.bar_chart_outlined: 'bar_chart',
  Icons.show_chart: 'chart_increasing',
  Icons.network_check: 'antenna_bars',
  Icons.dataset_linked: 'link',
  Icons.dataset_linked_outlined: 'link',
  Icons.backup_outlined: 'floppy_disk',
  Icons.file_download_outlined: 'inbox_tray',

  // 报告汇总
  Icons.insights_outlined: 'chart_increasing',
  Icons.summarize_outlined: 'spiral_notepad',

  // 聊天 / AI / 表情
  Icons.chat: 'speech_balloon',
  Icons.chat_bubble: 'speech_balloon',
  Icons.chat_bubble_outline: 'speech_balloon',
  Icons.add_comment_outlined: 'speech_balloon',
  Icons.psychology: 'brain',
  Icons.psychology_outlined: 'brain',
  Icons.emoji_emotions_outlined: 'grinning_face',

  // 日期 / 历史
  Icons.calendar_month: 'calendar',
  Icons.calendar_month_outlined: 'calendar',
  Icons.date_range: 'calendar',
  Icons.date_range_outlined: 'calendar',
  Icons.today: 'calendar',
  Icons.event: 'calendar',
  Icons.history: 'spiral_notepad',

  // 搜索 / 显示 / 外观
  Icons.search: 'mag',
  Icons.visibility: 'eye',
  Icons.visibility_outlined: 'eye',
  Icons.visibility_off_outlined: 'eye',
  Icons.dark_mode_outlined: 'crescent_moon',
  Icons.auto_awesome: 'sparkles',
  Icons.manage_accounts_outlined: 'person',

  // 账本 / 业务记录 / 标签等管理页
  Icons.menu_book: 'menu_book',
  Icons.menu_book_outlined: 'menu_book',
  Icons.north_east: 'north_east',
  Icons.south_west: 'south_west',
  Icons.swap_horiz: 'swap_horiz',
  Icons.assignment_return: 'assignment_return',
  Icons.bookmark: 'bookmark',
  Icons.bookmark_outline: 'bookmark',
};
