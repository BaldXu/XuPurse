import 'package:flutter/material.dart';

/// 解析 `#RRGGBB` / `#AARRGGBB` 十六进制颜色；非法值回退主题色。
Color hexToColor(String? hex, {Color fallback = const Color(0xFF8E8E93)}) {
  if (hex == null) return fallback;
  var text = hex.trim().replaceFirst('#', '');
  if (text.length == 6) text = 'FF$text';
  if (text.length != 8) return fallback;
  final value = int.tryParse(text, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}
