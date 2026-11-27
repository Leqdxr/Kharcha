import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../theme.dart';
import 'selection_bar.dart';

/// One expense in the day-grouped list: icon, title, "Food · eSewa · note",
/// amount.
/// Tap to edit, swipe left to delete, hold to start selecting. While
/// [selecting], a checkbox replaces the icon and a tap ticks the row.
/// [confirmDelete] asks first; [onDelete] runs only when the user confirms.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({
    super.key,
    required this.expense,
    required this.onTap,
    required this.confirmDelete,
    required this.onDelete,
    required this.onLongPress,
    this.selecting = false,
    this.selected = false,
  });

  final Expense expense;
  final VoidCallback onTap;
  final Future<bool> Function() confirmDelete;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final bool selecting;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(expense.amount);
    // "Food · eSewa · Repeats monthly · note"
    final sub = [
      expense.category,
      if (expense.paymentMethod != null)
        paymentMethodLabels[expense.paymentMethod] ?? expense.paymentMethod!,
      if (expense.recurringExpenseId != null) 'Repeats monthly',
      if (expense.note?.isNotEmpty ?? false) expense.note!,
    ].join(' · ');

    return Dismissible(
      key: ValueKey(expense.id),
      // No swiping while ticking rows.
      direction: selecting
          ? DismissDirection.none
          : DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(),
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
        selected: selecting ? selected : null,
        excludeSemantics: true,
        onLongPressHint: 'Select',
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete'): () async {
            if (await confirmDelete()) onDelete();
          },
        },
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selecting && selected ? AppColors.redTint : null,
              border: const Border(
                bottom: BorderSide(color: AppColors.rowLine),
              ),
            ),
            child: Row(
              children: [
                if (selecting)
                  SelectionCheck(selected: selected)
                else
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(amount, style: AppText.number(weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
