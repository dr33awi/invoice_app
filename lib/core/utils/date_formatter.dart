import 'package:intl/intl.dart';

/// Utility class for formatting dates
class DateFormatter {
  DateFormatter._();

  /// Format date as yyyy/MM/dd (English numbers)
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd', 'en').format(date);
  }

  /// Format date as dd/MM/yyyy (English numbers for compatibility)
  static String formatDateAr(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'en').format(date);
  }

  /// Format date with time (English numbers)
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm', 'en').format(date);
  }

  /// Format date with time (English numbers)
  static String formatDateTimeAr(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm', 'en').format(date);
  }

  /// Format as relative time (e.g., "منذ 5 دقائق")
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return formatDateAr(date);
    } else if (difference.inDays > 0) {
      return 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}';
    } else if (difference.inHours > 0) {
      return 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}';
    } else if (difference.inMinutes > 0) {
      return 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}';
    } else {
      return 'الآن';
    }
  }

  /// Format month and year (Arabic month names, English numbers)
  static String formatMonthYear(DateTime date) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Format time only (English numbers)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'en').format(date);
  }

  /// Format time with AM/PM (English numbers)
  static String formatTimeAmPm(DateTime date) {
    return DateFormat('hh:mm a', 'en').format(date);
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  /// Check if same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if today
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check if yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }
}
