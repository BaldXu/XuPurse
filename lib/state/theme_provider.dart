import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 卡片样式风格。
enum XpCardStyle { filled, outlined, elevated }

/// 主题定义:颜色(seed/背景/卡片)+ 可选定制维度(字体/卡片样式/动画)。
///
/// - 暗色模式是独立预设主题(preset_dark),系统暗色开关 = 切换到它;
///   用户自定义主题仅在浅色模式下生效,不参与暗色。
/// - 持久化 JSON 带 `v` 版本号:旧格式(无 v)按 v1 读取,新字段全部取默认,
///   用户已建主题无损迁移。
class AppTheme {
  const AppTheme({
    required this.id,
    required this.name,
    required this.seedColor,
    this.background,
    this.cardColor,
    this.sheetColor,
    this.fontFamily,
    this.fontScale = 1.0,
    this.cardStyle = XpCardStyle.filled,
    this.cardRadius,
    this.animationsEnabled = true,
    this.isDark = false,
  });

  final String id;
  final String name;
  final Color seedColor;
  final Color? background; // 页面背景覆盖(浅色)
  final Color? cardColor; // 卡片背景覆盖(浅色)
  final Color? sheetColor; // 弹窗背景覆盖(浅色；配置弹窗磨砂开启时固定为白色)

  /// 系统字体名(null = 平台默认);仅支持系统已装字体,不做字体文件导入。
  final String? fontFamily;

  /// 字号缩放(0.85 / 1.0 / 1.15)。
  final double fontScale;

  /// 卡片统一样式。
  final XpCardStyle cardStyle;

  /// 卡片圆角覆盖(null = 跟随 token 默认 12)。
  final double? cardRadius;

  /// 页面转场 / 弹窗动画开关(尊重系统 reduce-motion 时强制关闭)。
  final bool animationsEnabled;

  /// 是否为暗色主题(暗色预设专用标记)。
  final bool isDark;

  /// 内置预设主题不可删除;用户自建主题 id 以 `user_` 开头。
  bool get isPreset => id.startsWith('preset_');

  static Color _color(String hex) {
    // 必须按 16 进制解析：缺 radix 会把 '#123456' 当十进制(123456=0x1E240)，
    // 导致重启后主题/背景/卡色全部错乱甚至回退默认色。
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | (v ?? 0xFF002FA7));
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  static XpCardStyle _cardStyleOf(String? s) => XpCardStyle.values.firstWhere(
    (e) => e.name == s,
    orElse: () => XpCardStyle.filled,
  );

  Map<String, Object?> toJson() => {
    'v': 3,
    'id': id,
    'name': name,
    'seedColor': _hex(seedColor),
    if (background != null) 'background': _hex(background!),
    if (cardColor != null) 'cardColor': _hex(cardColor!),
    if (sheetColor != null) 'sheetColor': _hex(sheetColor!),
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontScale != 1.0) 'fontScale': fontScale,
    if (cardStyle != XpCardStyle.filled) 'cardStyle': cardStyle.name,
    if (cardRadius != null) 'cardRadius': cardRadius,
    if (!animationsEnabled) 'animationsEnabled': false,
    if (isDark) 'isDark': true,
  };

  /// 兼容 v1(无 v 字段,仅三色)、v2 与 v3(含弹窗背景色)格式。
  static AppTheme fromJson(Map<String, Object?> json) => AppTheme(
    id: json['id'] as String,
    name: json['name'] as String,
    seedColor: _color(json['seedColor'] as String),
    background: json['background'] == null
        ? null
        : _color(json['background'] as String),
    cardColor: json['cardColor'] == null
        ? null
        : _color(json['cardColor'] as String),
    sheetColor: json['sheetColor'] == null
        ? null
        : _color(json['sheetColor'] as String),
    fontFamily: json['fontFamily'] as String?,
    fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
    cardStyle: _cardStyleOf(json['cardStyle'] as String?),
    cardRadius: (json['cardRadius'] as num?)?.toDouble(),
    animationsEnabled: json['animationsEnabled'] as bool? ?? true,
    isDark: json['isDark'] as bool? ?? false,
  );

  AppTheme copyWith({
    String? fontFamily,
    double? fontScale,
    XpCardStyle? cardStyle,
    double? cardRadius,
    bool? animationsEnabled,
    bool clearFontFamily = false,
    bool clearCardRadius = false,
  }) => AppTheme(
    id: id,
    name: name,
    seedColor: seedColor,
    background: background,
    cardColor: cardColor,
    sheetColor: sheetColor,
    fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
    fontScale: fontScale ?? this.fontScale,
    cardStyle: cardStyle ?? this.cardStyle,
    cardRadius: clearCardRadius ? null : (cardRadius ?? this.cardRadius),
    animationsEnabled: animationsEnabled ?? this.animationsEnabled,
    isDark: isDark,
  );
}

