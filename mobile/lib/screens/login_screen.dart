import 'package:material_ui/material_ui.dart';

import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_storage.dart';
import '../theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/form_fields.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errors = {};
      _formError = null;
    });

    final res = await Api.post('/login', {
      'email': _email.text.trim(),
      'password': _password.text,
    });
    if (!mounted) return;

    switch (res) {
      case ApiSuccess(:final data):
        await AuthStorage.saveAuth(
          data['token'] as String,
          User.fromJson(data['user'] as Map<String, dynamic>),
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      case ApiFailure(:final error):
        setState(() {
          _loading = false;
          _errors = error.errors;
          // Field errors show under their inputs; anything else
          // (like a wrong password) shows above the button.
          _formError = error.errors.isEmpty ? error : null;
        });
    }
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      illustration: 'assets/images/login.svg',
      illustrationLabel: 'Two cats standing on either side of the word WELCOME',
      panelColor: AppColors.surface,
      title: 'Welcome back',
      subtitle: 'Log in to see this month’s spending.',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                error: _errors['email'],
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 18),
              LabeledTextField(
                label: 'Password',
                controller: _password,
                hint: 'At least 8 characters',
                error: _errors['password'],
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        if (_formError != null) ...[
          const SizedBox(height: 18),
          FormErrorBox(
            message: _formError!.message,
            onRetry: _formError!.isNetworkError ? _submit : null,
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Log in',
          loadingLabel: 'Logging in…',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        SwitchAuthLink(
          text: 'New here?',
          linkText: 'Create an account',
          onTap: _openRegister,
        ),
      ],
    );
  }
}
