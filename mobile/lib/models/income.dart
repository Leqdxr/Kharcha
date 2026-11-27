import 'expense.dart';

class Income {
  const Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.tdsAmount,
    required this.date,
  });

  final int id;
  final String title;
  final double amount;

  /// A key of [TaxSummary.types], e.g. 'salary' or 'service_pan'.
  final String type;
  final double tdsAmount;

  /// "YYYY-MM-DD"
  final String date;

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as int,
      title: json['title'] as String,
      amount: parseAmount(json['amount']),
      type: json['type'] as String,
      tdsAmount: parseAmount(json['tds_amount']),
      date: json['date'] as String,
    );
  }
}

/// One TDS rate from config/tax.php. [rate] is null for salary (typed in).
class IncomeType {
  const IncomeType({
    required this.label,
    required this.rate,
    required this.isFinal,
  });

  final String label;
  final double? rate;

  /// Final withholding: not counted in the yearly estimate.
  final bool isFinal;

  /// "15%", "1.5%", "6% final" or "slab"
  String get rateText {
    final value = rate;
    if (value == null) return 'slab';
    final pct = (value * 1000).round() / 10;
    final text = pct == pct.truncateToDouble() ? '${pct.toInt()}%' : '$pct%';
    return isFinal ? '$text final' : text;
  }
}

/// GET /tax/summary: income, TDS and the estimate for the fiscal year.
class TaxSummary {
  const TaxSummary({
    required this.fiscalYearLabel,
    required this.fiscalYearStart,
    required this.fiscalYearEnd,
    required this.types,
    required this.taxableIncome,
    required this.estimatedTax,
    required this.adjustableTdsYearEnd,
    required this.finalTds,
    required this.result,
    required this.slabsWithTax,
    required this.ssfContributor,
  });

  final String fiscalYearLabel;
  final String fiscalYearStart;
  final String fiscalYearEnd;

  /// Keyed by type, in the order of config/tax.php.
  final Map<String, IncomeType> types;
  final double taxableIncome;
  final double estimatedTax;
  final double adjustableTdsYearEnd;
  final double finalTds;

  /// Positive: you may get money back. Negative: you may still owe.
  final double result;

  /// How many slabs the income reaches (for "all in the 1% slab").
  final int slabsWithTax;
  final bool ssfContributor;

  factory TaxSummary.fromJson(Map<String, dynamic> json) {
    final fy = json['fiscal_year'] as Map<String, dynamic>;
    final types = json['types'] as Map<String, dynamic>;
    final slabs = json['slabs'] as List;
    return TaxSummary(
      fiscalYearLabel: fy['label'] as String,
      fiscalYearStart: fy['start'] as String,
      fiscalYearEnd: fy['end'] as String,
      types: {
        for (final MapEntry(:key, :value) in types.entries)
          key: IncomeType(
            label: (value as Map<String, dynamic>)['label'] as String,
            rate: (value['rate'] as num?)?.toDouble(),
            isFinal: value['final'] as bool,
          ),
      },
      taxableIncome: parseAmount(json['taxable_income']),
      estimatedTax: parseAmount(json['estimated_tax']),
      adjustableTdsYearEnd: parseAmount(json['adjustable_tds_year_end']),
      finalTds: parseAmount(json['final_tds']),
      result: parseAmount(json['result']),
      slabsWithTax: slabs
          .where((s) => parseAmount((s as Map<String, dynamic>)['taxable']) > 0)
          .length,
      ssfContributor: json['ssf_contributor'] as bool,
    );
  }
}
