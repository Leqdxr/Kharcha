import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/summary.dart';
import '../theme.dart';
import 'expense_row.dart';
import 'logo.dart';
import 'month_switcher.dart';
import 'summary_card.dart';

const _filters = ['All', ...expenseCategories];

/// The Expenses tab: logo and settings gear, month switcher, the red total
/// card, safe to spend today, upcoming bills, the first savings goal,
/// category chips and the list grouped by day.
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({
    super.key,
    required this.month,
    required this.expenses,
    required this.summary,
    required this.bills,
    required this.goals,
    required this.onMonthChanged,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.confirmDelete,
    required this.onDelete,
    required this.onEditBudget,
    required this.onOpenSettings,
    required this.onOpenGoals,
  });

  final DateTime month;

  /// The month's expenses, newest first.
  final List<Expense> expenses;
  final Summary summary;

  /// Repeating bills, next one first.
  final List<RecurringExpense> bills;
  final List<Goal> goals;
  final ValueChanged<DateTime> onMonthChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<Expense> onEdit;
  final Future<bool> Function(Expense) confirmDelete;
  final ValueChanged<Expense> onDelete;
  final VoidCallback onEditBudget;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGoals;

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    // Keep the content readable on wide screens (landscape, tablets).
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(20.0, (width - 720) / 2);
    final total = widget.expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(side, 12, side - 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Logo(size: 28),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
                color: AppColors.inkSoft,
                onPressed: widget.onOpenSettings,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: side - 8),
          child: MonthSwitcher(
            month: widget.month,
            onChanged: widget.onMonthChanged,
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.red,
            onRefresh: widget.onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 4, bottom: 120),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  child: SummaryCard(
                    month: widget.month,
                    total: total,
                    summary: widget.summary,
                    onEditBudget: widget.onEditBudget,
                  ),
                ),
                if (_safeToSpend(total) case final card?)
                  Padding(
                    padding: EdgeInsets.fromLTRB(side, 14, side, 0),
                    child: card,
                  ),
                if (widget.bills.isNotEmpty) ..._upcomingBills(side),
                Padding(
                  padding: EdgeInsets.fromLTRB(side, 14, side, 0),
                  child: _goalCard(),
                ),
                if (widget.expenses.isEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(side, 20, side, 0),
                    child: _emptyState(),
                  )
                else ...[
                  _chips(side),
                  ..._groups(side),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _groups(double side) {
    final shown = _filter == 'All'
        ? widget.expenses
        : widget.expenses.where((e) => e.category == _filter).toList();

    if (shown.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.fromLTRB(side, 24, side, 0),
          child: Text(
            'No $_filter expenses this month.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.muted),
          ),
        ),
      ];
    }

    // Consecutive expenses with the same date form one day group.
    final days = <List<Expense>>[];
    for (final expense in shown) {
      if (days.isNotEmpty && days.last.first.date == expense.date) {
        days.last.add(expense);
      } else {
        days.add([expense]);
      }
    }

    final headerStyle = GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.muted,
    );

    return [
      for (final day in days) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(side, 14, side, 6),
          child: Semantics(
            header: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayLabel(day.first.date), style: headerStyle),
                Text(
                  formatMoney(day.fold<double>(0, (sum, e) => sum + e.amount)),
                  style: AppText.number(
                    size: 13,
                    weight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final expense in day)
          Padding(
            key: ValueKey(expense.id),
            padding: EdgeInsets.symmetric(horizontal: side),
            child: ExpenseRow(
              expense: expense,
              onTap: () => widget.onEdit(expense),
              confirmDelete: () => widget.confirmDelete(expense),
              onDelete: () => widget.onDelete(expense),
            ),
          ),
      ],
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'Swipe left on an expense to delete it',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
        ),
      ),
    ];
  }

  Widget _chips(double side) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(side, 8, side, 0),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final selected = _filter == filter;
          return Center(
            child: ChoiceChip(
              label: Text(filter),
              // Set here: the chip ignores a state-based labelStyle in the
              // theme, which left the unselected labels white on white.
              labelStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.white : AppColors.ink,
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filter = filter),
            ),
          );
        },
      ),
    );
  }

  /// (Budget left) / (days left including today). Only for the current
  /// month with a budget; over budget it says by how much instead.
  Widget? _safeToSpend(double total) {
    final budget = widget.summary.budget;
    final daysLeft = widget.summary.daysLeft;
    if (budget == null || daysLeft == null || daysLeft < 1) return null;
    final left = budget - total;
    final over = left < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.redTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              over ? Icons.warning_amber_rounded : Icons.savings_outlined,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  over ? 'Over budget by' : 'Safe to spend today',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  formatMoney(over ? -left : (left / daysLeft).round()),
                  style: AppText.number(size: 22, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left\nthis month',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  /// The next three repeating bills, with the date and "in N days".
  List<Widget> _upcomingBills(double side) {
    final small = GoogleFonts.inter(fontSize: 12, color: AppColors.muted);
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(side, 18, side, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Upcoming bills',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Repeat every month',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
      ),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: side),
          itemCount: math.min(3, widget.bills.length),
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final bill = widget.bills[i];
            final days = daysUntil(bill.nextDate);
            final when = switch (days) {
              <= 0 => 'today',
              1 => 'tomorrow',
              _ => 'in $days days',
            };
            return Container(
              width: 150,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(bill.amount),
                    style: AppText.number(size: 16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDate(bill.nextDate, withYear: false)} · $when',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: small,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ];
  }

  /// The first goal's progress, or a link to start one. Opens Goals.
  Widget _goalCard() {
    final goal = widget.goals.firstOrNull;
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: widget.onOpenGoals,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: goal == null
                    ? Text(
                        'Start a savings goal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  goal.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '${goal.percent}%',
                                style: AppText.number(
                                  size: 14,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: goal.percent / 100,
                              minHeight: 6,
                              backgroundColor: AppColors.surface,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/images/money.svg',
            height: 170,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 24),
          Text(
            'No expenses yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first one and your monthly total will show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add your first expense'),
          ),
        ],
      ),
    );
  }
}
