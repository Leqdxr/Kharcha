import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../format.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_storage.dart';
import '../services/pan_storage.dart';
import '../services/session.dart';
import '../theme.dart';
import '../widgets/budget_dialog.dart';
import 'goals_screen.dart';
import 'login_screen.dart';

/// Settings: calendar, budget, goals, payment methods, SSF, PAN and log
/// out. Calendar, SSF and payment methods are saved on the user, so web
/// and mobile match. The PAN only stays on this phone.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _pan;
  int? _goalCount;

  @override
  void initState() {
    super.initState();
    currentUser.addListener(_onUserChanged);
    PanStorage.get().then((pan) {
      if (mounted) setState(() => _pan = pan);
    });
    _loadGoalCount();
  }

  @override
  void dispose() {
    currentUser.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() => setState(() {});

  Future<void> _loadGoalCount() async {
    if (await Api.get('/goals') case ApiSuccess(data: final List goals)) {
      if (mounted) setState(() => _goalCount = goals.length);
    }
  }

  /// Counts saves, so only the newest reply is used when several are on
  /// their way (e.g. BS, AD, BS tapped quickly).
  int _saves = 0;

  /// Shows the change at once, then saves it with PUT /settings. If saving
  /// fails, the old setting comes back.
  Future<void> _save(Map<String, Object> changes) async {
    final before = currentUser.value;
    if (before == null) return;
    currentUser.value = User.fromJson({...before.toJson(), ...changes});

    final save = ++_saves;
    final res = await Api.put('/settings', changes);
    if (save != _saves) return;
    switch (res) {
      case ApiSuccess(data: final Map<String, dynamic> json):
        await setCurrentUser(User.fromJson(json));
      case ApiSuccess():
        break;
      case ApiFailure(:final error):
        currentUser.value = before;
        if (mounted) _showSnackBar('Couldn’t save. ${error.message}');
    }
  }

  Future<void> _editBudget(User user) async {
    final saved = await showBudgetDialog(context, user.monthlyBudget);
    if (saved != null) await setCurrentUser(saved);
  }

  Future<void> _openGoals() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const GoalsScreen()));
    _loadGoalCount();
  }

  Future<void> _editPan() async {
    final pan = await showDialog<String>(
      context: context,
      builder: (_) => _PanDialog(pan: _pan),
    );
    if (pan == null) return;
    if (pan.isEmpty) {
      await PanStorage.clear();
    } else {
      await PanStorage.save(pan);
    }
    if (mounted) setState(() => _pan = pan.isEmpty ? null : pan);
  }

  Future<void> _logOut() async {
    // Tell the backend to drop the token, but log out locally either way.
    await Api.post('/logout');
    await AuthStorage.clear();
    await PanStorage.clear();
    currentUser.value = null;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser.value;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _heading('Dates'),
                _calendarPicker(user),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    text: 'Today shows as ',
                    children: [
                      TextSpan(
                        text: formatDate(toIsoDate(DateTime.now())),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                // Which year the Tax tab lists. The estimate always uses the
                // fiscal year.
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: _title('Nepali fiscal year'),
                  subtitle: _subtitle(
                    user.fiscalYearView
                        ? 'Tax tab lists Shrawan to Asar'
                        : 'Tax tab lists January to December',
                  ),
                  value: user.fiscalYearView,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.red,
                  onChanged: (on) => _save({'fiscal_year_view': on}),
                ),
                _heading('Money'),
                _linkRow(
                  'Monthly budget',
                  user.monthlyBudget == null
                      ? 'Not set'
                      : formatMoney(user.monthlyBudget!),
                  () => _editBudget(user),
                ),
                _linkRow('Savings goals', switch (_goalCount) {
                  null => '',
                  1 => '1 goal',
                  final n => '$n goals',
                }, _openGoals),
                const SizedBox(height: 8),
                _title('How you pay'),
                _subtitle('Shown when you add an expense'),
                const SizedBox(height: 8),
                _paymentMethods(user),
                _heading('Tax'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: _title('I contribute to SSF'),
                  subtitle: _subtitle(
                    'Waives the 1% Social Security Tax in estimates',
                  ),
                  value: user.ssfContributor,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.red,
                  onChanged: (on) => _save({'ssf_contributor': on}),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: _title('PAN number'),
                  subtitle: _subtitle('Optional. Stays on this phone.'),
                  trailing: Text(
                    _pan == null ? 'Add ›' : '$_pan ›',
                    style: AppText.number(size: 14, color: AppColors.muted),
                  ),
                  onTap: _editPan,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _logOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: AppText.eyebrow()),
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
  );

  Widget _subtitle(String text) => Text(
    text,
    style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
  );

  Widget _calendarPicker(User user) {
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 'bs', label: Text('Bikram Sambat (BS)')),
        ButtonSegment(value: 'ad', label: Text('English (AD)')),
      ],
      selected: {user.calendar},
      onSelectionChanged: (s) => _save({'calendar': s.first}),
    );
  }

  Widget _linkRow(String title, String value, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: _title(title),
      trailing: Text(
        '$value ›',
        style: AppText.number(size: 14, color: AppColors.muted),
      ),
      onTap: onTap,
    );
  }

  /// Toggle chips; saved in the backend's order.
  Widget _paymentMethods(User user) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final method in paymentMethodKeys)
          FilterChip(
            label: Text(paymentMethodLabels[method]!),
            selected: user.paymentMethods.contains(method),
            selectedColor: AppColors.redTint,
            side: BorderSide(
              color: user.paymentMethods.contains(method)
                  ? AppColors.red
                  : AppColors.inputBorder,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              color: user.paymentMethods.contains(method)
                  ? AppColors.redDark
                  : AppColors.ink,
            ),
            onSelected: (on) => _save({
              'payment_methods': [
                for (final m in paymentMethodKeys)
                  if (m == method ? on : user.paymentMethods.contains(m)) m,
              ],
            }),
          ),
      ],
    );
  }
}

/// Type or clear the PAN. Returns the new PAN ('' to remove), or null.
class _PanDialog extends StatefulWidget {
  const _PanDialog({this.pan});

  final String? pan;

  @override
  State<_PanDialog> createState() => _PanDialogState();
}

class _PanDialogState extends State<_PanDialog> {
  late final _pan = TextEditingController(text: widget.pan);
  String? _error;

  @override
  void dispose() {
    _pan.dispose();
    super.dispose();
  }

  void _submit() {
    final pan = _pan.text.trim();
    // A Nepali PAN is 9 digits.
    if (pan.isNotEmpty && !RegExp(r'^\d{9}$').hasMatch(pan)) {
      setState(() => _error = 'A PAN has 9 digits.');
      return;
    }
    Navigator.of(context).pop(pan);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      title: const Text('PAN number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _pan,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 9,
            style: AppText.number(size: 16),
            decoration: InputDecoration(
              hintText: '9 digits',
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          Text(
            'It stays on this phone and is never sent to Kharcha’s server.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
      actions: [
        if (widget.pan != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Remove'),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
