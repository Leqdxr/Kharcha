import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/income.dart';
import '../services/api.dart';
import '../theme.dart';
import 'form_fields.dart';

/// Opens the "Add income" sheet. Returns true when an income was saved.
Future<bool?> showIncomeForm(
  BuildContext context,
  Map<String, IncomeType> types,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.white,
    builder: (_) => IncomeForm(types: types),
  );
}

/// Amount before TDS, from, type, TDS cut and date. The TDS is filled in as
/// amount x rate and can be changed; salary TDS is always typed in.
class IncomeForm extends StatefulWidget {
  const IncomeForm({super.key, required this.types});

  final Map<String, IncomeType> types;

  @override
  State<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends State<IncomeForm> {
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _tds = TextEditingController();
  late String _type = widget.types.keys.first;
  DateTime _date = DateTime.now();

  /// Once the TDS is typed in, stop filling it from the rate.
  bool _tdsTyped = false;
  bool _saving = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _tds.dispose();
    super.dispose();
  }

  void _fillTds() {
    final rate = widget.types[_type]!.rate;
    if (_tdsTyped || rate == null) return;
    final amount = double.tryParse(_amount.text);
    _tds.text = amount == null
        ? ''
        : _plain((amount * rate * 100).round() / 100);
  }

  /// 3750.0 -> "3750", 37.5 -> "37.5"
  static String _plain(double n) =>
      n == n.truncateToDouble() ? '${n.toInt()}' : '$n';

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
    final res = await Api.post('/incomes', {
      'title': _title.text.trim(),
      'amount': _amount.text.trim(),
      'type': _type,
      'tds_amount': _tds.text.trim().isEmpty ? '0' : _tds.text.trim(),
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
    final type = widget.types[_type]!;
    final gross = double.tryParse(_amount.text) ?? 0;
    final tds = double.tryParse(_tds.text) ?? 0;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add income',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LabeledTextField(
              label: 'Amount before TDS',
              controller: _amount,
              prefixText: 'Rs. ',
              numberInput: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              error: _errors['amount'],
              onChanged: (_) => setState(_fillTds),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'From',
              controller: _title,
              hint: 'e.g. Logo design for a cafe',
              error: _errors['title'],
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const FieldLabel('Type of income'),
            for (final MapEntry(:key, :value) in widget.types.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _typeTile(key, value),
              ),
            if (_errors['type'] != null) ErrorMessage(_errors['type']!),
            const SizedBox(height: 8),
            LabeledTextField(
              label: type.rate == null
                  ? 'TDS cut (from your payslip)'
                  : 'TDS cut (${type.rateText}, change it if needed)',
              controller: _tds,
              prefixText: 'Rs. ',
              numberInput: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              error: _errors['tds_amount'],
              onChanged: (_) => setState(() => _tdsTyped = true),
            ),
            const SizedBox(height: 12),
            _summary(type, gross, tds),
            const SizedBox(height: 16),
            const FieldLabel('Date'),
            Semantics(
              button: true,
              label: 'Date, ${formatDate(toIsoDate(_date))}. Tap to change.',
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
                  child: Text(
                    formatDate(toIsoDate(_date)),
                    style: AppText.number(size: 15),
                  ),
                ),
              ),
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
              label: 'Save income · ${formatDate(toIsoDate(_date))}',
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

  Widget _typeTile(String key, IncomeType type) {
    final selected = _type == key;
    return Semantics(
      selected: selected,
      button: true,
      excludeSemantics: true,
      label: '${type.label}, ${type.rateText}',
      child: Material(
        color: selected ? AppColors.redTint : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? AppColors.red : AppColors.inputBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() {
            _type = key;
            _tdsTyped = false;
            if (type.rate == null) _tds.clear();
            _fillTds();
          }),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type.label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected ? AppColors.redDark : AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    type.rateText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(IncomeType type, double gross, double tds) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TDS cut (${type.rateText})',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              Text(formatMoney(tds), style: AppText.number(size: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'You received',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatMoney((gross - tds).clamp(0, double.infinity)),
                style: AppText.number(size: 14, weight: FontWeight.w600),
              ),
            ],
          ),
          if (type.isFinal) ...[
            const SizedBox(height: 8),
            Text(
              'Final withholding: this income won’t be added to your yearly tax estimate.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
