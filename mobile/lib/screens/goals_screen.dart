import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/goal.dart';
import '../services/api.dart';
import '../theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/form_fields.dart';

/// Savings goals: progress, what to save each month, quick + Rs. 500,
/// "Add money" and new goals. Money in goals is not an expense.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<Goal>? _goals;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Api.get('/goals');
    if (!mounted) return;
    switch (res) {
      case ApiSuccess(data: final List rows):
        setState(() {
          _error = null;
          _goals = [
            for (final g in rows) Goal.fromJson(g as Map<String, dynamic>),
          ];
        });
      case ApiSuccess():
        break;
      case ApiFailure(:final error):
        setState(() => _error = error.message);
    }
  }

  Future<void> _deposit(Goal goal, num amount) async {
    final res = await Api.post('/goals/${goal.id}/deposit', {'amount': amount});
    if (!mounted) return;
    switch (res) {
      case ApiSuccess():
        _load();
        _showSnackBar('Added ${formatMoney(amount)} to ${goal.name}');
      case ApiFailure(:final error):
        _showSnackBar('Couldn’t add money. ${error.message}');
    }
  }

  Future<void> _addMoney(Goal goal) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => _AmountDialog(goalName: goal.name),
    );
    if (amount != null) await _deposit(goal, amount);
  }

  Future<void> _delete(Goal goal) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this goal?',
      message:
          '“${goal.name}” and the ${formatMoney(goal.saved)} saved in it will be removed from Kharcha.',
    );
    if (!confirmed || !mounted) return;
    final res = await Api.delete('/goals/${goal.id}');
    if (!mounted) return;
    if (res case ApiFailure(:final error)) {
      _showSnackBar('Couldn’t delete it. ${error.message}');
    }
    _load();
  }

  Future<void> _newGoal() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (_) => const _GoalForm(),
    );
    if (saved == true && mounted) _load();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final goals = _goals;
    return Scaffold(
      appBar: AppBar(title: const Text('Savings goals')),
      body: goals == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(
                      onPressed: _load,
                      child: Text('Couldn’t load goals. $_error Try again.'),
                    ),
            )
          : RefreshIndicator(
              color: AppColors.red,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  _totalCard(goals),
                  const SizedBox(height: 14),
                  for (final goal in goals) ...[
                    _goalCard(goal),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _newGoal,
                    icon: const Icon(Icons.add),
                    label: const Text('New goal'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _totalCard(List<Goal> goals) {
    final total = goals.fold(0.0, (sum, g) => sum + g.saved);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved across all goals',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
          Text(
            formatMoney(total),
            style: AppText.number(size: 26, weight: FontWeight.w600),
          ),
          Text(
            'Money in goals is not counted as spending.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  /// "Save Rs. X a month to make it", rounded up to the nearest 10. With no
  /// date "Rs. X to go"; when reached "Goal reached".
  String _tip(Goal goal) {
    final left = goal.target - goal.saved;
    if (left <= 0) return 'Goal reached';
    final date = goal.targetDate;
    if (date == null) return '${formatMoney(left)} to go';
    final now = DateTime.now();
    final target = DateTime.parse(date);
    final months = (target.year - now.year) * 12 + target.month - now.month;
    final perMonth = (left / (months < 1 ? 1 : months) / 10).ceil() * 10;
    return 'Save ${formatMoney(perMonth)} a month to make it';
  }

  Widget _goalCard(Goal goal) {
    final when = goal.targetDate == null
        ? 'no deadline'
        : 'by ${formatMonthYear(goal.targetDate!)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                when,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
              ),
              PopupMenuButton<String>(
                tooltip: 'More for ${goal.name}',
                color: AppColors.white,
                onSelected: (value) => switch (value) {
                  'add' => _addMoney(goal),
                  _ => _delete(goal),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'add', child: Text('Add money')),
                  PopupMenuItem(value: 'delete', child: Text('Delete goal')),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatMoney(goal.saved),
                      style: AppText.number(size: 20, weight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'of ${formatNumber(goal.target)} · ${goal.percent}%',
                      style: AppText.number(size: 13, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: '${goal.name} progress',
                  value: '${goal.percent}%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.percent / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.surface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tip(goal),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => _deposit(goal, 500),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 40),
                      ),
                      child: const Text('+ Rs. 500'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Add money": any amount into a goal.
class _AmountDialog extends StatefulWidget {
  const _AmountDialog({required this.goalName});

  final String goalName;

  @override
  State<_AmountDialog> createState() => _AmountDialogState();
}

class _AmountDialogState extends State<_AmountDialog> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount < 1) {
      setState(() => _error = 'Enter an amount of at least Rs. 1.');
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      title: Text('Add money to ${widget.goalName}'),
      content: LabeledTextField(
        label: 'Amount',
        controller: _amount,
        prefixText: 'Rs. ',
        numberInput: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        error: _error,
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

/// New goal: name, target and an optional date.
class _GoalForm extends StatefulWidget {
  const _GoalForm();

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  DateTime? _date;
  bool _saving = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _errors = {};
      _formError = null;
    });
    final res = await Api.post('/goals', {
      'name': _name.text.trim(),
      'target': _target.text.trim(),
      'target_date': _date == null ? null : toIsoDate(_date!),
    });
    if (!mounted) return;
    switch (res) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() {
          _saving = false;
          _errors = error.errors;
          _formError = error.errors.isEmpty ? error : null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _date;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New goal',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Name',
              controller: _name,
              hint: 'e.g. Dashain and Tihar fund',
              error: _errors['name'],
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Target',
              controller: _target,
              prefixText: 'Rs. ',
              numberInput: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              error: _errors['target'],
            ),
            const SizedBox(height: 16),
            const FieldLabel('Target date (optional)'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      date == null
                          ? 'No deadline'
                          : formatDate(toIsoDate(date)),
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    tooltip: 'Remove the date',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _date = null),
                  ),
              ],
            ),
            if (_errors['target_date'] != null)
              ErrorMessage(_errors['target_date']!),
            if (_formError != null) ...[
              const SizedBox(height: 16),
              FormErrorBox(
                message: _formError!.message,
                onRetry: _formError!.isNetworkError ? _submit : null,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save goal',
              loadingLabel: 'Saving…',
              loading: _saving,
              onPressed: _submit,
              height: 52,
              radius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
