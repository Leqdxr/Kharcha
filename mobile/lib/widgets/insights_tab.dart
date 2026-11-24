import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../models/summary.dart';
import '../theme.dart';
import 'month_switcher.dart';

/// The Insights tab: compared with last month, where it went, and the
/// three biggest expenses of the month.
class InsightsTab extends StatelessWidget {
  const InsightsTab({
    super.key,
    required this.month,
    required this.expenses,
    required this.summary,
    required this.onMonthChanged,
    required this.onRefresh,
  });

  final DateTime month;
  final List<Expense> expenses;
  final Summary summary;
  final ValueChanged<DateTime> onMonthChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(20.0, (width - 720) / 2);
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return ColoredBox(
      color: AppColors.rowHover,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(side, 20, side, 4),
            child: Semantics(
              header: true,
              child: Text(
                'Insights',
                style: GoogleFonts.onest(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: side - 8),
            child: MonthSwitcher(
              month: month,
              onChanged: onMonthChanged,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.red,
              onRefresh: onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(side, 4, side, 32),
                children: [
                  _comparison(total),
                  const SizedBox(height: 14),
                  _whereItWent(total),
                  const SizedBox(height: 14),
                  _biggest(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparison(double total) {
    final previous = summary.previousTotal;
    final previousMonth = parseMonth(summary.previousMonth);
    final most = math.max(total, previous);
    final pct = percentChange(total, previous);

    final normal = GoogleFonts.onest(fontSize: 14, color: AppColors.inkSoft);
    final bold = normal.copyWith(fontWeight: FontWeight.w700);
    final InlineSpan sentence;
    if (pct == null) {
      sentence = TextSpan(
        text: 'Nothing was recorded in ${formatMonthName(previousMonth)}.',
      );
    } else if (total == previous) {
      sentence = const TextSpan(text: 'You spent the same as last month.');
    } else {
      final diff = (total - previous).abs();
      sentence = TextSpan(
        children: [
          const TextSpan(text: 'You spent '),
          TextSpan(
            text: '${formatMoney(diff)} ${total < previous ? 'less' : 'more'}',
            style: bold,
          ),
          TextSpan(text: ' (${pct.abs()}%) than last month.'),
        ],
      );
    }

    return _Section(
      title: 'Compared with ${formatMonthName(previousMonth)}',
      children: [
        _BarRow(
          label: formatMonthName(month),
          value: total,
          fraction: most > 0 ? total / most : 0,
          color: AppColors.red,
        ),
        const SizedBox(height: 8),
        _BarRow(
          label: formatMonthName(previousMonth),
          value: previous,
          fraction: most > 0 ? previous / most : 0,
          color: const Color(0xFFA8A19A),
        ),
        const SizedBox(height: 12),
        Text.rich(TextSpan(style: normal, children: [sentence])),
      ],
    );
  }

  Widget _whereItWent(double total) {
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _Section(
      title: 'Where it went',
      children: [
        if (sorted.isEmpty) _muted('Nothing spent yet.'),
        for (final entry in sorted) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: GoogleFonts.onest(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${formatNumber(entry.value)} · '
                '${(entry.value / total * 100).round()}%',
                style: AppText.mono(size: 14, color: AppColors.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _Bar(fraction: entry.value / total, height: 8),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _biggest() {
    final top = [...expenses]..sort((a, b) => b.amount.compareTo(a.amount));

    return _Section(
      title: 'Biggest expenses',
      children: [
        if (top.isEmpty) _muted('No expenses this month.'),
        for (final (i, expense) in top.take(3).indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: i < math.min(3, top.length) - 1
                  ? const Border(bottom: BorderSide(color: AppColors.rowLine))
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: '${i + 1}. ${expense.title} ',
                      style: GoogleFonts.onest(
                        fontSize: 15,
                        color: AppColors.ink,
                      ),
                      children: [
                        TextSpan(
                          text: '· ${formatShortDate(expense.date)}',
                          style: GoogleFonts.onest(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatNumber(expense.amount),
                  style: AppText.mono(weight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _muted(String text) => Text(
    text,
    style: GoogleFonts.onest(fontSize: 14, color: AppColors.muted),
  );
}

/// White rounded box with a bold title.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: GoogleFonts.onest(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// "November [=======    ] 8,060"
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double value;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.onest(fontSize: 13, color: AppColors.muted),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Bar(fraction: fraction, height: 12, color: color),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(
            formatNumber(value),
            textAlign: TextAlign.right,
            style: AppText.mono(size: 13, weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// A rounded bar on a light track.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.height,
    this.color = AppColors.red,
  });

  final double fraction;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: fraction.clamp(0, 1).toDouble(),
        minHeight: height,
        backgroundColor: AppColors.surface,
        color: color,
      ),
    );
  }
}
