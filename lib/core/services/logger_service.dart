import 'package:flutter/foundation.dart';

/// مستويات التسجيل
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// خدمة التسجيل المركزية
/// تستبدل print() في كل التطبيق
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // الحد الأدنى لمستوى التسجيل (يمكن تغييره)
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// تعيين الحد الأدنى لمستوى التسجيل
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// تسجيل رسالة debug
  void debug(String message, {String? tag, Object? error}) {
    _log(LogLevel.debug, message, tag: tag, error: error);
  }

  /// تسجيل رسالة info
  void info(String message, {String? tag, Object? error}) {
    _log(LogLevel.info, message, tag: tag, error: error);
  }

  /// تسجيل رسالة warning
  void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// تسجيل رسالة error
  void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;

    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final levelEmoji = _getLevelEmoji(level);
    final tagStr = tag != null ? '[$tag] ' : '';

    final logMessage = '$levelEmoji $timestamp $tagStr$message';

    // استخدام debugPrint بدلاً من print للأداء الأفضل
    debugPrint(logMessage);

    if (error != null) {
      debugPrint('   Error: $error');
    }

    if (stackTrace != null) {
      debugPrint('   StackTrace: $stackTrace');
    }
  }

  String _getLevelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }
}

/// اختصار للوصول السريع للـ Logger
final logger = LoggerService();
