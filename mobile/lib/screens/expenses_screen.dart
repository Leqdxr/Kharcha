import 'package:material_ui/material_ui.dart';

import '../services/auth_storage.dart';
import '../widgets/logo.dart';
import 'login_screen.dart';

// Placeholder so login has somewhere to go. Replaced in Phase 3.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  Future<void> _logOut(BuildContext context) async {
    await AuthStorage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Logo(),
              const SizedBox(height: 16),
              FutureBuilder(
                future: AuthStorage.getUser(),
                builder: (context, snapshot) =>
                    Text('Logged in as ${snapshot.data?.name ?? '...'}'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _logOut(context),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
