import 'expense.dart';

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.monthlyBudget,
    this.calendar = 'bs',
    this.ssfContributor = false,
    this.fiscalYearView = true,
    this.paymentMethods = paymentMethodKeys,
  });

  final int id;
  final String name;
  final String email;

  /// Rupees per month, or null when no budget is set.
  final int? monthlyBudget;

  /// How dates are shown: 'bs' (Bikram Sambat) or 'ad'.
  final String calendar;

  /// SSF contributors don't pay the 1% Social Security Tax.
  final bool ssfContributor;

  /// On: the Tax tab lists the Nepali fiscal year (Shrawan to Asar).
  /// Off: the calendar year. The estimate always uses the fiscal year.
  final bool fiscalYearView;

  /// The payment methods shown as chips when adding an expense.
  final List<String> paymentMethods;

  factory User.fromJson(Map<String, dynamic> json) {
    final methods = json['payment_methods'];
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      monthlyBudget: (json['monthly_budget'] as num?)?.toInt(),
      calendar: json['calendar'] as String? ?? 'bs',
      ssfContributor: json['ssf_contributor'] as bool? ?? false,
      fiscalYearView: json['fiscal_year_view'] as bool? ?? true,
      paymentMethods: methods is List
          ? [for (final m in methods) '$m']
          : paymentMethodKeys,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'monthly_budget': monthlyBudget,
    'calendar': calendar,
    'ssf_contributor': ssfContributor,
    'fiscal_year_view': fiscalYearView,
    'payment_methods': paymentMethods,
  };

  /// Up to two letters, e.g. "Aagaman Koirala" -> "AK".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}
