import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/income.dart';
import '../services/api.dart';
import '../theme.dart';
import 'confirm_dialog.dart';
import 'income_form.dart';

/// The Tax tab: what you may get back (or owe) this fiscal year, the
/// estimate behind it and the income so far. Swipe an income to delete it.
class TaxTab extends StatefulWidget {
  const TaxTab({super.key});

  @override
  State<TaxTab> createState() => TaxTabState();
}

class TaxTabState extends State<TaxTab> {
  TaxSummary? _summary;
  List<Income> _incomes = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final [summary, list] = await Future.wait([
      Api.get('/tax/summary'),
      Api.get('/incomes'),
    ]);
    if (!mounted) return;
    if (summary case ApiSuccess(data: final Map<String, dynamic> json)) {
      if (list case ApiSuccess(data: final List rows)) {
        final data = TaxSummary.fromJson(json);
        setState(() {
          _summary = data;
          _error = null;
          _incomes = [
            for (final r in rows) Income.fromJson(r as Map<String, dynamic>),
          ].where((i) => _inFiscalYear(i, data)).toList();
        });
        return;
      }
    }
    final error = [summary, list].whereType<ApiFailure>().firstOrNull?.error;
    setState(() => _error = error?.message ?? 'Something went wrong.');
  }

  bool _inFiscalYear(Income income, TaxSummary summary) =>
      income.date.compareTo(summary.fiscalYearStart) >= 0 &&
      income.date.compareTo(summary.fiscalYearEnd) <= 0;

  /// The + button on this tab.
  Future<void> add() async {
    final summary = _summary;
    if (summary == null) return;
    final saved = await showIncomeForm(context, summary.types);
    if (saved == true && mounted) {
      _load();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Income added')));
    }
  }

  Future<void> _delete(Income income) async {
    setState(
      () => _incomes = _incomes.where((i) => i.id != income.id).toList(),
    );
    final res = await Api.delete('/incomes/${income.id}');
    if (!mounted) return;
    if (res case ApiFailure(:final error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn’t delete it. ${error.message}')),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    if (summary == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Couldn’t load your tax summary. $_error',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.muted),
                    ),
                    const SizedBox(height: 16),
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

    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(20.0, (width - 720) / 2);
    final total = _incomes.fold(0.0, (sum, i) => sum + i.amount);

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(side, 20, side, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Tax & TDS',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'FY ${summary.fiscalYearLabel}',
                  style: AppText.number(size: 13, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _resultCard(summary),
          const SizedBox(height: 14),
          _howCard(summary),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Income so far',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                formatMoney(total),
                style: AppText.number(size: 14, weight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (_incomes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No income yet this fiscal year. Tap + to add your salary or a payment.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.muted),
              ),
            ),
          for (final income in _incomes) _incomeRow(income, summary),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.inkSoft,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keep the TDS slips your clients give you. You need them to claim this money when you file. Estimate only, using FY ${summary.fiscalYearLabel} slabs. It isn’t tax advice.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(TaxSummary summary) {
    final back = summary.result >= 0;
    final small = GoogleFonts.inter(fontSize: 12, color: AppColors.redTint);
    Widget box(String label, double value) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.redDark,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: small),
            Text(
              formatNumber(value.round()),
              style: AppText.number(
                size: 16,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            back ? 'You may get back' : 'You may still owe',
            style: small.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatMoney(summary.result.abs().round()),
              style: AppText.number(
                size: 34,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            back
                ? 'More TDS was cut than your estimated tax. Claim it when you file.'
                : 'Your TDS so far won’t cover your estimated tax.',
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              box('Estimated tax', summary.estimatedTax),
              const SizedBox(width: 8),
              box('TDS by year end', summary.adjustableTdsYearEnd),
            ],
          ),
        ],
      ),
    );
  }

  /// "Rs. 3,65,000 projected · all in the 1% slab", plus the SSF and final
  /// tax notes.
  Widget _howCard(TaxSummary summary) {
    final slabs = summary.slabsWithTax;
    final reach = switch (slabs) {
      0 => 'no tax yet',
      1 => 'all in the 1% slab',
      _ => 'reaches slab $slabs of 5',
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How we worked it out',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatMoney(summary.taxableIncome.round())} projected · $reach',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
          if (summary.ssfContributor)
            Text(
              'SSF contributor: the 1% slab is waived.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
          if (summary.finalTds > 0)
            Text(
              'Plus ${formatMoney(summary.finalTds.round())} final tax on interest and dividends.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Widget _incomeRow(Income income, TaxSummary summary) {
    final type = summary.types[income.type];
    final icon = switch (income.type) {
      'salary' => Icons.payments_outlined,
      'interest' || 'dividend' => Icons.account_balance_outlined,
      _ => Icons.work_outline,
    };
    final sub =
        '${formatDate(income.date, withYear: false)} · TDS ${formatNumber(income.tdsAmount)} (${type?.rateText ?? ''})';

    return Dismissible(
      key: ValueKey(income.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'Delete this income?',
        message:
            '“${income.title}” (${formatMoney(income.amount)}) will be deleted and your estimate updated.',
      ),
      onDismissed: (_) => _delete(income),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.red,
        child: const Icon(Icons.delete_outline, color: AppColors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.rowLine)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.inkSoft),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    income.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatNumber(income.amount),
              style: AppText.number(weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
