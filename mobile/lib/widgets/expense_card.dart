import 'package:flutter/semantics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../theme.dart';

/// One expense in the list. Swipe left to delete: [confirmDelete] asks the
/// user and calls the API, and returns true only if the delete worked.
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.confirmDelete,
    required this.onDeleted,
    this.onTap,
  });

  final Expense expense;
  final Future<bool> Function() confirmDelete;
  final VoidCallback onDeleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(expense.amount);
    final date = formatShortDate(expense.date);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(),
      onDismissed: (_) => onDeleted(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: GoogleFonts.onest(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.delete_outline, color: AppColors.white),
          ],
        ),
      ),
      // Swiping is invisible to screen readers, so offer the same action.
      child: Semantics(
        label: '${expense.title}, ${expense.category}, $date, $amount',
        excludeSemantics: true,
        button: onTap != null,
        customSemanticsActions: {
          const CustomSemanticsAction(label: 'Delete'): () async {
            if (await confirmDelete()) onDeleted();
          },
        },
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.onest(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              CategoryPill(expense.category),
                              Text(
                                date,
                                style: AppText.mono(
                                  size: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Takes at most 2/5 of the row; huge amounts shrink to fit.
                    Flexible(
                      flex: 2,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          amount,
                          style: AppText.mono(
                            size: 16,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey rounded label with the category name.
class CategoryPill extends StatelessWidget {
  const CategoryPill(this.category, {super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: GoogleFonts.onest(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF3D3835),
        ),
      ),
    );
  }
}
