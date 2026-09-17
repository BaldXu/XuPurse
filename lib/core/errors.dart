/// 领域异常体系。UI 层捕获后统一转为用户可读提示。
library;

/// 基础领域异常
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 业务规则校验失败（如同账本内账户重名）
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// 数据不存在
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// 第三方数据库解析失败
class ImportParseException extends AppException {
  const ImportParseException(super.message);
}

/// 导入被用户取消（预览阶段确认放弃等）
class ImportCancelledException extends AppException {
  const ImportCancelledException([super.message = '导入已取消']);
}
