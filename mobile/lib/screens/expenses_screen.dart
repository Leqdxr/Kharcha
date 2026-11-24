import 'dart:math' as math;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_storage.dart';
import '../theme.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_form.dart';
import '../widgets/logo.dart';
import '../widgets/summary_card.dart';
import 'login_screen.dart';

enum _Status { loading, ready, error }

const _filters = ['All', ...expenseCategories];

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  User? _user;
  List<Expense> _expenses = [];
  _Status _status = _Status.loading;
  String _errorMessage = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    AuthStorage.getUser().then((user) {
      if (mounted) setState(() => _user = user);
    });
    _load();
  }

  /// Loads the list. With [refresh] (pull to refresh) the current list stays
  /// on screen, and a failure only shows a snackbar.
  Future<void> _load({bool refresh = false}) async {
    if (!refresh) setState(() => _status = _Status.loading);

    final res = await Api.get('/expenses');
    if (!mounted) return;

    switch (res) {
      case ApiSuccess(:final data):
        setState(() {
          _expenses = [
            for (final json in data as List)
              Expense.fromJson(json as Map<String, dynamic>),
          ];
          _status = _Status.ready;
        });
      case ApiFailure(:final error):
        if (refresh && _status == _Status.ready) {
          _showSnackBar(error.message);
        } else {
          setState(() {
            _status = _Status.error;
            _errorMessage = error.isNetworkError
                ? error.message
                : 'Couldn’t load your expenses. ${error.message}';
          });
        }
    }
  }

  Future<void> _logOut() async {
    // Tell the backend to drop the token, but log out locally either way.
    await Api.post('/logout');
    await AuthStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _addExpense() async {
    final result = await showExpenseForm(context);
    if (result is! ExpenseSaved || !mounted) return;
    setState(() => _expenses = sortExpenses([..._expenses, result.expense]));
    _showSnackBar('Expense added');
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await showExpenseForm(context, expense: expense);
    if (!mounted) return;
    switch (result) {
      case ExpenseSaved(expense: final saved):
        setState(() {
          _expenses = sortExpenses([
            for (final e in _expenses) e.id == saved.id ? saved : e,
          ]);
        });
        _showSnackBar('Expense updated');
      case ExpenseDeleteRequested():
        if (await _confirmDelete(expense)) _removeExpense(expense);
      case null:
        break;
    }
  }

  /// Asks first, then calls DELETE. Returns true only if it was deleted.
  Future<bool> _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete this expense?'),
        content: Text(
          '"${expense.title}" (${formatMoney(expense.amount)}) will be '
          'removed. This can’t be undone.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    final res = await Api.delete('/expenses/${expense.id}');
    if (!mounted) return false;
    if (res case ApiFailure(:final error)) {
      _showSnackBar('Couldn’t delete the expense. ${error.message}');
      return false;
    }
    return true;
  }

  void _removeExpense(Expense expense) {
    if (!mounted) return;
    setState(() {
      _expenses = _expenses.where((e) => e.id != expense.id).toList();
    });
    _showSnackBar('Expense deleted');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Logo(),
        actions: [_accountMenu(), const SizedBox(width: 8)],
      ),
      floatingActionButton: _status == _Status.ready
          ? FloatingActionButton(
              tooltip: 'Add expense',
              onPressed: _addExpense,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: switch (_status) {
          _Status.loading => const Center(child: CircularProgressIndicator()),
          _Status.error => _errorState(),
          _Status.ready => _list(),
        },
      ),
    );
  }

  Widget _accountMenu() {
    final user = _user;
    return PopupMenuButton<String>(
      tooltip: user == null ? 'Account menu' : 'Account menu for ${user.name}',
      position: PopupMenuPosition.under,
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      onSelected: (value) {
        if (value == 'logout') _logOut();
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
                  style: GoogleFonts.onest(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  user.email,
                  style: GoogleFonts.onest(
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
            radius: 18,
            backgroundColor: const Color(0xFFEAE5DF),
            child: Text(
              user?.initials ?? '',
              style: GoogleFonts.onest(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5A544F),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppColors.muted,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.onest(
                fontSize: 16,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final thisMonth = toIsoDate(DateTime.now()).substring(0, 7);
    final monthExpenses = _expenses
        .where((e) => e.date.startsWith(thisMonth))
        .toList();
    final visible = _filter == 'All'
        ? _expenses
        : _expenses.where((e) => e.category == _filter).toList();

    // Keep the content readable on wide screens (landscape, tablets).
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(16.0, (width - 720) / 2);
    EdgeInsets pad(double top, double bottom) =>
        EdgeInsets.fromLTRB(side, top, side, bottom);

    final List<Widget> items;
    if (_expenses.isEmpty) {
      items = [
        Padding(padding: pad(20, 0), child: _heading()),
        Padding(padding: pad(20, 32), child: _emptyState()),
      ];
    } else {
      items = [
        Padding(padding: pad(20, 0), child: _heading()),
        Padding(
          padding: pad(16, 0),
          child: SummaryCard(expenses: monthExpenses),
        ),
        const SizedBox(height: 12),
        _filterChips(side),
        if (visible.isEmpty)
          Padding(
            padding: pad(24, 24),
            child: Text(
              'No $_filter expenses yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.onest(color: AppColors.muted),
            ),
          ),
        for (final expense in visible)
          Padding(
            padding: pad(0, 10),
            child: ExpenseCard(
              key: ValueKey(expense.id),
              expense: expense,
              confirmDelete: () => _confirmDelete(expense),
              onDeleted: () => _removeExpense(expense),
              onTap: () => _editExpense(expense),
            ),
          ),
        // Room so the FAB doesn't cover the last card.
        const SizedBox(height: 88),
      ];
    }

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: items,
      ),
    );
  }

  Widget _heading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(currentMonthLabel(), style: AppText.eyebrow()),
        const SizedBox(height: 4),
        Text(
          'Your expenses',
          style: GoogleFonts.onest(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _filterChips(double side) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: side),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          return Center(
            child: ChoiceChip(
              label: Text(filter),
              selected: _filter == filter,
              onSelected: (_) => setState(() => _filter = filter),
            ),
          );
        },
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
            style: GoogleFonts.onest(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first one and your monthly total will show up here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.onest(
              fontSize: 15,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _addExpense,
            icon: const Icon(Icons.add),
            label: const Text('Add your first expense'),
          ),
        ],
      ),
    );
  }
}
