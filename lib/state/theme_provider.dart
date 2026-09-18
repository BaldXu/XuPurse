import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题定义：主题色（seed）+ 可选页面背景 / 卡片背景覆盖。
///
/// `background` / `cardColor` 为 null 时跟随主题默认（Material 3 派生色）。
class AppTheme {
  const AppTheme({
    required this.id,
    required this.name,
    required this.seedColor,
    this.background,
    this.cardColor,
  });

  final String id;
  final String name;
  final Color seedColor;
  final Color? background; // 页面背景覆盖
  final Color? cardColor; // 卡片背景覆盖

  /// 内置预设主题不可删除；用户自建主题 id 以 `user_` 开头。
  bool get isPreset => id.startsWith('preset_');

  static Color _color(String hex) {
    final v = int.tryParse(hex.replaceFirst('#', ''));
    return Color(0xFF000000 | (v ?? 0xFF2F6F4F));
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'seedColor': _hex(seedColor),
    if (background != null) 'background': _hex(background!),
    if (cardColor != null) 'cardColor': _hex(cardColor!),
  };

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
  );
}

/// 内置预设主题（不可删除）。克莱因蓝：浅灰白页面背景 + 白色卡片 + 克莱因蓝主题色。
const presetThemes = <AppTheme>[
  AppTheme(id: 'preset_green', name: '蓝绿', seedColor: Color(0xFF2F6F4F)),
  AppTheme(id: 'preset_blue', name: '蓝', seedColor: Color(0xFF2F5FA8)),
  AppTheme(id: 'preset_purple', name: '紫', seedColor: Color(0xFF7C4DBB)),
  AppTheme(id: 'preset_red', name: '红', seedColor: Color(0xFFB33A3A)),
  AppTheme(id: 'preset_orange', name: '橙', seedColor: Color(0xFFB06A00)),
  AppTheme(id: 'preset_teal', name: '青', seedColor: Color(0xFF1E6B7A)),
  AppTheme(id: 'preset_olive', name: '橄榄', seedColor: Color(0xFF6B7A1E)),
  AppTheme(id: 'preset_graphite', name: '石墨', seedColor: Color(0xFF3A3A3A)),
  AppTheme(
    id: 'preset_klein',
    name: '克莱因蓝',
    seedColor: Color(0xFF002FA7),
    background: Color(0xFFF5F6F8), // 浅灰白页面背景
    cardColor: Color(0xFFFFFFFF), // 白色卡片背景
  ),
];

/// 主题状态：当前主题 id + 用户自建主题列表（预设固定内置）。
class ThemeState {
  const ThemeState({required this.currentId, required this.userThemes});

  final String currentId;
  final List<AppTheme> userThemes;

  List<AppTheme> get allThemes => [...presetThemes, ...userThemes];

  AppTheme get current => allThemes.firstWhere(
    (t) => t.id == currentId,
    orElse: () => presetThemes.first,
  );
}

/// 主题状态（当前主题 + 用户自建列表），持久化到 SharedPreferences。
final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);

/// 当前生效主题。
final currentThemeProvider = Provider<AppTheme>(
  (ref) => ref.watch(themeProvider).current,
);

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
        for (final e in list)
          AppTheme.fromJson((e as Map).cast<String, Object?>()),
      ];
    } catch (_) {
      return const [];
    }
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

  /// 选择并应用主题。
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
}
