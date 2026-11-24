import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../services/api.dart';
import '../theme.dart';
import 'form_fields.dart';

/// What the expense sheet closed with. A plain close returns null.
sealed class ExpenseFormResult {
  const ExpenseFormResult();
}

/// The expense was created (add mode) or updated (edit mode).
class ExpenseSaved extends ExpenseFormResult {
  const ExpenseSaved(this.expense);

  final Expense expense;
}

/// The user tapped "Delete" in edit mode. The screen asks to confirm, then
/// deletes it with an Undo snackbar, the same way as swipe to delete.
class ExpenseDeleteRequested extends ExpenseFormResult {
  const ExpenseDeleteRequested();
}

/// Opens the expense bottom sheet: "Add expense" without [expense],
/// "Edit expense" (pre-filled) with one.
Future<ExpenseFormResult?> showExpenseForm(
  BuildContext context, {
  Expense? expense,
}) {
  return showModalBottomSheet<ExpenseFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (_) => ExpenseForm(expense: expense),
  );
}

/// Amount, title, category, date and note. Saves through the API (POST to
/// add, PUT to edit) and pops the sheet with the result.
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.expense});

  /// The expense being edited, or null to add a new one.
  final Expense? expense;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late final _title = TextEditingController(text: widget.expense?.title);
  late final _note = TextEditingController(text: widget.expense?.note);
  late final _amount = TextEditingController(
    text: widget.expense == null ? '' : _amountText(widget.expense!.amount),
  );
  late String _category = widget.expense?.category ?? expenseCategories.first;
  late DateTime _date = widget.expense == null
      ? DateTime.now()
      : DateTime.parse(widget.expense!.date);

  bool get _isEdit => widget.expense != null;

  /// 340.0 -> "340", 12.5 -> "12.5"
  static String _amountText(double amount) {
    return amount == amount.truncateToDouble()
        ? amount.toInt().toString()
        : amount.toString();
  }

  bool _saving = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
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
    final body = {
      'title': _title.text.trim(),
      'amount': _amount.text.trim(),
      'category': _category,
      'date': toIsoDate(_date),
      'note': _note.text.trim(),
    };
    final res = _isEdit
        ? await Api.put('/expenses/${widget.expense!.id}', body)
        : await Api.post('/expenses', body);
    if (!mounted) return;

    switch (res) {
      case ApiSuccess(:final data):
        Navigator.of(context)
            .pop(ExpenseSaved(Expense.fromJson(data as Map<String, dynamic>)));
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
                const SizedBox(height: 8),
                _amountField(),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Title',
                  controller: _title,
                  hint: 'e.g. Lunch at Bhojan Griha',
                  error: _errors['title'],
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                _categoryField(),
                const SizedBox(height: 16),
                _dateField(),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: 'Note (optional)',
                  controller: _note,
                  hint: 'Who, where, why',
                  error: _errors['note'],
                  maxLines: 2,
                  maxLength: 255,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  FormErrorBox(
                    message: _formError!.message,
                    onRetry: _formError!.isNetworkError ? _submit : null,
                  ),
                ],
                const SizedBox(height: 24),
                _actions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final title = Text(
      _isEdit ? 'Edit expense' : 'Add expense',
      style: GoogleFonts.onest(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
    return Row(
      children: [
        Expanded(
          child: _isEdit
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXPENSE #${widget.expense!.id}',
                      style: AppText.eyebrow(),
                    ),
                    const SizedBox(height: 2),
                    title,
                  ],
                )
              : title,
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _actions() {
    if (!_isEdit) {
      return PrimaryButton(
        label: 'Add expense',
        loadingLabel: 'Adding\u2026',
        loading: _saving,
        onPressed: _submit,
        height: 52,
        radius: 12,
      );
    }
    return Row(
      children: [
        TextButton.icon(
          onPressed: _saving
              ? null
              : () => Navigator.of(context).pop(const ExpenseDeleteRequested()),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PrimaryButton(
            label: 'Save changes',
            loadingLabel: 'Saving\u2026',
            loading: _saving,
            onPressed: _submit,
            height: 52,
            radius: 12,
          ),
        ),
      ],
    );
  }

  /// The big centered amount with a red underline.
  Widget _amountField() {
    final error = _errors['amount'];
    return Column(
      children: [
        // The input below is labelled for screen readers instead.
        ExcludeSemantics(
          child: Text(
            'Amount',
            style: GoogleFonts.onest(fontSize: 13, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            ExcludeSemantics(
              child: Text(
                'Rs.',
                style: AppText.mono(size: 22, color: AppColors.muted),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 170,
              child: Semantics(
                label: 'Amount in rupees',
                child: TextField(
                  controller: _amount,
                  autofocus: !_isEdit,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: AppText.mono(size: 40, weight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: '0',
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.only(bottom: 2),
                    border: _amountBorder,
                    enabledBorder: _amountBorder,
                    focusedBorder: _amountBorder,
                    errorBorder: _amountBorder,
                    focusedErrorBorder: _amountBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (error != null) ...[const SizedBox(height: 6), ErrorMessage(error)],
      ],
    );
  }

  static const _amountBorder = UnderlineInputBorder(
    borderSide: BorderSide(color: AppColors.red, width: 2),
  );

  /// Four tiles with icons; the selected one is red-tinted.
  Widget _categoryField() {
    final error = _errors['category'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Category'),
        Row(
          children: [
            for (final (i, category) in expenseCategories.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _categoryTile(category)),
            ],
          ],
        ),
        if (error != null) ...[const SizedBox(height: 6), ErrorMessage(error)],
      ],
    );
  }

  Widget _categoryTile(String category) {
    final selected = _category == category;
    final color = selected ? AppColors.redDark : AppColors.inkSoft;
    return Semantics(
      selected: selected,
      button: true,
      excludeSemantics: true,
      label: category,
      child: Material(
        color: selected ? AppColors.redTint : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.red : AppColors.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _category = category),
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categoryIcons[category], size: 20, color: color),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: GoogleFonts.onest(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
