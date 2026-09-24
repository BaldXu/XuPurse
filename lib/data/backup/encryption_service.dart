import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// 备份加密服务：Argon2id 派生密钥 + AES-256-GCM 认证加密。
///
/// 加密备份 = JSON 信封（明文元数据 + base64 密文），业务数据全部在密文内。
/// 格式自描述（`enc` 标记），恢复时无需额外配置即可识别。
///
/// 安全约定：
/// - 密码不落盘、无找回机制，忘记密码 = 数据永久丢失。
/// - 每次备份随机 salt + nonce，同一密码多次备份的密文互不相同。
/// - GCM 自带完整性校验：密码错误或文件被篡改都会解密失败。
class BackupEncryption {
  BackupEncryption._();

  /// 备份格式标识（与明文备份共用，方便恢复端统一识别）。
  static const String formatName = 'xupurse-backup';

  /// 当前备份格式版本。
  static const int formatVersion = 2;

  /// 加密信封标记：存在即视为加密备份。
  static const String envelopeMagic = 'xupurse-backup-encrypted';

  /// Argon2id 参数：64 MiB 内存 / 3 轮 / 4 并行，输出 32 字节（AES-256 密钥）。
  ///
  /// 故意设得较慢以抵抗弱密码暴力破解 —— 这是「加密后备份/恢复变慢」的
  /// 主要来源，加解密各付一次。
  static const int kdfMemoryKib = 64 * 1024;
  static const int kdfIterations = 3;
  static const int kdfParallelism = 4;

  static final AesGcm _aes = AesGcm.with256bits();
  static final Random _random = Random.secure();

  /// 测试专用：并行测试负载下 Argon2id（64 MiB / 3 轮）派生可能极慢导致
  /// 单测超时，测试环境置 true 换用轻量参数（仅降低派生成本，算法不变）。
  static bool fastKdf = false;

  static Argon2id get _kdf => fastKdf
      ? Argon2id(memory: 1024, iterations: 1, parallelism: 1, hashLength: 32)
      : Argon2id(
          memory: kdfMemoryKib,
          iterations: kdfIterations,
          parallelism: kdfParallelism,
          hashLength: 32,
        );

  /// 密码最小长度（KDF 已足够慢，弱口令靠长度兜底一部分字典风险）。
  static const int minPasswordLength = 8;

  /// 校验密码是否可用（长度下限），返回错误文案；通过返回 null。
  static String? validatePassword(String password) {
    if (password.length < minPasswordLength) {
      return '密码至少 $minPasswordLength 位';
    }
    return null;
  }

  /// 加密 JSON 字符串，返回加密信封 JSON 字符串。
  static Future<String> encryptJson(String plainJson, String password) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final secretKey = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final box = await _aes.encrypt(
      utf8.encode(plainJson),
      secretKey: secretKey,
      nonce: nonce,
    );
    final envelope = <String, Object?>{
      'format': formatName,
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'encrypted': true,
      'enc': envelopeMagic,
      'kdf': {
        'algorithm': 'argon2id',
        'iterations': kdfIterations,
        'memory': kdfMemoryKib,
        'parallelism': kdfParallelism,
      },
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'cipherText': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
    return jsonEncode(envelope);
  }

  /// 解密加密信封 JSON 字符串。密码错误 / 数据被篡改抛出 [InvalidPasswordException]。
  static Future<String> decryptJson(
    String envelopeJson,
    String password,
  ) async {
    final dynamic decoded = jsonDecode(envelopeJson);
    if (decoded is! Map) {
      throw const FormatException('不是有效的备份文件');
    }
    final map = Map<String, Object?>.from(decoded);
    if (map['enc'] != envelopeMagic) {
      throw const FormatException('备份文件未加密，无需密码');
    }
    final salt = base64Decode(map['salt'] as String);
    final nonce = base64Decode(map['nonce'] as String);
    final cipherText = base64Decode(map['cipherText'] as String);
    final mac = base64Decode(map['mac'] as String);
    // 信封只信任固定参数的 Argon2id 派生，防止伪造 kdf 参数拖慢/绕过校验。
    final secretKey = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    try {
      final clear = await _aes.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: secretKey,
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const InvalidPasswordException();
    }
  }

  static List<int> _randomBytes(int length) =>
      List<int>.generate(length, (_) => _random.nextInt(256));
}

/// 密码错误或密文被篡改（GCM 认证失败）。
class InvalidPasswordException implements Exception {
  const InvalidPasswordException();

  @override
  String toString() => '密码错误，或备份文件已损坏';
}
