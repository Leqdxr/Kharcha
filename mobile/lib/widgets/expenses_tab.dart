import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../models/summary.dart';
import '../models/user.dart';
import '../theme.dart';
import 'expense_row.dart';
import 'logo.dart';
import 'month_switcher.dart';
import 'summary_card.dart';

const _filters = ['All', ...expenseCategories];

/// The Expenses tab: logo and account menu, month switcher, the red total
/// card, category chips and the list grouped by day.
class ExpensesTab extends StatefulWidget {
  const ExpensesTab({
    super.key,
    required this.user,
    required this.month,
    required this.expenses,
    required this.summary,
    required this.onMonthChanged,
    required this.onRefresh,
    required this.onAdd,
    required this.onEdit,
    required this.confirmDelete,
    required this.onDelete,
    required this.onEditBudget,
    required this.onLogOut,
  });

  final User? user;
  final DateTime month;

  /// The month's expenses, newest first.
  final List<Expense> expenses;
  final Summary summary;
  final ValueChanged<DateTime> onMonthChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<Expense> onEdit;
  final Future<bool> Function(Expense) confirmDelete;
  final ValueChanged<Expense> onDelete;
  final VoidCallback onEditBudget;
  final VoidCallback onLogOut;

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

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(side, 12, side - 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Logo(size: 28), _accountMenu()],
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
                    total: widget.expenses.fold(0, (sum, e) => sum + e.amount),
                    summary: widget.summary,
                    onEditBudget: widget.onEditBudget,
                  ),
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

  Widget _accountMenu() {
    final user = widget.user;
    return PopupMenuButton<String>(
      tooltip: user == null ? 'Account menu' : 'Account menu for ${user.name}',
      position: PopupMenuPosition.under,
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      onSelected: (value) {
        if (value == 'logout') widget.onLogOut();
      },
      itemBuilder: (context) => [
        if (user != null)
          PopupMenuItem<String>(
            enabled: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        if (user != null) const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: AppColors.ink),
              SizedBox(width: 12),
              Text('Log out'),
            ],
          ),
        ),
      ],
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.redTint,
            child: Text(
              user?.initials ?? '',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.redDark,
              ),
            ),
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
