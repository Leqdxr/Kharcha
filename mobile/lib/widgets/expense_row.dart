import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../theme.dart';

/// One expense in the day-grouped list: icon, title, "Food · note", amount.
/// Tap to edit, swipe left to delete (the screen shows an Undo snackbar).
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(expense.amount);
    final note = expense.note;
    final sub = note == null || note.isEmpty
        ? expense.category
        : '${expense.category} · $note';

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.red,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      // Swiping is invisible to screen readers, so offer the same action.
      child: Semantics(
        label: '${expense.title}, $sub, $amount',
        button: true,
        excludeSemantics: true,
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete'): onDelete,
        },
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.rowLine)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcons[expense.category],
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.onest(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.onest(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(amount, style: AppText.mono(weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
