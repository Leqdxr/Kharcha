/// Same list as Expense::CATEGORIES in the backend.
const expenseCategories = ['Food', 'Travel', 'Bills', 'Other'];

/// Same list as User::PAYMENT_METHODS in the backend.
const paymentMethodKeys = [
  'cash',
  'esewa',
  'khalti',
  'bank_card',
  'mobile_banking',
];

const paymentMethodLabels = {
  'cash': 'Cash',
  'esewa': 'eSewa',
  'khalti': 'Khalti',
  'bank_card': 'Bank card',
  'mobile_banking': 'Mobile banking',
};

double parseAmount(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.note,
    this.recurringExpenseId,
  });

  final int id;
  final String title;
  final double amount;
  final String category;

  /// "YYYY-MM-DD", exactly as the API sends it.
  final String date;

  /// One of [paymentMethodKeys], or null.
  final String? paymentMethod;

  final String? note;

  /// Set when the expense repeats every month (made by, or started, a rule).
  final int? recurringExpenseId;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: parseAmount(json['amount']),
      category: json['category'] as String,
      date: json['date'] as String,
      paymentMethod: json['payment_method'] as String?,
      note: json['note'] as String?,
      recurringExpenseId: json['recurring_expense_id'] as int?,
    );
  }
}

/// A monthly repeating bill (GET /recurring-expenses).
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.nextDate,
  });

  final int id;
  final String title;
  final double amount;
  final String category;

  /// "YYYY-MM-DD" of the next bill.
  final String nextDate;

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: parseAmount(json['amount']),
      category: json['category'] as String,
      nextDate: json['next_date'] as String,
    );
  }
}