/// 暗色主题预设(独立于用户自定义体系;系统暗色开关即切换到它)。
/// 克莱因蓝暗色变体:fromSeed 暗色派生自动提亮 primary、中性色带蓝灰调
/// (深灰蓝背景),避免纯黑背景,符合设计稿要求。
const darkThemePreset = AppTheme(
  id: 'preset_dark',
  name: '暗色',
  seedColor: Color(0xFF002FA7),
  isDark: true,
);

/// 内置预设主题（不可删除）：唯一预设「克莱因蓝」，色值对齐 design_tokens §4.1
/// （页面背景 #F7F8F6 + 白色卡片 + 克莱因蓝主题色）。
const presetThemes = <AppTheme>[
  AppTheme(
    id: 'preset_klein',
    name: '克莱因蓝',
    seedColor: Color(0xFF002FA7),
    background: Color(0xFFF7F8F6), // 页面背景（designDirection §4.1）
    cardColor: Color(0xFFFFFFFF), // 白色卡片背景
  ),
];

/// 主题状态：当前主题 id + 用户自建主题列表（预设固定内置）。
class ThemeState {
  const ThemeState({required this.currentId, required this.userThemes});

  final String currentId;
  final List<AppTheme> userThemes;

  /// 全部可选主题(浅色主题 + 暗色预设;主题设置页展示用)。
  List<AppTheme> get allThemes => [
    ...presetThemes,
    darkThemePreset,
    ...userThemes,
  ];

  AppTheme get current => allThemes.firstWhere(
    (t) => t.id == currentId,
    orElse: () => presetThemes.first,
  );
}

/// 主题状态（当前主题 + 用户自建列表），持久化到 SharedPreferences。
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// 当前生效主题(带系统暗色感知:系统暗色时强制返回暗色预设主题)。
final currentThemeProvider = Provider<AppTheme>((ref) {
  final state = ref.watch(themeProvider);
  final platformDark =
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
      Brightness.dark;
  if (platformDark) return darkThemePreset;
  return state.current;
});

class ThemeNotifier extends Notifier<ThemeState> {
  static const _currentKey = 'theme_current_id';
  static const _userThemesKey = 'theme_user_themes';

  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 需要同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  @override
  ThemeState build() {
    final userThemes = _loadUserThemes();
    final currentId = _prefsCache?.getString(_currentKey);
    final valid = [
      ...presetThemes,
      ...userThemes,
    ].any((t) => t.id == currentId);
    return ThemeState(
      currentId: valid ? currentId! : presetThemes.first.id,
      userThemes: userThemes,
    );
  }

