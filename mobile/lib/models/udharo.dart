import 'expense.dart';

/// Money lent to a friend ('lent': they owe me) or borrowed ('borrowed': I
/// owe them). The API only lists unsettled entries.
class Udharo {
  const Udharo({
    required this.id,
    required this.person,
    required this.amount,
    required this.direction,
    required this.date,
    this.note,
  });

  final int id;
  final String person;
  final double amount;
  final String direction;

  /// "YYYY-MM-DD"
  final String date;
  final String? note;

  bool get isLent => direction == 'lent';

  factory Udharo.fromJson(Map<String, dynamic> json) {
    return Udharo(
      id: json['id'] as int,
      person: json['person'] as String,
      amount: parseAmount(json['amount']),
      direction: json['direction'] as String,
      date: json['date'] as String,
      note: json['note'] as String?,
    );
  }
}
