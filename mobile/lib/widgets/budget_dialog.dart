import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/user.dart';
import '../services/api.dart';
import '../theme.dart';
import 'confirm_dialog.dart';
import 'form_fields.dart';

/// Opens the dialog to set or clear the monthly budget. Returns the updated
/// user after a successful PUT /budget, or null when closed.
Future<User?> showBudgetDialog(BuildContext context, int? budget) {
  return showDialog<User>(
    context: context,
    builder: (_) => _BudgetDialog(budget: budget),
  );
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({required this.budget});

  final int? budget;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  late final _amount = TextEditingController(
    text: widget.budget?.toString() ?? '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(int? budget) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final res = await Api.put('/budget', {'monthly_budget': budget});
    if (!mounted) return;
    switch (res) {
      case ApiSuccess(:final data):
        Navigator.of(context).pop(User.fromJson(data as Map<String, dynamic>));
      case ApiFailure(:final error):
        setState(() {
          _saving = false;
          _error = error.errors['monthly_budget'] ?? error.message;
        });
    }
  }

  Future<void> _remove() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Remove your monthly budget?',
      message: 'The budget bar will be hidden until you set a new one.',
      confirmLabel: 'Remove',
    );
    if (confirmed && mounted) await _save(null);
  }

  void _submit() {
    final text = _amount.text.trim();
    _save(text.isEmpty ? null : int.tryParse(text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text('Monthly budget'),
      content: LabeledTextField(
        label: 'Amount',
        controller: _amount,
        hint: 'e.g. 20000',
        prefixText: 'Rs. ',
        numberInput: true,
        error: _error,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if (widget.budget != null)
          TextButton(
            onPressed: _saving ? null : _remove,
            child: const Text('Remove'),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    );
  }
}
