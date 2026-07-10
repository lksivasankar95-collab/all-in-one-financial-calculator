import 'package:intl/intl.dart';

class NumberFormatter {
  NumberFormatter._();

  static String formatCurrency(double value, {String symbol = '₹', int decimals = 2}) {
    if (value.abs() >= 10000000) {
      return '$symbol${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value.abs() >= 100000) {
      return '$symbol${(value / 100000).toStringAsFixed(2)} L';
    } else if (value.abs() >= 1000) {
      final formatter = NumberFormat('#,##,##0.##');
      return '$symbol${formatter.format(value)}';
    }
    return '$symbol${value.toStringAsFixed(decimals)}';
  }

  static String formatCurrencyFull(double value, {String symbol = '₹'}) {
    final formatter = NumberFormat('#,##,##0.##');
    return '$symbol${formatter.format(value)}';
  }

  static String formatCompact(double value, {String symbol = '₹'}) {
    if (value.abs() >= 10000000) {
      return '$symbol${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value.abs() >= 100000) {
      return '$symbol${(value / 100000).toStringAsFixed(2)} L';
    } else if (value.abs() >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(2)} K';
    }
    return '$symbol${value.toStringAsFixed(2)}';
  }

  static String formatPercent(double value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  static String formatNumber(double value, {int decimals = 2}) {
    final formatter = NumberFormat('#,##,##0.##');
    if (value == value.truncateToDouble()) {
      return NumberFormat('#,##,##0').format(value);
    }
    return formatter.format(value);
  }

  static String formatInteger(int value) {
    return NumberFormat('#,##,##0').format(value);
  }

  static String formatMonths(int months) {
    if (months < 12) return '$months months';
    final years = months ~/ 12;
    final rem = months % 12;
    if (rem == 0) return '$years ${years == 1 ? "year" : "years"}';
    return '$years ${years == 1 ? "year" : "years"} $rem ${rem == 1 ? "month" : "months"}';
  }

  static double? tryParse(String text) {
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }
}
