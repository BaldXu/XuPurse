import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/bill_repository.dart';
import '../../state/providers.dart';

/// 单次发送给 AI 的逐笔明细：条数硬上限。
///
/// 约合 24k tokens（每笔 ~30 tokens），给 32k 上下文模型留足余量。
const int kAiAnalysisMaxCount = 600;

/// 单次发送的 JSON 字节硬上限（UTF-8）。
const int kAiAnalysisMaxBytes = 64 * 1024;

/// 黄色提醒线：条数。
const int kAiAnalysisWarnCount = 300;

/// 黄色提醒线：字节。
const int kAiAnalysisWarnBytes = 32 * 1024;

/// 单条备注最长保留字符数（防单条超长备注撑爆体积）。
const int kAiAnalysisNoteMaxChars = 60;

/// 逐笔明细的 JSON 快照 + 体量统计。
class AiAnalysisData {
  const AiAnalysisData({
    required this.json,
    required this.count,
    required this.bytes,
    required this.expense,
    required this.income,
    required this.redacted,
    required this.start,
    required this.end,
    required this.includeNotes,
    this.estimated = false,
  });

  /// 紧凑 JSON 文本；[estimated] 为 true 时为空串（仅用于超量范围的体积提示）。
  final String json;

  /// 账单条数。
  final int count;

  /// JSON 的 UTF-8 字节数（[estimated] 时为估算值）。
  final int bytes;

  /// 区间内支出合计（万分之元）。
  final int expense;

  /// 区间内收入合计（万分之元）。
  final int income;

  /// 备注是否已脱敏。
  final bool redacted;

  /// 区间 `[start, end)` 毫秒。
  final int start;
  final int end;

  /// 本次是否附带备注。
  final bool includeNotes;

  /// 条数过大未真正构建 JSON，[bytes] 为估算。
  final bool estimated;

  /// 估算 token 数（字节 × 0.27，中英混合保守值）。
  int get tokens => (bytes * 27) ~/ 100;

  /// 超过硬上限，禁止发送。
  bool get overLimit => count > kAiAnalysisMaxCount || bytes > kAiAnalysisMaxBytes;

  /// 处于黄色提醒区。
  bool get warn => count > kAiAnalysisWarnCount || bytes > kAiAnalysisWarnBytes;

  /// 超量但未构建 JSON 时的占位。
  factory AiAnalysisData.estimate({
    required int count,
    required bool includeNotes,
    required int start,
    required int end,
  }) => AiAnalysisData(
    json: '',
    count: count,
    bytes: count * (includeNotes ? 140 : 105),
    expense: 0,
    income: 0,
    redacted: false,
    start: start,
    end: end,
    includeNotes: includeNotes,
    estimated: true,
  );
}

/// 生成「逐笔明细 JSON」并做体量统计。
///
/// 设计要点（与统计页 AI 助手的聚合摘要不同）：
/// - 只发原始账目，不发账户余额、账单 id、坐标、图片；
/// - 金额统一转「元」并保留两位小数，避免 AI 误读万分之元整数；
/// - 备注可选，开启时做本地脱敏（手机号/身份证/卡号/邮箱/长数字）；
/// - 传输格式为紧凑 JSON（短键名），体积随范围线性增长。
class AiAnalysisContext {
  AiAnalysisContext(this._ref);

  /// 支持来自 Notifier 的 [Ref] 或 Widget 的 [WidgetRef]。
  final dynamic _ref;

  T _read<T>(ProviderListenable<T> provider) => _ref.read(provider);

  BillRepository get _repo => _read<BillRepository>(billRepoProvider);

  /// 范围内账单数量（统计口径）。
  Future<int> countInRange(int start, int end) =>
      _repo.countInRange(start, end);

  /// 当前范围解析结果。
  (int, int) rangeOf(int start, int end) => (start, end);

  /// 按范围生成逐笔明细 JSON。
  ///
  /// 条数超过 [kAiAnalysisMaxCount] × 4 时不再构建 JSON（避免拉全库），
  /// 返回 [AiAnalysisData.estimated] 供界面展示超限提示。
  Future<AiAnalysisData> build({
    required int start,
    required int end,
    required bool includeNotes,
  }) async {
    // 账户/分类名先在同步阶段取好：await 之后页面可能已 dispose，
    // 继续用 WidgetRef 读 provider 会抛「ref after dispose」。
    final accounts = _read(accountsProvider).value ?? const <Account>[];
    final categories = _read(categoriesProvider).value ?? const <Category>[];

    final count = await countInRange(start, end);
    if (count > kAiAnalysisMaxCount * 4) {
      return AiAnalysisData.estimate(
        count: count,
        includeNotes: includeNotes,
        start: start,
        end: end,
      );
    }

    final bills = await _repo.listByRange(start, end);
    return _assemble(
      bills: bills,
      start: start,
      end: end,
      includeNotes: includeNotes,
      accounts: accounts,
      categories: categories,
    );
  }

