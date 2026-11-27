import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/summary.dart';
import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_storage.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/expense_form.dart';
import '../widgets/expenses_tab.dart';
import '../widgets/insights_tab.dart';
import '../widgets/tax_tab.dart';
import '../widgets/udharo_tab.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';

enum _Status { loading, ready, error }

/// The logged-in app: Expenses, Insights, Udharo and Tax tabs with a bottom
/// bar and a red + button that adds the tab's own thing. Holds the month's
/// data for the Expenses and Insights tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _month = thisMonth();
  List<Expense> _expenses = [];
  Summary? _summary;
  List<RecurringExpense> _bills = [];
  List<Goal> _goals = [];
  _Status _status = _Status.loading;
  String _errorMessage = '';
  int _tab = 0;
  final _udharoTab = GlobalKey<UdharoTabState>();
  final _taxTab = GlobalKey<TaxTabState>();

  /// Reloads when the app comes back to the front, so changes made on the
  /// web (a stopped repeat, a new expense) show up here.
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Dates follow the calendar setting, so redraw when the user changes.
    currentUser.addListener(_onUserChanged);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_status == _Status.ready) _load(refresh: true);
      },
    );
    _loadUser();
    _load();
  }

  @override
  void dispose() {
    currentUser.removeListener(_onUserChanged);
    _lifecycle.dispose();
    super.dispose();
  }

  void _onUserChanged() => setState(() {});

  /// The saved copy first, then the latest settings from the API.
  Future<void> _loadUser() async {
    final saved = await AuthStorage.getUser();
    if (saved != null) currentUser.value = saved;
    if (await Api.get('/user') case ApiSuccess(
      data: final Map<String, dynamic> json,
    )) {
      await setCurrentUser(User.fromJson(json));
    }
  }

  /// Loads the month's expenses and summary. With [refresh] (pull to
  /// refresh) the current data stays on screen and a failure only shows a
  /// snackbar.
  Future<void> _load({bool refresh = false}) async {
    if (!refresh) setState(() => _status = _Status.loading);

    final month = monthKey(_month);
    final [list, summary, bills, goals] = await Future.wait([
      Api.get('/expenses?month=$month'),
      Api.get('/summary?month=$month'),
      Api.get('/recurring-expenses'),
      Api.get('/goals'),
    ]);
    if (!mounted) return;

    if (list case ApiSuccess(data: final List data)) {
      if (summary case ApiSuccess(data: final Map<String, dynamic> json)) {
        setState(() {
          _expenses = [
            for (final e in data) Expense.fromJson(e as Map<String, dynamic>),
          ];
          _summary = Summary.fromJson(json);
          // Bills and goals are extras: keep the old ones if they fail.
          if (bills case ApiSuccess(data: final List rows)) {
            _bills = [
              for (final r in rows)
                RecurringExpense.fromJson(r as Map<String, dynamic>),
            ];
          }
          if (goals case ApiSuccess(data: final List rows)) {
            _goals = [
              for (final g in rows) Goal.fromJson(g as Map<String, dynamic>),
            ];
          }
          _status = _Status.ready;
        });
        return;
      }
    }

    final error = [list, summary].whereType<ApiFailure>().firstOrNull?.error;
    final message = error?.message ?? 'Something went wrong. Try again.';
    if (refresh && _status == _Status.ready) {
      _showSnackBar(message);
    } else {
      setState(() {
        _status = _Status.error;
        _errorMessage = error?.isNetworkError ?? false
            ? message
            : 'Couldn’t load your expenses. $message';
      });
    }
  }

  void _changeMonth(DateTime month) {
    setState(() => _month = month);
    _load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
    // The budget or goals may have changed there.
    if (mounted) _load(refresh: true);
  }

  Future<void> _openGoals() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const GoalsScreen()));
    if (mounted) _load(refresh: true);
  }

  Future<void> _addExpense() async {
    final result = await showExpenseForm(context);
    if (result is! ExpenseSaved || !mounted) return;
    final expense = result.expense;
    // Added to another month: show that month.
    if (!expense.date.startsWith(monthKey(_month))) {
      _changeMonth(parseMonth(expense.date.substring(0, 7)));
    } else if (result.repeatChanged) {
      // A new repeat may have added bills for this and earlier months.
      _load(refresh: true);
    } else {
      setState(() => _expenses = sortExpenses([..._expenses, expense]));
    }
    _showSnackBar('Expense added');
  }

  Future<void> _editExpense(Expense expense) async {
    final result = await showExpenseForm(context, expense: expense);
    if (!mounted) return;
    switch (result) {
      case ExpenseSaved(repeatChanged: true):
        _load(refresh: true);
        _showSnackBar('Expense updated');
      case ExpenseSaved(expense: final saved):
        final others = _expenses.where((e) => e.id != saved.id);
        setState(() {
          // Moved to another month: it leaves this list.
          _expenses = saved.date.startsWith(monthKey(_month))
              ? sortExpenses([...others, saved])
              : others.toList();
        });
        _showSnackBar('Expense updated');
      case ExpenseDeleteRequested():
        if (await _confirmDelete(expense) && mounted) _deleteExpense(expense);
      case null:
        break;
    }
  }

  Future<bool> _confirmDelete(Expense expense) {
    return confirmDelete(
      context,
      title: 'Delete this expense?',
      message:
          '“${expense.title}” (${formatMoney(expense.amount)}) will be deleted.',
    );
  }

  /// Called after "Delete this expense?" is confirmed. The row leaves the
  /// list straight away (a swiped row must), and comes back if the DELETE
  /// fails.
  Future<void> _deleteExpense(Expense expense) async {
    setState(() {
      _expenses = _expenses.where((e) => e.id != expense.id).toList();
    });
    final res = await Api.delete('/expenses/${expense.id}');
    if (!mounted) return;
    switch (res) {
      case ApiSuccess():
        _showSnackBar('Expense deleted');
        // Deleting a repeat's last expense stops the repeat, so the
        // upcoming bills can change.
        if (expense.recurringExpenseId != null) _load(refresh: true);
      case ApiFailure(:final error):
        setState(() => _expenses = sortExpenses([..._expenses, expense]));
        _showSnackBar('Couldn’t delete “${expense.title}”. ${error.message}');
    }
  }

  Future<void> _editBudget() async {
    final user = await showBudgetDialog(context, _summary?.budget);
    if (user == null || !mounted) return;
    final summary = _summary!;
    setState(() {
      _summary = Summary(
        previousMonth: summary.previousMonth,
        previousTotal: summary.previousTotal,
        budget: user.monthlyBudget,
        daysLeft: summary.daysLeft,
      );
    });
    await setCurrentUser(user);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ready = _status == _Status.ready;
    return Scaffold(
      floatingActionButton: ready || _tab >= 2 ? _addButton() : null,
      bottomNavigationBar: _BottomBar(
        index: _tab,
        onChanged: (i) => setState(() => _tab = i),
      ),
      body: SafeArea(
        bottom: false,
        child: switch (_status) {
          // Udharo and Tax load their own data.
          _ when _tab == 2 => UdharoTab(key: _udharoTab),
          _ when _tab == 3 => TaxTab(key: _taxTab),
          _Status.loading => const Center(child: CircularProgressIndicator()),
          _Status.error => _errorState(),
          _Status.ready when _tab == 0 => ExpensesTab(
            month: _month,
            expenses: _expenses,
            summary: _summary!,
            bills: _bills,
            goals: _goals,
            onMonthChanged: _changeMonth,
            onRefresh: () => _load(refresh: true),
            onAdd: _addExpense,
            onEdit: _editExpense,
            confirmDelete: _confirmDelete,
            onDelete: _deleteExpense,
            onEditBudget: _editBudget,
            onOpenSettings: _openSettings,
            onOpenGoals: _openGoals,
          ),
          _Status.ready => InsightsTab(
            month: _month,
            expenses: _expenses,
            summary: _summary!,
            onMonthChanged: _changeMonth,
            onRefresh: () => _load(refresh: true),
          ),
        },
      ),
    );
  }

  /// Adds an expense, an udharo or an income, to fit the tab.
  Widget _addButton() {
    final (tooltip, onPressed) = switch (_tab) {
      2 => ('Add udharo', () => _udharoTab.currentState?.add()),
      3 => ('Add income', () => _taxTab.currentState?.add()),
      _ => ('Add expense', _addExpense),
    };
    return SizedBox.square(
      dimension: 60,
      child: FloatingActionButton(
        tooltip: tooltip,
        shape: const CircleBorder(),
        elevation: 6,
        onPressed: onPressed,
        child: const Icon(Icons.add, size: 28),
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
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.muted),
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
}

/// Expenses / Insights / Udharo / Tax, the active one in red.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (icon: Icons.receipt_long, label: 'Expenses'),
    (icon: Icons.bar_chart, label: 'Insights'),
    (icon: Icons.handshake_outlined, label: 'Udharo'),
    (icon: Icons.request_quote_outlined, label: 'Tax'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final (i, item) in _items.indexed)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    child: InkWell(
                      onTap: () => onChanged(i),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 22,
                            color: i == index ? AppColors.red : AppColors.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: i == index
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: i == index
                                  ? AppColors.red
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
