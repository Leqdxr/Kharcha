import 'package:intl/intl.dart';

import 'models/expense.dart';

final _money = NumberFormat.decimalPattern('en_IN');
final _shortDate = DateFormat('d MMM');
final _longDate = DateFormat('d MMM yyyy');
final _monthYear = DateFormat('MMMM yyyy');

/// 234000 -> "Rs. 2,34,000"
String formatMoney(num amount) => 'Rs. ${_money.format(amount)}';

/// "2026-11-24" -> "24 Nov"
String formatShortDate(String date) => _shortDate.format(DateTime.parse(date));

/// "2026-11-24" -> "24 Nov 2026"
String formatLongDate(String date) => _longDate.format(DateTime.parse(date));

/// "NOVEMBER 2026"
String currentMonthLabel() => _monthYear.format(DateTime.now()).toUpperCase();

/// A date as "YYYY-MM-DD", the format the API uses.
String toIsoDate(DateTime d) {
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$month-$day';
}

/// Newest first, same order as GET /expenses.
List<Expense> sortExpenses(Iterable<Expense> expenses) {
  return expenses.toList()..sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : b.id.compareTo(a.id);
  });
}
