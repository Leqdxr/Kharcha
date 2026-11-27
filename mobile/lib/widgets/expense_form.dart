import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../presets.dart';
import '../services/api.dart';
import '../services/session.dart';
import '../theme.dart';
import 'form_fields.dart';

/// What the expense sheet closed with. A plain close returns null.
sealed class ExpenseFormResult {
  const ExpenseFormResult();
}

/// The expense was created (add mode) or updated (edit mode).
class ExpenseSaved extends ExpenseFormResult {
  const ExpenseSaved(this.expense, {this.repeatChanged = false});

  final Expense expense;

  /// A monthly repeat was started or stopped, which can change other rows
  /// (and add bills for earlier months), so the list should reload.
  final bool repeatChanged;
}

/// The user tapped "Delete" in edit mode. The screen asks to confirm, then
/// deletes it, the same way as swipe to delete.
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

/// Quick add (when adding), amount, title, category, paid with, date, note
/// and "Repeat every month". Saves through the API (POST to add, PUT to
/// edit), starts or stops the repeat, and pops the sheet with the result.
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
  late String? _paymentMethod = widget.expense?.paymentMethod;
  late bool _repeat = widget.expense?.recurringExpenseId != null;

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
      'payment_method': _paymentMethod,
      'date': toIsoDate(_date),
      'note': _note.text.trim(),
    };
    final res = _isEdit
        ? await Api.put('/expenses/${widget.expense!.id}', body)
        : await Api.post('/expenses', body);
    if (!mounted) return;

    if (res case ApiFailure(:final error)) {
      _showError(error);
      return;
    }
    final saved = Expense.fromJson(
      (res as ApiSuccess).data as Map<String, dynamic>,
    );

    // Start or stop the monthly repeat.
    final ruleId = widget.expense?.recurringExpenseId;
    final repeatChanged = _repeat != (ruleId != null);
    if (repeatChanged) {
      final rule = _repeat
          ? await Api.post('/recurring-expenses', {'expense_id': saved.id})
          : await Api.delete('/recurring-expenses/$ruleId');
      if (!mounted) return;
      if (rule case ApiFailure(:final error)) {
        // The expense itself is saved, so the list must still update.
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(ExpenseSaved(saved, repeatChanged: true));
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Saved, but the repeat didn’t change. ${error.message}',
            ),
          ),
        );
        return;
      }
    }
    Navigator.of(context)
        .pop(ExpenseSaved(saved, repeatChanged: repeatChanged));
  }

  void _showError(ApiError error) {
    setState(() {
      _saving = false;
      _errors = error.errors;
      _formError = error.errors.isEmpty ? error : null;
    });
  }

  void _usePreset(({String title, int amount, String category}) preset) {
    setState(() {
      _title.text = preset.title;
      _amount.text = '${preset.amount}';
      _category = preset.category;
    });
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
                if (!_isEdit) _quickAdd(),
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
                if (_methods.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _paidWithField(),
                ],
                const SizedBox(height: 16),
                _dateField(),
                const SizedBox(height: 12),
                _repeatField(),
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
      style: GoogleFonts.inter(
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
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
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
                style: AppText.number(size: 22, color: AppColors.muted),
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
                  style: AppText.number(size: 40, weight: FontWeight.w600),
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
                  style: GoogleFonts.inter(
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
    final label = formatDate(toIsoDate(_date));
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
              child: Text(label, style: AppText.number(size: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickAdd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick add',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in quickAddPresets)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    onPressed: () => _usePreset(preset),
                    label: Text.rich(
                      TextSpan(
                        text: '${preset.title} ',
                        children: [
                          TextSpan(
                            text: '${preset.amount}',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// The methods turned on in Settings, plus the expense's own if it has
  /// been turned off since.
  List<String> get _methods {
    final methods = [...?currentUser.value?.paymentMethods];
    final own = _paymentMethod;
    if (own != null && !methods.contains(own)) methods.add(own);
    return methods;
  }

  /// Chips; tapping the selected one again clears it.
  Widget _paidWithField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Paid with (optional)'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final method in _methods)
              ChoiceChip(
                label: Text(paymentMethodLabels[method] ?? method),
                selected: _paymentMethod == method,
                selectedColor: AppColors.redTint,
                side: BorderSide(
                  color: _paymentMethod == method
                      ? AppColors.red
                      : AppColors.inputBorder,
                  width: _paymentMethod == method ? 1.5 : 1,
                ),
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: _paymentMethod == method
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _paymentMethod == method
                      ? AppColors.redDark
                      : AppColors.ink,
                ),
                onSelected: (_) => setState(
                  () =>
                      _paymentMethod = _paymentMethod == method ? null : method,
                ),
              ),
          ],
        ),
        if (_errors['payment_method'] != null) ...[
          const SizedBox(height: 6),
          ErrorMessage(_errors['payment_method']!),
        ],
      ],
    );
  }

  Widget _repeatField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Repeat every month',
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _repeat ? 'On day ${_date.day} of each month' : 'Off',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
        ),
        value: _repeat,
        activeThumbColor: AppColors.white,
        activeTrackColor: AppColors.red,
        onChanged: (on) => setState(() => _repeat = on),
      ),
    );
  }
}
