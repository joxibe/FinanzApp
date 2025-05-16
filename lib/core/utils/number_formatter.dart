import 'package:intl/intl.dart';

class NumberFormatter {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final formatted = formatter.format(amount);
    return formatted.startsWith('\$') ? formatted : '\$${formatted.replaceAll('\$', '')}';
  }

  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return formatter.format(number);
  }

  static String formatPercent(double number) {
    final formatter = NumberFormat.percentPattern('es_CO');
    return formatter.format(number / 100);
  }

  static String formatCurrencyWithCOP(double amount) {
    return '${formatCurrency(amount)} COP';
  }
} 