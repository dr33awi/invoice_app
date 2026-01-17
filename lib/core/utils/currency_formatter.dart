import 'package:intl/intl.dart';

/// Utility class for formatting currency values
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format USD amount with $ symbol
  static String formatUSD(double amount, {int decimals = 2}) {
    return '\$${amount.toStringAsFixed(decimals)}';
  }

  /// Format SYP amount with ل.س symbol
  static String formatSYP(double amount) {
    final formatter = NumberFormat('#,###', 'ar');
    return '${formatter.format(amount.round())} ل.س';
  }

  /// Format number with thousands separator (Arabic style)
  static String formatNumber(double value, {int decimals = 0}) {
    final formatter = NumberFormat('#,###', 'ar');
    if (decimals > 0) {
      return value.toStringAsFixed(decimals);
    }
    return formatter.format(value.round());
  }

  /// Format number with thousands separator (English style)
  static String formatNumberEn(double value, {int decimals = 0}) {
    final formatter = NumberFormat('#,###', 'en');
    if (decimals > 0) {
      return value.toStringAsFixed(decimals);
    }
    return formatter.format(value.round());
  }

  /// Convert USD to SYP
  static double usdToSyp(double usd, double exchangeRate) {
    return usd * exchangeRate;
  }

  /// Convert SYP to USD
  static double sypToUsd(double syp, double exchangeRate) {
    if (exchangeRate == 0) return 0;
    return syp / exchangeRate;
  }

  /// Format exchange rate display
  static String formatExchangeRate(double rate) {
    final formatter = NumberFormat('#,###', 'ar');
    return '1 USD = ${formatter.format(rate.round())} SYP';
  }

  /// Parse currency string to double
  static double? parse(String value) {
    // Remove currency symbols and separators
    final cleaned = value
        .replaceAll('\$', '')
        .replaceAll('ل.س', '')
        .replaceAll(',', '')
        .replaceAll('٬', '') // Arabic thousand separator
        .trim();

    return double.tryParse(cleaned);
  }
}