  List<AppTheme> _loadUserThemes() {
    final raw = _prefsCache?.getString(_userThemesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        // 读取时兜底:历史版本允许保存过深背景/卡色(浅色主题渲染会文字全糊),
        // 加载时把过深色置 null 回退默认,与保存时校验形成双保险。
        for (final e in list)
          _sanitizeTheme(AppTheme.fromJson((e as Map).cast<String, Object?>())),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// 浅色主题的背景/卡色/弹窗色亮度兜底:亮度 < 0.15(近黑)视为脏数据置 null。
  /// seedColor 不校验(主题色允许深色,如克莱因蓝)。
  static AppTheme _sanitizeTheme(AppTheme theme) {
    final bgOk =
        theme.background == null ||
        theme.background!.computeLuminance() >= 0.15;
    final cardOk =
        theme.cardColor == null || theme.cardColor!.computeLuminance() >= 0.15;
    final sheetOk =
        theme.sheetColor == null ||
        theme.sheetColor!.computeLuminance() >= 0.15;
    if (bgOk && cardOk && sheetOk) return theme;
    return AppTheme(
      id: theme.id,
      name: theme.name,
      seedColor: theme.seedColor,
      background: bgOk ? theme.background : null,
      cardColor: cardOk ? theme.cardColor : null,
      sheetColor: sheetOk ? theme.sheetColor : null,
      fontFamily: theme.fontFamily,
      fontScale: theme.fontScale,
      cardStyle: theme.cardStyle,
      cardRadius: theme.cardRadius,
      animationsEnabled: theme.animationsEnabled,
      isDark: theme.isDark,
    );
  }

  Future<void> _persist(ThemeState next) async {
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setString(_currentKey, next.currentId);
    await prefs.setString(
      _userThemesKey,
      jsonEncode([for (final t in next.userThemes) t.toJson()]),
    );
  }

  /// 选择并应用主题。暗色预设不在浅色列表中可直接选中(设置页入口),但
  /// 实际生效主题由系统暗色决定(currentThemeProvider)。
  Future<void> select(String id) async {
    if (state.currentId == id) return;
    final next = ThemeState(currentId: id, userThemes: state.userThemes);
    await _persist(next);
    state = next;
  }

  /// 新增用户自建主题并应用（成为当前主题）。
  Future<void> addUserTheme(AppTheme theme) async {
    final next = ThemeState(
      currentId: theme.id,
      userThemes: [...state.userThemes, theme],
    );
    await _persist(next);
    state = next;
  }

  /// 删除用户自建主题；内置预设或当前使用中的主题不可删，返回是否删除成功。
  Future<bool> deleteUserTheme(String id) async {
    if (!state.userThemes.any((t) => t.id == id)) return false; // 内置预设
    if (state.currentId == id) return false; // 当前使用中
    final next = ThemeState(
      currentId: state.currentId,
      userThemes: state.userThemes.where((t) => t.id != id).toList(),
    );
    await _persist(next);
    state = next;
    return true;
  }

  /// 更新当前主题的定制维度(字体/卡片样式/动画)并持久化。
  /// 仅用户自建主题可改;预设主题(含暗色)不可变,返回是否成功。
  Future<bool> updateCurrentTheme(AppTheme updated) async {
    if (updated.isPreset) return false;
    final next = ThemeState(
      currentId: state.currentId,
      userThemes: [
        for (final t in state.userThemes)
          if (t.id == updated.id) updated else t,
      ],
    );
    await _persist(next);
    state = next;
    return true;
  }
}

/// 磨砂玻璃配置（独立于具体主题）：
/// 总开关 + 三个子项——标题栏/导航栏磨砂、卡片磨砂、配置弹窗磨砂。
///
/// 历史版本只有单个总开关（即现在的 [enabled]），迁移时
/// 子项默认 appBar=true、card=false、sheet=false，保持旧行为不变。
class FrostedState {
  const FrostedState({
    required this.enabled,
    required this.appBar,
    required this.card,
    required this.sheet,
  });

  /// 磨砂总开关：关掉后所有子项全部失效。
  final bool enabled;

  /// 子项 1：标题栏 / 导航栏磨砂（AppBar 与一级页底部导航栏的白色高斯模糊）。
  final bool appBar;

  /// 子项 2：卡片磨砂（卡片表面半透明白磨砂，σ20 / α0.65）。
  final bool card;

  /// 子项 3：配置弹窗磨砂（底部配置弹窗表面白色磨砂，σ10 / α0.55）。
  final bool sheet;

  /// 标题栏/导航栏磨砂是否实际生效。
  bool get barsOn => enabled && appBar;

  /// 卡片磨砂是否实际生效。
  bool get cardsOn => enabled && card;

  /// 配置弹窗磨砂是否实际生效。
  bool get sheetOn => enabled && sheet;
}

/// 全局磨砂玻璃配置，持久化到 SharedPreferences。
final frostedGlassProvider =
    NotifierProvider<FrostedGlassNotifier, FrostedState>(
      FrostedGlassNotifier.new,
    );

class FrostedGlassNotifier extends Notifier<FrostedState> {
  /// 旧版总开关 key（迁移：写入/读取仍用它表示 enabled）。
  static const _key = 'ui_frosted_glass';
  static const _keyAppBar = 'ui_frosted_appbar';
  static const _keyCard = 'ui_frosted_card';
  static const _keySheet = 'ui_frosted_sheet';

  static SharedPreferences? _prefsCache;

  /// main 启动时调用，预热 SharedPreferences 缓存（build 需要同步读取）。
  static Future<void> init() async {
    _prefsCache = await SharedPreferences.getInstance();
  }

  @override
  FrostedState build() => FrostedState(
    enabled: _prefsCache?.getBool(_key) ?? true,
    appBar: _prefsCache?.getBool(_keyAppBar) ?? true,
    card: _prefsCache?.getBool(_keyCard) ?? false,
    sheet: _prefsCache?.getBool(_keySheet) ?? false,
  );

  Future<void> _persist(FrostedState next) async {
    final prefs = await SharedPreferences.getInstance();
    _prefsCache = prefs;
    await prefs.setBool(_key, next.enabled);
    await prefs.setBool(_keyAppBar, next.appBar);
    await prefs.setBool(_keyCard, next.card);
    await prefs.setBool(_keySheet, next.sheet);
  }

  Future<void> setEnabled(bool value) async {
    if (state.enabled == value) return;
    final next = FrostedState(
      enabled: value,
      appBar: state.appBar,
      card: state.card,
      sheet: state.sheet,
    );
    await _persist(next);
    state = next;
  }

  Future<void> setAppBar(bool value) async {
    if (state.appBar == value) return;
    final next = FrostedState(
      enabled: state.enabled,
      appBar: value,
      card: state.card,
      sheet: state.sheet,
    );
    await _persist(next);
    state = next;
  }

  Future<void> setCard(bool value) async {
    if (state.card == value) return;
    final next = FrostedState(
      enabled: state.enabled,
      appBar: state.appBar,
      card: value,
      sheet: state.sheet,
    );
    await _persist(next);
    state = next;
  }

  Future<void> setSheet(bool value) async {
    if (state.sheet == value) return;
    final next = FrostedState(
      enabled: state.enabled,
      appBar: state.appBar,
      card: state.card,
      sheet: value,
    );
    await _persist(next);
    state = next;
  }
}
