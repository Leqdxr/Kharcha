import 'package:intl/intl.dart';

import 'models/expense.dart';

final _money = NumberFormat.decimalPattern('en_IN');
final _shortDate = DateFormat('d MMM');
final _longDate = DateFormat('d MMM yyyy');
final _monthYear = DateFormat('MMMM yyyy');
final _monthName = DateFormat('MMMM');

/// 234000 -> "2,34,000"
String formatNumber(num amount) => _money.format(amount);

/// 234000 -> "Rs. 2,34,000"
String formatMoney(num amount) => 'Rs. ${formatNumber(amount)}';

/// Rounded percent change from [previous] to [current], e.g. -16 for 16% less.
/// Null when there is nothing to compare with.
int? percentChange(double current, double previous) {
  return previous > 0 ? ((current - previous) / previous * 100).round() : null;
}

/// "2026-11-24" -> "24 Nov"
String formatShortDate(String date) => _shortDate.format(DateTime.parse(date));

/// "2026-11-24" -> "24 Nov 2026"
String formatLongDate(String date) => _longDate.format(DateTime.parse(date));

/// "2026-11-24" -> "Today · 24 Nov" or "22 Nov"
String dayLabel(String date) {
  final label = formatShortDate(date);
  return date == toIsoDate(DateTime.now()) ? 'Today · $label' : label;
}

/// A month is kept as a DateTime on the 1st, e.g. DateTime(2026, 11).
DateTime thisMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

/// DateTime(2026, 11) -> "2026-11", the format the API uses.
String monthKey(DateTime month) => toIsoDate(month).substring(0, 7);

/// "2026-11" -> DateTime(2026, 11)
DateTime parseMonth(String key) => DateTime.parse('$key-01');

/// DateTime(2026, 11) -> "November 2026"
String formatMonth(DateTime month) => _monthYear.format(month);

/// DateTime(2026, 11) -> "November"
String formatMonthName(DateTime month) => _monthName.format(month);

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
