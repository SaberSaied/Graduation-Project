import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final Map<String, String> _symbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SAR': '﷼',
    'EGP': 'E£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'INR': '₹',
  };

  static String format(double amount, String currencyCode) {
    final formatter = NumberFormat('#,##0.00');
    final symbol = _symbols[currencyCode] ?? currencyCode;
    return '$symbol${formatter.format(amount)}';
  }

  static String formatCompact(double amount, String currencyCode) {
    final formatter = NumberFormat.compact();
    final symbol = _symbols[currencyCode] ?? currencyCode;
    return '$symbol${formatter.format(amount)}';
  }

  static String getSymbol(String currencyCode) {
    return _symbols[currencyCode] ?? currencyCode;
  }

  static String formatWithSign(double amount, String currencyCode, String type) {
    final formatted = format(amount.abs(), currencyCode);
    return type == 'INCOME' ? '+$formatted' : '-$formatted';
  }
}
