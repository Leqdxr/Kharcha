import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/summary.dart';
import '../theme.dart';

/// The red card: "Spent in November", the total, the comparison with last
/// month and the budget bar. Tapping the budget part opens the budget dialog.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.month,
    required this.total,
    required this.summary,
    required this.onEditBudget,
  });

  final DateTime month;

  /// Total of the month's expenses (without one waiting to be deleted).
  final double total;
  final Summary summary;
  final VoidCallback onEditBudget;

  @override
  Widget build(BuildContext context) {
    final small = GoogleFonts.inter(fontSize: 13, color: AppColors.redTint);
    final pct = percentChange(total, summary.previousTotal);
    final previousName = formatMonthName(parseMonth(summary.previousMonth));

    final IconData compareIcon;
    final String compareText;
    if (pct == null) {
      compareIcon = Icons.remove;
      compareText = 'First month of data';
    } else {
      compareIcon = pct <= 0 ? Icons.arrow_downward : Icons.arrow_upward;
      compareText =
          '${pct.abs()}% ${pct <= 0 ? 'less' : 'more'} than $previousName';
    }

    // Material (not a Container) so the budget's tap ripple shows on the red.
    return Material(
      color: AppColors.red,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Spent in ${formatMonthName(month)}', style: small),
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
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(compareIcon, size: 14, color: AppColors.white),
                const SizedBox(width: 4),
                Text(
                  compareText,
                  style: small.copyWith(color: AppColors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _budget(small),
          ],
        ),
      ),
    );
  }

  Widget _budget(TextStyle small) {
    final budget = summary.budget;

    if (budget == null) {
      return Semantics(
        button: true,
        child: InkWell(
          onTap: onEditBudget,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  'Set a monthly budget',
                  style: small.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final left = budget - total;
    final used = budget > 0 ? total / budget : (total > 0 ? 1.0 : 0.0);
    final usedPct = (used * 100).round();
    final note = left >= 0
        ? '$usedPct% of ${formatMoney(budget)} budget · ${formatMoney(left)} left'
        : '${formatMoney(-left)} over budget';

    return Semantics(
      button: true,
      label: 'Monthly budget. $note. Tap to edit.',
      excludeSemantics: true,
      child: InkWell(
        onTap: onEditBudget,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: used.clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: AppColors.redDark,
                  color: left >= 0 ? AppColors.white : AppColors.redTint,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text(note, style: small)),
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.redTint,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
