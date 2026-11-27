/// The parts of GET /summary?month=YYYY-MM the app uses. The month's own
/// total and categories are worked out from the loaded list, so they update
/// straight away on add, edit and delete.
class Summary {
  const Summary({
    required this.previousMonth,
    required this.previousTotal,
    required this.budget,
    required this.daysLeft,
  });

  /// "YYYY-MM"
  final String previousMonth;
  final double previousTotal;

  /// Monthly budget in rupees, or null when none is set.
  final int? budget;

  /// Days left in the month including today; null for other months.
  final int? daysLeft;

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      previousMonth: json['previous_month'] as String,
      previousTotal: (json['previous_total'] as num).toDouble(),
      budget: (json['budget'] as num?)?.toInt(),
      daysLeft: (json['days_left'] as num?)?.toInt(),
    );
  }
}
