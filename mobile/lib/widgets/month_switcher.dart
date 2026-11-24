import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../theme.dart';

/// ← November 2026 →. Next is disabled on the current month.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.fontSize = 17,
    this.fontWeight = FontWeight.w700,
  });

  /// The 1st of the shown month.
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final isCurrent = month == thisMonth();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          tooltip: 'Previous month',
          color: AppColors.inkSoft,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            formatMonth(month),
            style: GoogleFonts.onest(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: AppColors.ink,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          color: AppColors.inkSoft,
          disabledColor: const Color(0xFFC9C3BC),
          icon: const Icon(Icons.chevron_right),
          onPressed: isCurrent
              ? null
              : () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}
