// 阶段 0 性能基线采集入口 —— 仅 profile 模式运行，不进生产构建：
//   flutter run --profile -t lib/main_profile.dart
//
// 程序化复现用户反馈的两个卡顿场景（进主题外观页转场 / 打开记账弹窗），
// 每场景连跑 3 次，用 FrameTiming 对比首跑与复跑，定性区分：
// - 一次性 jank（shader/PSO 编译）：首跑尖刺、复跑平滑
// - 持续掉帧（逐帧重算类，如 BackdropFilter）：每次都尖刺
// 输出 REPORT 后自动退出。
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'main.dart' as app;
import 'state/theme_provider.dart';
import 'ui/layout/xp_page_scaffold_mixin.dart';
import 'ui/pages/bookkeeping_sheet.dart';
import 'ui/pages/theme_settings_page.dart';

Future<void> main() async {
  await app.main();
  await _Harness().run();
}

class _Harness {
  final List<FrameTiming> _frames = [];

  Future<void> run() async {
    SchedulerBinding.instance.addTimingsCallback((ts) => _frames.addAll(ts));

    // 等启动与首页数据流稳定（含首次骨架→内容切换）。
    await Future<void>.delayed(const Duration(seconds: 8));

    final context = app.appNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('HARNESS_FAIL: navigator context 不可用');
      exit(2);
    }

    // context 来自全局 key，app 运行期始终 mounted；此 lint 在采集场景为误报。
    // ignore: use_build_context_synchronously
    final refresh = View.of(context).display.refreshRate;
    final budget = 1000 / refresh;
    // ignore: use_build_context_synchronously
    final container = ProviderScope.containerOf(context);
    final theme = container.read(currentThemeProvider);
    final frosted = container.read(frostedGlassProvider);

    debugPrint('=== XUPURSE PROFILE BASELINE ===');
    debugPrint('platform: ${Platform.operatingSystemVersion}');
    debugPrint(
      'refreshRate: ${refresh.toStringAsFixed(0)}Hz '
      'budget: ${(1000 / refresh).toStringAsFixed(1)}ms '
      'profile: $kProfileMode',
    );
    debugPrint(
      'animations: ${theme.animationsEnabled}  '
      'frosted: on=${frosted.enabled} bar=${frosted.appBar} '
      'card=${frosted.card} sheet=${frosted.sheet}',
    );

    final nav = Navigator.of(
      context, // ignore: use_build_context_synchronously
    );

    // 场景 1：进主题外观页（转场）—— 用户反馈卡顿点 ①
    final themePush = <String, List<FrameTiming>>{};
    final themePop = <String, List<FrameTiming>>{};
    for (var i = 1; i <= 3; i++) {
      themePush['run$i'] = await _window(() async {
        unawaited(
          nav.push(XpRoute<void>(builder: (_) => const ThemeSettingsPage())),
        );
      }, settleMs: 1600);
      themePop['run$i'] = await _window(() async => nav.pop(), settleMs: 1400);
    }

    // 场景 2：记账弹窗 —— 用户反馈卡顿点 ②
    final sheetOpen = <String, List<FrameTiming>>{};
    final sheetClose = <String, List<FrameTiming>>{};
    for (var i = 1; i <= 3; i++) {
      sheetOpen['run$i'] = await _window(() async {
        unawaited(BookkeepingSheet.show(context));
      }, settleMs: 2200);
      sheetClose['run$i'] = await _window(
        () async => nav.pop(),
        settleMs: 1400,
      );
    }

    void dump(String name, Map<String, List<FrameTiming>> windows) {
      debugPrint('--- $name ---');
      for (final e in windows.entries) {
        debugPrint('run=${e.key} ${_fmt(e.value, budget)}');
      }
    }

    dump('theme_page_push', themePush);
    dump('theme_page_pop', themePop);
    dump('bookkeeping_sheet_open', sheetOpen);
    dump('bookkeeping_sheet_close', sheetClose);

    debugPrint('=== REPORT END ===');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    exit(0);
  }

  /// 冲刷上一窗口 → 标记起点 → 执行动作 → 等动画+稳定 → 收集窗口内帧。
  Future<List<FrameTiming>> _window(
    Future<void> Function() act, {
    required int settleMs,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final start = _frames.length;
    await act();
    await Future<void>.delayed(Duration(milliseconds: settleMs));
    return List<FrameTiming>.unmodifiable(
      _frames.getRange(start, _frames.length),
    );
  }

  /// 刷新率自适应阈值：>1×/>2× 帧预算（120Hz 时预算 8.3ms，60Hz 时 16.7ms），
  /// 超预算帧数才是跨刷新率可比的掉帧指标。
  String _fmt(List<FrameTiming> fs, double budget) {
    if (fs.isEmpty) return 'frames=0';
    List<double> ms(List<FrameTiming> l, Duration Function(FrameTiming) pick) =>
        l.map((f) => pick(f).inMicroseconds / 1000).toList()..sort();
    final total = ms(fs, (f) => f.totalSpan);
    final build = ms(fs, (f) => f.buildDuration);
    final raster = ms(fs, (f) => f.rasterDuration);
    double avg(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    final p95 = total[(total.length - 1) * 95 ~/ 100];
    final worst = total.last;
    return 'frames=${fs.length} '
        'totalAvg=${avg(total).toStringAsFixed(1)} '
        'p95=${p95.toStringAsFixed(1)} worst=${worst.toStringAsFixed(1)} | '
        'buildAvg=${avg(build).toStringAsFixed(1)} '
        'buildWorst=${build.last.toStringAsFixed(1)} | '
        'rasterAvg=${avg(raster).toStringAsFixed(1)} '
        'rasterWorst=${raster.last.toStringAsFixed(1)} | '
        '>1budget=${total.where((t) => t > budget).length} '
        '>2budget=${total.where((t) => t > 2 * budget).length}';
  }
}
