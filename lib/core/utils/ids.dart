import 'package:uuid/uuid.dart';

/// 统一 UUID v4 生成
const _uuid = Uuid();

String genId() => _uuid.v4();

/// 当前毫秒时间戳
int nowMs() => DateTime.now().millisecondsSinceEpoch;
