import 'package:material_ui/material_ui.dart';

import 'screens/expenses_screen.dart';
import 'screens/login_screen.dart';
import 'services/api.dart';
import 'services/auth_storage.dart';
import 'theme.dart';
import 'widgets/logo.dart';

/// Lets the API service send the user to login from anywhere (on a 401).
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  Api.onUnauthorized = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  };
  runApp(const KharchaApp());
}

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      home: const StartScreen(),
    );
  }
}

/// Checks for a saved token, then replaces itself with the right screen.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await AuthStorage.getToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            token == null ? const LoginScreen() : const ExpensesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Logo(size: 40),
            SizedBox(height: 32),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
