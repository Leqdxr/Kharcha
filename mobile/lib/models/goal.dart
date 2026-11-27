import 'expense.dart';

/// A savings goal. Money moved into it is not an expense.
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.target,
    required this.saved,
    this.targetDate,
  });

  final int id;
  final String name;
  final double target;
  final double saved;

  /// "YYYY-MM-DD", or null for no deadline.
  final String? targetDate;

  /// 0 to 100.
  int get percent =>
      target > 0 ? (saved / target * 100).clamp(0, 100).round() : 0;

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as int,
      name: json['name'] as String,
      target: parseAmount(json['target']),
      saved: parseAmount(json['saved']),
      targetDate: json['target_date'] as String?,
    );
  }
}
