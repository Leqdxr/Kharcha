import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../services/api.dart';
import '../theme.dart';
import 'form_fields.dart';

/// Opens the "Add expense" bottom sheet. Returns the created expense,
/// or null if the sheet was closed.
Future<Expense?> showExpenseForm(BuildContext context) {
  return showModalBottomSheet<Expense>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (_) => const ExpenseForm(),
  );
}

/// Title, amount, category and date. Saves through the API and pops the
/// sheet with the saved expense.
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _category = expenseCategories.first;
  DateTime _date = DateTime.now();

  bool _saving = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
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

    // Amount is sent as typed; Laravel's "numeric" rule checks it.
    final res = await Api.post('/expenses', {
      'title': _title.text.trim(),
      'amount': _amount.text.trim(),
      'category': _category,
      'date': toIsoDate(_date),
    });
    if (!mounted) return;

    switch (res) {
      case ApiSuccess(:final data):
        Navigator.of(context)
            .pop(Expense.fromJson(data as Map<String, dynamic>));
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
    // Keep the form above the keyboard.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Title',
                  controller: _title,
                  hint: 'e.g. Lunch at Bhojan Griha',
                  error: _errors['title'],
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Amount',
                  controller: _amount,
                  hint: '0',
                  prefixText: 'Rs. ',
                  monoInput: true,
                  error: _errors['amount'],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                _categoryField(),
                const SizedBox(height: 16),
                _dateField(),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  FormErrorBox(
                    message: _formError!.message,
                    onRetry: _formError!.isNetworkError ? _submit : null,
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Add expense',
                  loadingLabel: 'Adding…',
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Add expense',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Category'),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          style: GoogleFonts.ibmPlexSans(fontSize: 15, color: AppColors.ink),
          borderRadius: BorderRadius.circular(6),
          dropdownColor: AppColors.white,
          decoration: InputDecoration(
            error: _errors['category'] == null
                ? null
                : ErrorMessage(_errors['category']!),
          ),
          items: [
            for (final c in expenseCategories)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _category = value);
          },
        ),
      ],
    );
  }

  Widget _dateField() {
    final label = formatLongDate(toIsoDate(_date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Date'),
        Semantics(
          button: true,
          label: 'Date, $label. Tap to change.',
          excludeSemantics: true,
          child: InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: InputDecoration(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
                error: _errors['date'] == null
                    ? null
                    : ErrorMessage(_errors['date']!),
              ),
              child: Text(label, style: AppText.mono(size: 15)),
            ),
          ),
        ),
      ],
    );
  }
}
