import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  return formatter.format(amount);
}

String formatDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) return 'Today';
  if (date.year == now.year && date.month == now.month && date.day == now.day - 1) return 'Yesterday';
  return DateFormat('MMM dd, yyyy').format(date);
}

String formatMonthYear(DateTime date) {
  return DateFormat('MMMM yyyy').format(date);
}