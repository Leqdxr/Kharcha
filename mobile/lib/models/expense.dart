/// Same list as Expense::CATEGORIES in the backend.
const expenseCategories = ['Food', 'Travel', 'Bills', 'Other'];

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final int id;
  final String title;
  final double amount;
  final String category;

  /// "YYYY-MM-DD", exactly as the API sends it.
  final String date;

  final String? note;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    return Expense(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: amount is num
          ? amount.toDouble()
          : double.tryParse('$amount') ?? 0,
      category: json['category'] as String,
      date: json['date'] as String,
      note: json['note'] as String?,
    );
  }
}
