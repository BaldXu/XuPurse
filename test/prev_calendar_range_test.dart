import 'package:flutter_test/flutter_test.dart';

import 'package:xupurse/ui/pages/statistics/stats_shared.dart';

void main() {
  group('prevCalendarRange 环比上期日历对齐', () {
    int ms(int y, int m, [int d = 1]) =>
        DateTime(y, m, d).millisecondsSinceEpoch;

    test('本月(9/1~10/1)的上期是整个上月(8/1~9/1)，而非滚动窗口(8/2~9/1)', () {
      final prev = prevCalendarRange(ms(2026, 9), ms(2026, 10));
      expect(prev.start, ms(2026, 8));
      expect(prev.end, ms(2026, 9));
    });

    test('31 天月(8月)环比不切边：7/1~8/1 的上期是 6/1~7/1', () {
      // 旧算法 span=31 天 → 6/30，错切 6/30 全天；日历对齐 = 上月。
      final prev = prevCalendarRange(ms(2026, 8), ms(2026, 9));
      expect(prev.start, ms(2026, 7));
      expect(prev.end, ms(2026, 8));
    });

    test('跨年(12月)环比：2026/12 → 2026/11', () {
      final prev = prevCalendarRange(ms(2026, 12), ms(2027, 1));
      expect(prev.start, ms(2026, 11));
      expect(prev.end, ms(2026, 12));
    });

    test('1月环比跨年：2027/1 → 2026/12', () {
      final prev = prevCalendarRange(ms(2027, 1), ms(2027, 2));
      expect(prev.start, ms(2026, 12));
      expect(prev.end, ms(2027, 1));
    });

    test('本年(2026)的上期是整个去年(2025)', () {
      final prev = prevCalendarRange(ms(2026, 1), ms(2027, 1));
      expect(prev.start, ms(2025, 1));
      expect(prev.end, ms(2026, 1));
    });

    test('整周(周一起)的上期是上一周', () {
      // 2026-09-07 是周一 → 8/31(周一)~9/7(周一)。
      final prev = prevCalendarRange(ms(2026, 9, 7), ms(2026, 9, 14));
      expect(prev.start, ms(2026, 8, 31));
      expect(prev.end, ms(2026, 9, 7));
    });

    test('自定义范围(非日历对齐)按整天平移，边界同刻', () {
      // 9/5 ~ 9/19（14 天）→ 8/22 ~ 9/5。
      final s = DateTime(2026, 9, 5);
      final e = DateTime(2026, 9, 19);
      final prev = prevCalendarRange(
        s.millisecondsSinceEpoch,
        e.millisecondsSinceEpoch,
      );
      expect(DateTime.fromMillisecondsSinceEpoch(prev.start).day, 22);
      expect(DateTime.fromMillisecondsSinceEpoch(prev.start).month, 8);
      expect(DateTime.fromMillisecondsSinceEpoch(prev.end).day, 5);
    });

    test('跨整月边界但非 1 号起止(6/15~7/15)不误判为整月，按整天数平移', () {
      // 旧实现只校验年/月，会把 6/15~7/15 误对齐成上期 5/1~6/1（丢 15 天）；
      // 正确为保持区间长度平移 30 天：5/16~6/15。
      final s = DateTime(2026, 6, 15);
      final e = DateTime(2026, 7, 15);
      final prev = prevCalendarRange(
        s.millisecondsSinceEpoch,
        e.millisecondsSinceEpoch,
      );
      final ps = DateTime.fromMillisecondsSinceEpoch(prev.start);
      final pe = DateTime.fromMillisecondsSinceEpoch(prev.end);
      expect(ps.year, 2026);
      expect(ps.month, 5);
      expect(ps.day, 16);
      expect(pe.month, 6);
      expect(pe.day, 15);
    });

    test('跨整月边界的 30 天区间(8/31~9/30)不误判为整月', () {
      // 8/31~9/30 跨月边界且端点都非 1 号，旧实现误对齐到 7/1~8/1；
      // 正确为保持区间长度平移 30 天：8/1~8/31。
      final s = DateTime(2026, 8, 31);
      final e = DateTime(2026, 9, 30);
      final prev = prevCalendarRange(
        s.millisecondsSinceEpoch,
        e.millisecondsSinceEpoch,
      );
      final ps = DateTime.fromMillisecondsSinceEpoch(prev.start);
      final pe = DateTime.fromMillisecondsSinceEpoch(prev.end);
      expect(ps.month, 8);
      expect(ps.day, 1);
      expect(pe.month, 8);
      expect(pe.day, 31);
    });


    test('非整点起点不误判为日历月（滚动平移兜底）', () {
      // 9/1 12:00 ~ 10/1 12:00 不是日历月端点（非 00:00）。
      final s = DateTime(2026, 9, 1, 12);
      final e = DateTime(2026, 10, 1, 12);
      final prev = prevCalendarRange(
        s.millisecondsSinceEpoch,
        e.millisecondsSinceEpoch,
      );
      final ps = DateTime.fromMillisecondsSinceEpoch(prev.start);
      expect(ps.month, 8);
      expect(ps.hour, 12);
    });
  });
}
