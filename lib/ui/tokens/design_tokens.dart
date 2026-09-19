import 'package:flutter/material.dart';

/// XuPurse 设计 token:圆角 / 间距 / 语义色 / 动画。
///
/// 全项目 UI 常量唯一来源;页面禁止再写裸 radius / 硬编码语义色。
/// 主题可定制维度(卡片圆角、动画时长等)在 P2 主题模型中引用这里的默认值。
abstract final class XpRadius {
  /// 小圆角(chip、小按钮)
  static const double s = 8;

  /// 中圆角(卡片、输入框、按钮)——项目默认圆角
  static const double m = 12;

  /// 大圆角(大面板)
  static const double l = 16;

  /// 胶囊/底部弹窗顶部
  static const double pill = 20;

  static final BorderRadius card = BorderRadius.circular(m);

  /// 底部弹窗顶部圆角 shape
  static final RoundedRectangleBorder sheet = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(pill)),
  );
}

/// 间距(4 的倍数)
abstract final class XpSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}

/// 语义色:收入 / 支出 / 转账。
///
/// 历史来源 bill_tile.dart 常量(2026-09 上提统一);未来主题可覆盖时,
/// 改为经 ThemeExtension 提供,消费端入口不变。
abstract final class XpSemanticColors {
  static const Color expense = Color(0xFFE5484D);
  static const Color income = Color(0xFF30A46C);
  static const Color transfer = Color(0xFF6E6E77);

  /// 删除等警示操作(与支出同色系)
  static const Color danger = expense;
}

/// 动画时长与曲线
abstract final class XpMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Curve curve = Curves.easeOutCubic;
}

/// 页内二级断点:宽于此值用页内左右分栏(统计页分区 Rail),否则横向 Tab。
/// 与 kWideBreakpoint(800,主导航断点)区分:这是内容区内部的分栏阈值。
const double kSectionBreakpoint = 640;
