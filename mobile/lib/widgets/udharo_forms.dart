import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../services/api.dart';
import '../theme.dart';
import 'form_fields.dart';

/// Opens "Add udharo". Returns true when one was saved.
Future<bool?> showUdharoForm(BuildContext context) =>
    _showSheet(context, const UdharoForm());

/// Opens "Split a bill". Returns true when the bill was split.
Future<bool?> showSplitBill(BuildContext context) =>
    _showSheet(context, const SplitBillForm());

Future<bool?> _showSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (_) => child,
  );
}

final _amountFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
];

/// Title row of a sheet: heading and a close button.
Widget _sheetHeader(BuildContext context, String title) {
  return Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
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

/// Two or more choices as red-tinted toggle chips.
Widget _choiceChips<T>({
  required List<(T, String)> options,
  required T selected,
  required ValueChanged<T> onSelected,
}) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (value, label) in options)
        ChoiceChip(
          label: Text(label),
          selected: value == selected,
          selectedColor: AppColors.redTint,
          side: BorderSide(
            color: value == selected ? AppColors.red : AppColors.inputBorder,
            width: value == selected ? 1.5 : 1,
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: value == selected ? FontWeight.w600 : FontWeight.w400,
            color: value == selected ? AppColors.redDark : AppColors.ink,
          ),
          onSelected: (_) => onSelected(value),
        ),
    ],
  );
}

/// "I lent money" / "I borrowed", person, amount, what for and date.
class UdharoForm extends StatefulWidget {
  const UdharoForm({super.key});

  @override
  State<UdharoForm> createState() => _UdharoFormState();
}

class _UdharoFormState extends State<UdharoForm> {
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _direction = 'lent';
  DateTime _date = DateTime.now();
  bool _saving = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _errors = {};
      _formError = null;
    });
    final res = await Api.post('/udharos', {
      'person': _person.text.trim(),
      'amount': _amount.text.trim(),
      'direction': _direction,
      'note': _note.text.trim(),
      'date': toIsoDate(_date),
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetHeader(context, 'Add udharo'),
            const SizedBox(height: 8),
            _choiceChips(
              options: const [
                ('lent', 'I lent money'),
                ('borrowed', 'I borrowed'),
              ],
              selected: _direction,
              onSelected: (d) => setState(() => _direction = d),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Person',
              controller: _person,
              hint: 'Name',
              error: _errors['person'],
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Amount',
              controller: _amount,
              prefixText: 'Rs. ',
              numberInput: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _amountFormatters,
              error: _errors['amount'],
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'What for',
              controller: _note,
              hint: 'e.g. Bus fare',
              error: _errors['note'],
              maxLength: 255,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            _DateField(
              date: _date,
              error: _errors['date'],
              onChanged: (d) => setState(() => _date = d),
            ),
            if (_formError != null) ...[
              const SizedBox(height: 16),
              FormErrorBox(
                message: _formError!.message,
                onRetry: _formError!.isNetworkError ? _submit : null,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Add udharo',
              loadingLabel: 'Adding…',
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

/// A bill you paid, split equally between you and your friends. Friends'
/// shares are whole rupees and you take the remainder. Each friend gets an
/// udharo and your share is added as an expense.
class SplitBillForm extends StatefulWidget {
  const SplitBillForm({super.key});

  @override
  State<SplitBillForm> createState() => _SplitBillFormState();
}

class _SplitBillFormState extends State<SplitBillForm> {
  final _title = TextEditingController();
  final _total = TextEditingController();
  final _friend = TextEditingController();
  final _friends = <String>[];
  String _category = 'Food';
  bool _saving = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _title.dispose();
    _total.dispose();
    _friend.dispose();
    super.dispose();
  }

  void _addFriend() {
    final name = _friend.text.trim();
    setState(() {
      if (name.isNotEmpty && !_friends.contains(name)) _friends.add(name);
      _friend.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _errors = {};
      _formError = null;
    });
    final res = await Api.post('/udharos/split', {
      'title': _title.text.trim(),
      'total': _total.text.trim(),
      'friends': _friends,
      'category': _category,
    });
    if (!mounted) return;
    switch (res) {
      case ApiSuccess():
        Navigator.of(context).pop(true);
      case ApiFailure(:final error):
        setState(() {
          _saving = false;
          _errors = {
            ...error.errors,
            // An error on one name ("friends.0") shows under the friends.
            if (error.errors.entries
                    .where((e) => e.key.startsWith('friends.'))
                    .firstOrNull
                case final e?)
              'friends': e.value,
          };
          _formError = error.errors.isEmpty ? error : null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(_total.text) ?? 0;
    final people = _friends.length + 1;
    final share = (total / people).floor();
    final yours = ((total - share * (people - 1)) * 100).round() / 100;
    final canSplit = _friends.isNotEmpty && share >= 1;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetHeader(context, 'Split a bill'),
            Text(
              'You paid. Everyone pays an equal share.',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'What for',
              controller: _title,
              hint: 'e.g. Khaja set at the canteen',
              error: _errors['title'],
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Total',
              controller: _total,
              prefixText: 'Rs. ',
              numberInput: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: _amountFormatters,
              error: _errors['total'],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: LabeledTextField(
                    label: 'Friends',
                    controller: _friend,
                    hint: 'Name',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addFriend(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _addFriend, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(
                  label: const Text('You'),
                  backgroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.ink),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                for (final friend in _friends)
                  InputChip(
                    label: Text(friend),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                    deleteButtonTooltipMessage: 'Remove $friend',
                    onDeleted: () => setState(() => _friends.remove(friend)),
                  ),
              ],
            ),
            if (_errors['friends'] != null) ...[
              const SizedBox(height: 6),
              ErrorMessage(_errors['friends']!),
            ],
            const SizedBox(height: 16),
            const FieldLabel('Your share goes to'),
            _choiceChips(
              options: [for (final c in expenseCategories) (c, c)],
              selected: _category,
              onSelected: (c) => setState(() => _category = c),
            ),
            if (canSplit) ...[
              const SizedBox(height: 16),
              Text(
                'Split equally: ${formatMoney(share)} each. '
                '${_joinNames(_friends)} ${_friends.length == 1 ? 'will owe' : 'will each owe'} you ${formatMoney(share)}, '
                'and your ${formatMoney(yours)} is added to your $_category expenses.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            if (_formError != null) ...[
              const SizedBox(height: 16),
              FormErrorBox(
                message: _formError!.message,
                onRetry: _formError!.isNetworkError ? _submit : null,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Split and add to udharo',
              loadingLabel: 'Splitting…',
              loading: _saving,
              onPressed: canSplit ? _submit : null,
              height: 52,
              radius: 12,
            ),
          ],
        ),
      ),
    );
  }

  /// ["Sujan", "Priya", "Anish"] -> "Sujan, Priya and Anish"
  static String _joinNames(List<String> names) => names.length < 2
      ? names.join()
      : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}

/// "Date" with the date in the user's calendar; tap to pick another.
class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onChanged, this.error});

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final label = formatDate(toIsoDate(date));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Date'),
        Semantics(
          button: true,
          label: 'Date, $label. Tap to change.',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onChanged(picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                suffixIcon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.muted,
                ),
                error: error == null ? null : ErrorMessage(error!),
              ),
              child: Text(label, style: AppText.number(size: 15)),
            ),
          ),
        ),
      ],
    );
  }
}
