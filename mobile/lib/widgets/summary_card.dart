import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../theme.dart';

/// The red "Spent this month" card, with the entry count and the biggest
/// category underneath. Pass only this month's expenses.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    MapEntry<String, double>? biggest;
    for (final entry in byCategory.entries) {
      if (biggest == null || entry.value > biggest.value) biggest = entry;
    }

    final labelStyle = GoogleFonts.onest(
      fontSize: 13,
      color: AppColors.white.withValues(alpha: 0.8),
    );
    final valueStyle = GoogleFonts.onest(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: AppColors.white,
    );
    final count = expenses.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spent this month', style: labelStyle.copyWith(fontSize: 14)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(total),
              style: AppText.mono(
                size: 32,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: AppColors.white.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Entries',
                  value: Text('$count', style: valueStyle),
                  labelStyle: labelStyle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _Stat(
                  label: 'Biggest category',
                  labelStyle: labelStyle,
                  value: biggest == null
                      ? Text('None yet', style: valueStyle)
                      : Text.rich(
                          TextSpan(
                            text: '${biggest.key}  ',
                            style: valueStyle,
                            children: [
                              TextSpan(
                                text: formatMoney(biggest.value),
                                style: AppText.mono(
                                  size: 13,
                                  color: AppColors.white.withValues(
                                    alpha: 0.85,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.labelStyle,
  });

  final String label;
  final Widget value;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}
