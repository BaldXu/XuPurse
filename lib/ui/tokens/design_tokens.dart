import 'package:flutter/material.dart';

/// XuPurse 设计 token —— 「明亮光感极简」设计语言（docs/designDirection.md）。
///
/// 全项目 UI 常量唯一来源；页面禁止再写裸 radius / 硬编码语义色。
/// 主题可定制维度（卡片圆角、动画时长等）在主题模型中引用这里的默认值。

/// 品牌色：克莱因蓝（International Klein Blue）。
abstract final class XpBrandColors {
  /// 品牌主色
  static const Color primary = Color(0xFF002FA7);

  /// 主色深阶（hover / pressed）
  static const Color primaryDeep = Color(0xFF00226E);

  /// 主色柔和底（约 8%，选中态背景）
  static const Color primarySoft = Color(0x14002FA7);

  /// 品牌蓝上的前景
  static const Color onPrimary = Color(0xFFFFFFFF);
}

/// 圆角四档：c12 / s14 / m20 / l28（G2 连续曲率，见 [XpShape]）。
abstract final class XpRadius {
  /// 小控件圆角（迷你按钮、开关轨道）
  static const double c = 12;

  /// 小圆角（chip、输入框）
  static const double s = 14;

  /// 中圆角（卡片、按钮）——项目默认圆角
  static const double m = 20;

  /// 大圆角（大面板、弹窗、sheet 顶部）
  static const double l = 28;

  /// 超大圆角（配置弹窗大圆角）
  static const double xl = 40;

  /// 胶囊（全圆）
  static const double pill = 999;

  static final BorderRadius card = BorderRadius.circular(m);

  /// 底部弹窗顶部圆角 shape（G2 连续曲率）
  static final RoundedSuperellipseBorder sheet = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(l)),
  );

  /// 配置弹窗顶部大圆角 shape（G2 连续曲率，遵循设计规范）
  static final RoundedSuperellipseBorder sheetLarge = RoundedSuperellipseBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(xl)),
  );
}

/// 形状：G2 连续曲率（superellipse）边框的唯一封装。
///
/// Flutter 3.32+ 原生 RoundedSuperellipseBorder；未来换实现只改这里。
abstract final class XpShape {
  /// G2 连续曲率圆角边框
  static RoundedSuperellipseBorder smooth({
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(XpRadius.m),
    ),
    BorderSide side = BorderSide.none,
  }) => RoundedSuperellipseBorder(borderRadius: borderRadius, side: side);

  /// 默认卡片形状（m20 + G2）
  static final RoundedSuperellipseBorder card = smooth(
    borderRadius: XpRadius.card,
  );
}

/// 间距（4 的倍数）
abstract final class XpSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}

/// 语义色：收入 / 支出 / 转账 / 警示 / 危险。
///
/// 历史来源 bill_tile.dart 常量（2026-09 上提统一）；未来主题可覆盖时，
/// 改为经 ThemeExtension 提供，消费端入口不变。
abstract final class XpSemanticColors {
  /// 支出
  static const Color expense = Color(0xFFF0645A);

  /// 收入
  static const Color income = Color(0xFF20B978);

  /// 转账
  static const Color transfer = Color(0xFF3E9FE8);

  /// 警示
  static const Color warning = Color(0xFFE7A92B);

  /// 删除等警示操作（错误红，独立于支出色）
  static const Color danger = Color(0xFFE05454);
}

/// 分层海拔 E0-E3（冷灰蓝色温阴影）。
abstract final class XpElevation {
  /// 平面（页面底、分割元素）
  static const double e0 = 0;

  /// 轻浮（卡片）
  static const double e1 = 2;

  /// 悬浮（下拉、弹出菜单）
  static const double e2 = 6;

  /// 模态（弹窗、sheet）
  static const double e3 = 12;

  /// 阴影色温：主文字色（冷灰蓝黑）
  static const Color shadow = Color(0xFF18212B);
}

/// 动效四档：micro / component / container / page。
abstract final class XpMotion {
  /// 微交互（按压、勾选）
  static const Duration micro = Duration(milliseconds: 170);

  /// 组件（chip、按钮状态）
  static const Duration component = Duration(milliseconds: 240);

  /// 容器（卡片展开、sheet）
  static const Duration container = Duration(milliseconds: 350);

  /// 页面转场
  static const Duration page = Duration(milliseconds: 450);

  /// 进入一律 easeOut
  static const Curve easeOut = Curves.easeOutCubic;

  /// 退出一律 easeIn
  static const Curve easeIn = Curves.easeInCubic;

  // ── 页面转场「空间层级」参数（XpPageTransitionsBuilder 消费，调整只改这里）──

  /// 新页滑入起始缩放（<1 产生「向前靠近」感，滑入过程放大到 1.0）。
  static const double pageEnterScaleFrom = 0.96;

  /// 旧页后退目标缩放（1.0 → 该值，产生后退感）。
  static const double pageExitScaleTo = 0.94;

  /// 旧页后退时轻微左移距离（逻辑像素）。
  static const double pageExitShift = 16;

  /// 旧页变暗遮罩最大透明度（0~1）。
  static const double pageExitDim = 0.18;

  /// 旧页轻微模糊 sigma。性能敏感：真机掉帧时置 0 关闭，
  /// 退化为 Scale + Translate + Dim 兜底。
  static const double pageExitBlur = 3;
}

/// 排印阶梯：Display 32 / H1 28 / H2 22 / H3 18 / BodyL 16 / Body 14 / Caption 12。
///
/// 由 theme.dart 挂载到全局 textTheme；页面优先用 Theme.of(context).textTheme。
abstract final class XpTextStyles {
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.25,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle bodyL = TextStyle(fontSize: 16, height: 1.5);

  static const TextStyle body = TextStyle(fontSize: 14, height: 1.5);

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    letterSpacing: 0.2,
  );
}

/// 金额 / 数字排印：等宽数字（tabular figures）——金额强调靠字重，不靠字号。
extension XpTabularText on TextStyle {
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// 页内二级断点：宽于此值用页内左右分栏（统计页分区 Rail），否则横向 Tab。
/// 与 kWideBreakpoint（800，主导航断点）区分：这是内容区内部的分栏阈值。
const double kSectionBreakpoint = 640;
