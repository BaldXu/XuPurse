import 'package:flutter/material.dart';

/// 货币展示元信息配置：国旗/区旗 emoji + 专属颜色。
///
/// 资产页账户余额、汇率设置页等按币种着色时统一从这里取；
/// 新币种只需在 [currencies] 增一行（code → flag + color）。
/// 颜色一律选深色系（保证文字可读性），避免过浅。
class XpCurrencyMeta {
  const XpCurrencyMeta({required this.flag, required this.color});

  /// 国家/地区旗帜 emoji（如 🇨🇳 🇺🇸 🇭🇰）
  final String flag;

  /// 该货币专属色（余额文字/图标着色）
  final Color color;
}

/// 货币配置表：code → 国旗 + 颜色。
abstract final class XpCurrencyMetaConfig {
  static const Map<String, XpCurrencyMeta> currencies = {
    // 人民币：中国国旗 / 红
    'CNY': XpCurrencyMeta(flag: '🇨🇳', color: Color(0xFFE0322D)),
    // 美元：美国国旗 / 蓝
    'USD': XpCurrencyMeta(flag: '🇺🇸', color: Color(0xFF1F4FA3)),
    // 欧元：欧盟旗 / 深蓝
    'EUR': XpCurrencyMeta(flag: '🇪🇺', color: Color(0xFF1D3A8F)),
    // 日元：日本国旗 / 深红
    'JPY': XpCurrencyMeta(flag: '🇯🇵', color: Color(0xFFC72B2B)),
    // 港元：香港区旗 / 粉
    'HKD': XpCurrencyMeta(flag: '🇭🇰', color: Color(0xFFE26BA8)),
    // 英镑：英国国旗 / 深蓝
    'GBP': XpCurrencyMeta(flag: '🇬🇧', color: Color(0xFF1B3A6B)),
    // 韩元：韩国国旗 / 蓝
    'KRW': XpCurrencyMeta(flag: '🇰🇷', color: Color(0xFF2E5FA3)),
    // 新加坡元：新加坡国旗 / 红
    'SGD': XpCurrencyMeta(flag: '🇸🇬', color: Color(0xFFE0443A)),
    // 澳元：澳大利亚国旗 / 藏蓝
    'AUD': XpCurrencyMeta(flag: '🇦🇺', color: Color(0xFF1B3A6B)),
    // 加元：加拿大国旗 / 红
    'CAD': XpCurrencyMeta(flag: '🇨🇦', color: Color(0xFFD9443C)),
    // 泰铢：泰国国旗 / 深蓝
    'THB': XpCurrencyMeta(flag: '🇹🇭', color: Color(0xFF233B8F)),
    // 新台币：台湾地区旗帜 / 深蓝
    'TWD': XpCurrencyMeta(flag: '🇹🇼', color: Color(0xFF1F4FA3)),
    // 林吉特：马来西亚国旗 / 深蓝
    'MYR': XpCurrencyMeta(flag: '🇲🇾', color: Color(0xFF1F3A93)),
    // 印度卢比：印度国旗 / 深蓝
    'INR': XpCurrencyMeta(flag: '🇮🇳', color: Color(0xFF1B3A8F)),
    // 卢布：俄罗斯国旗 / 深蓝
    'RUB': XpCurrencyMeta(flag: '🇷🇺', color: Color(0xFF29408F)),
  };

  /// 未收录币种的兜底：地球 emoji + 主文字色。
  static const XpCurrencyMeta fallback = XpCurrencyMeta(
    flag: '🌐',
    color: Color(0xFF18212B),
  );

  /// 取币种元信息（未收录走 [fallback]）。
  static XpCurrencyMeta metaOf(String code) => currencies[code] ?? fallback;

  /// 取币种国旗 emoji。
  static String flagOf(String code) => metaOf(code).flag;

  /// 取币种专属色。
  static Color colorOf(String code) => metaOf(code).color;
}
