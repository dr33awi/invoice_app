/// Base Exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server exceptions (API, Firebase)
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Cache/Local storage exceptions
class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Network exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Authentication exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    super.code,
    this.fieldErrors,
  });
}
