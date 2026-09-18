import 'dart:math' as math;

/// 账户名称归一化与相似度（合并候选检测、账户管理页排序共用）。

/// 账户名归一化：去括号内容、空格、卡号尾号、统一小写。
String normalizeAccountName(String name) {
  var n = name.trim();
  n = n.replaceAll(RegExp(r'[（(].*?[）)]'), ''); // 「支付宝（尾号1234）」
  n = n.replaceAll(RegExp(r'(尾号|卡号|#)\s*\d{2,}'), ''); // 尾号8888
  n = n.replaceAll(RegExp(r'[#*]{2,}\d{2,}'), ''); // ****8888
  n = n.replaceAll(RegExp(r'\s+'), '');
  return n.toLowerCase();
}

/// 两个账户名的相似度（0.0 ~ 1.0）：
/// - 归一化后完全相同 → 1.0
/// - 一方包含另一方 → 0.85（如「微信」与「微信钱包」）
/// - 否则按最长公共子串占比（0 ~ 0.84）
double accountNameSimilarity(String a, String b) {
  final na = normalizeAccountName(a);
  final nb = normalizeAccountName(b);
  if (na.isEmpty || nb.isEmpty) return 0;
  if (na == nb) return 1.0;
  if (na.contains(nb) || nb.contains(na)) return 0.85;
  final lcs = _longestCommonSubstring(na, nb);
  if (lcs <= 0) return 0;
  return math.min(0.84, lcs / math.max(na.length, nb.length));
}

/// 最长公共子串长度（朴素 DP，账户名很短，性能足够）。
int _longestCommonSubstring(String a, String b) {
  final m = a.length;
  final n = b.length;
  final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
  var best = 0;
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      if (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1)) {
        dp[i][j] = dp[i - 1][j - 1] + 1;
        if (dp[i][j] > best) best = dp[i][j];
      }
    }
  }
  return best;
}
