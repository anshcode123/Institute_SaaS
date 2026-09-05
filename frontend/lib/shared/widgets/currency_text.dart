import 'package:intl/intl.dart';

/// INR-formatted currency string, e.g. 1000000.0 -> "₹10,00,000.00"
/// (Indian digit grouping, not Western thousands-grouping).
String formatCurrency(double amount, {String currency = 'INR'}) {
  final symbol = currency == 'INR' ? '₹' : '$currency ';
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: symbol, decimalDigits: 2);
  return formatter.format(amount);
}
