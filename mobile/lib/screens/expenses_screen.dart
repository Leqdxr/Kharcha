import 'package:material_ui/material_ui.dart';

import '../widgets/logo.dart';

// Placeholder so main.dart has somewhere to go. Replaced in Phase 3.
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Logo(),
              SizedBox(height: 16),
              Text('Expenses screen'),
            ],
          ),
        ),
      ),
    );
  }
}
