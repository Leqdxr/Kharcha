import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';

import 'models/expense.dart';
import 'services/session.dart';

final _money = NumberFormat.decimalPattern('en_IN');
final _shortDate = DateFormat('d MMM');
final _longDate = DateFormat('d MMM yyyy');
final _monthShortYear = DateFormat('MMM yyyy');
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

/// BS month names as the designs spell them (the web uses the same list).
/// nepali_utils does the date conversion; only the names come from here.
const _bsMonths = [
  'Baisakh',
  'Jestha',
  'Asar',
  'Shrawan',
  'Bhadra',
  'Asoj',
  'Kartik',
  'Mangsir',
  'Poush',
  'Magh',
  'Falgun',
  'Chaitra',
];

/// "2026-11-26" -> "10 Mangsir 2083" (BS) or "26 Nov 2026" (AD), following
/// the calendar setting. Without the year: "10 Mangsir" or "26 Nov".
String formatDate(String date, {bool withYear = true}) {
  final d = DateTime.parse(date);
  if (calendar == 'bs') {
    final bs = d.toNepaliDateTime();
    final dayMonth = '${bs.day} ${_bsMonths[bs.month - 1]}';
    return withYear ? '$dayMonth ${bs.year}' : dayMonth;
  }
  return (withYear ? _longDate : _shortDate).format(d);
}

/// "2027-10-01" -> "Asoj 2084" (BS) or "Oct 2027" (AD).
String formatMonthYear(String date) {
  final d = DateTime.parse(date);
  if (calendar == 'bs') {
    final bs = d.toNepaliDateTime();
    return '${_bsMonths[bs.month - 1]} ${bs.year}';
  }
  return _monthShortYear.format(d);
}

/// DateTime(2026, 11) -> "15 Kartik – 14 Mangsir": the BS dates the AD
/// month covers.
String bsMonthRange(DateTime month) {
  String bs(DateTime d) {
    final n = d.toNepaliDateTime();
    return '${n.day} ${_bsMonths[n.month - 1]}';
  }

  return '${bs(month)} – ${bs(DateTime(month.year, month.month + 1, 0))}';
}

/// "2026-11-24" -> "Today · 24 Nov" or "22 Nov" (or the BS date)
String dayLabel(String date) {
  final label = formatDate(date, withYear: false);
  return date == toIsoDate(DateTime.now()) ? 'Today · $label' : label;
}

/// Whole days from today to [date]: 0 today, 1 tomorrow.
int daysUntil(String date) {
  final now = DateTime.now();
  return DateTime.parse(date)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
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