  /// 用给定的账单列表生成 JSON（消费清单 AI 分析用）。
  ///
  /// 与按时间范围生成的区别：范围由账单本身推导，并可附带「清单内分类」。
  AiAnalysisData buildFromBills({
    required List<Bill> bills,
    required bool includeNotes,
    String? listName,
    Map<String, String>? sectionByBillId,
  }) {
    final accounts = _read(accountsProvider).value ?? const <Account>[];
    final categories = _read(categoriesProvider).value ?? const <Category>[];
    var minT = 0;
    var maxT = 0;
    if (bills.isNotEmpty) {
      minT = bills.first.time;
      maxT = bills.first.time;
      for (final b in bills) {
        if (b.time < minT) minT = b.time;
        if (b.time > maxT) maxT = b.time;
      }
    }
    return _assemble(
      bills: bills,
      start: minT,
      end: maxT + 1,
      includeNotes: includeNotes,
      accounts: accounts,
      categories: categories,
      listName: listName,
      sectionByBillId: sectionByBillId,
    );
  }

  AiAnalysisData _assemble({
    required List<Bill> bills,
    required int start,
    required int end,
    required bool includeNotes,
    required List<Account> accounts,
    required List<Category> categories,
    String? listName,
    Map<String, String>? sectionByBillId,
  }) {
    final sorted = [...bills]..sort((a, b) => a.time.compareTo(b.time));
    final accountName = {for (final a in accounts) a.id: a.name};
    final categoryById = {for (final c in categories) c.id: c};

    String categoryPath(String id) {
      final c = categoryById[id];
      if (c == null) return '';
      final parentId = c.parentId;
      if (parentId == null) return c.name;
      final parent = categoryById[parentId];
      return parent == null ? c.name : '${parent.name}/${c.name}';
    }

    final rows = <Map<String, Object?>>[];
    var expense = 0;
    var income = 0;

    for (final b in sorted) {
      final toAccount = b.incomeAccountId;
      final isTransfer = toAccount != null;
      final type = isTransfer
          ? 'trf'
          : (b.type == 'income' ? 'inc' : 'exp');
      if (type == 'exp') expense += b.amount;
      if (type == 'inc') income += b.amount;

      final fromName = accountName[b.accountId] ?? '未知账户';
      final row = <String, Object?>{
        't': _formatTime(b.time),
        'ty': type,
        'a': _yuan(b.amount),
        if (!isTransfer) 'c': categoryPath(b.categoryId),
        'ac': isTransfer
            ? '$fromName→${accountName[toAccount] ?? '未知账户'}'
            : fromName,
      };

      final section = sectionByBillId?[b.id];
      if (section != null && section.isNotEmpty) row['sec'] = section;

      final note = b.comment?.trim();
      if (includeNotes && note != null && note.isNotEmpty) {
        row['n'] = _sanitizeNote(note);
      }
      rows.add(row);
    }

    final json = jsonEncode({
      'meta': {
        'v': 1,
        if (listName != null && listName.isNotEmpty) 'list': listName,
        'from': _formatDate(start),
        'to': _formatDate(end - 1),
        'cnt': rows.length,
        'redacted': includeNotes,
        'sum': {'exp': _yuan(expense), 'inc': _yuan(income)},
        'note': '金额单位为元；sec 为清单内分类；n 为备注（*** 表示已脱敏）',
      },
      'b': rows,
    });

    return AiAnalysisData(
      json: json,
      count: rows.length,
      bytes: utf8.encode(json).length,
      expense: expense,
      income: income,
      redacted: includeNotes,
      start: start,
      end: end,
      includeNotes: includeNotes,
    );
  }

  /// 从区间末尾向前按 7 天步进，找出条数不超过上限的最长区间起点。
  ///
  /// 返回 null 表示当前范围本身没超限，或向前找满 400 周仍无解。
  Future<int?> suggestStart(int start, int end) async {
    final total = await countInRange(start, end);
    if (total <= kAiAnalysisMaxCount) return null;
    var cursor = end;
    for (var i = 0; i < 400; i++) {
      final prev = DateTime.fromMillisecondsSinceEpoch(cursor);
      cursor = prev.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      if (cursor <= start) return null;
      final c = await countInRange(cursor, end);
      if (c <= kAiAnalysisMaxCount) return cursor;
    }
    return null;
  }
}

/// 万分之元 → 元（两位小数，作为 JSON 数字输出）。
num _yuan(int fen) => num.parse((fen / 10000).toStringAsFixed(2));

String _formatDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mm-$dd';
}

/// 同年只留「月-日 时:分」，跨年补年份（省体积）。
String _formatTime(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mi = d.minute.toString().padLeft(2, '0');
  if (d.year == DateTime.now().year) return '$mm-$dd $hh:$mi';
  return '${d.year}-$mm-$dd $hh:$mi';
}

/// 备注脱敏：身份证 → 手机号 → 邮箱 → 6 位以上连续数字。
final List<RegExp> _redactPatterns = [
  RegExp(r'\d{17}[\dXx]'),
  RegExp(r'1[3-9]\d{9}'),
  RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'),
  RegExp(r'\d{6,}'),
];

String _sanitizeNote(String note) {
  var text = note;
  for (final p in _redactPatterns) {
    text = text.replaceAll(p, '***');
  }
  if (text.length > kAiAnalysisNoteMaxChars) {
    text = '${text.substring(0, kAiAnalysisNoteMaxChars)}…';
  }
  return text;
}
