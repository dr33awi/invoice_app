/// Base Failure class for handling errors
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server-related failures (API, Firebase)
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Cache/Local storage failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    super.message, {
    super.code,
    this.fieldErrors,
  });
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.code});
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.code});
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'حدث خطأ غير متوقع']) : super(message);
}
