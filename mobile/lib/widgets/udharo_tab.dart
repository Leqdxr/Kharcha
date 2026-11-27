import 'dart:math' as math;

import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/udharo.dart';
import '../services/api.dart';
import '../theme.dart';
import 'udharo_forms.dart';

/// The Udharo tab: who owes you, whom you owe, Settle (with Undo) and
/// Split a bill.
class UdharoTab extends StatefulWidget {
  const UdharoTab({super.key});

  @override
  State<UdharoTab> createState() => UdharoTabState();
}

class UdharoTabState extends State<UdharoTab> {
  List<Udharo>? _udharos;
  String? _error;

  /// 0: they owe you, 1: you owe.
  int _list = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await Api.get('/udharos');
    if (!mounted) return;
    switch (res) {
      case ApiSuccess(data: final List rows):
        setState(() {
          _error = null;
          _udharos = [
            for (final r in rows) Udharo.fromJson(r as Map<String, dynamic>),
          ];
        });
      case ApiSuccess():
        break;
      case ApiFailure(:final error):
        setState(() => _error = error.message);
    }
  }

  /// The + button on this tab.
  Future<void> add() async {
    if (await showUdharoForm(context) == true && mounted) {
      _load();
      _showSnackBar('Udharo added');
    }
  }

  Future<void> _split() async {
    if (await showSplitBill(context) == true && mounted) {
      _load();
      _showSnackBar('Bill split. Your share is in your expenses.');
    }
  }

  Future<void> _settle(Udharo udharo) async {
    final res = await Api.post('/udharos/${udharo.id}/settle');
    if (!mounted) return;
    if (res case ApiFailure(:final error)) {
      _showSnackBar('Couldn’t settle with ${udharo.person}. ${error.message}');
      return;
    }
    setState(() => _udharos = [...?_udharos]..remove(udharo));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text('Settled with ${udharo.person.split(' ').first}.'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.white,
            onPressed: () => _unsettle(udharo),
          ),
        ),
      );
  }

  Future<void> _unsettle(Udharo udharo) async {
    final res = await Api.post('/udharos/${udharo.id}/unsettle');
    if (!mounted) return;
    if (res case ApiFailure(:final error)) {
      _showSnackBar('Couldn’t undo. ${error.message}');
    }
    _load();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final udharos = _udharos;
    if (udharos == null) {
      return Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Couldn’t load udharo. $_error',
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
    final owesYou = udharos.where((u) => u.isLent).toList();
    final youOwe = udharos.where((u) => !u.isLent).toList();
    double sum(List<Udharo> list) => list.fold(0.0, (s, u) => s + u.amount);
    final shown = _list == 0 ? owesYou : youOwe;

    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(side, 20, side, 120),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Udharo',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Who owes whom',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _totalBox('Friends owe you', sum(owesYou), AppColors.ink),
              const SizedBox(width: 10),
              _totalBox('You owe', sum(youOwe), AppColors.redDark),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 0,
                label: Text('Owe you (${owesYou.length})'),
              ),
              ButtonSegment(
                value: 1,
                label: Text('You owe (${youOwe.length})'),
              ),
            ],
            selected: {_list},
            onSelectionChanged: (s) => setState(() => _list = s.first),
          ),
          const SizedBox(height: 8),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'All settled. Nothing here.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.muted),
              ),
            ),
          for (final udharo in shown) _row(udharo),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _split,
            icon: const Icon(Icons.call_split),
            label: const Text('Split a bill'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalBox(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatMoney(amount),
                style: AppText.number(
                  size: 20,
                  weight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Udharo udharo) {
    final initials = udharo.person
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final what = [
      if (udharo.note?.isNotEmpty ?? false) udharo.note!,
      formatDate(udharo.date, withYear: false),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rowLine)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surface,
            child: Text(
              initials,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  udharo.person,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  what,
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
          const SizedBox(width: 8),
          Text(
            formatMoney(udharo.amount),
            style: AppText.number(weight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Semantics(
            label: 'Settle with ${udharo.person}',
            excludeSemantics: true,
            button: true,
            child: FilledButton(
              onPressed: () => _settle(udharo),
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text('Settle'),
            ),
          ),
        ],
      ),
    );
  }
}
