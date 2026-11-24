import 'package:material_ui/material_ui.dart';

import '../models/user.dart';
import '../services/api.dart';
import '../services/auth_storage.dart';
import '../theme.dart';
import '../widgets/auth_layout.dart';
import '../widgets/form_fields.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  bool _loading = false;
  Map<String, String> _errors = {};
  ApiError? _formError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _errors = {};
      _formError = null;
    });

    // Same quick check as the web app, before bothering the server.
    if (_password.text != _passwordConfirmation.text) {
      setState(() {
        _errors = {'password_confirmation': 'Passwords don’t match.'};
      });
      return;
    }

    setState(() => _loading = true);
    final res = await Api.post('/register', {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'password_confirmation': _passwordConfirmation.text,
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
          _formError = error.errors.isEmpty ? error : null;
        });
    }
  }

  void _openLogin() {
    final navigator = Navigator.of(context);
    // Usually we came here from login, so just go back.
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      illustration: 'assets/images/register.svg',
      illustrationLabel: 'A person standing next to a large sign-up form',
      panelColor: AppColors.redTint,
      title: 'Create your account',
      subtitle: 'It takes less than a minute.',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                label: 'Full name',
                controller: _name,
                hint: 'Your name',
                error: _errors['name'],
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: 18),
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
                hint: '8+ characters',
                error: _errors['password'],
                isPassword: true,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 18),
              LabeledTextField(
                label: 'Confirm password',
                controller: _passwordConfirmation,
                hint: 'Type it again',
                error: _errors['password_confirmation'],
                isPassword: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
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
          label: 'Create account',
          loadingLabel: 'Creating account…',
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 12),
        SwitchAuthLink(
          text: 'Already have an account?',
          linkText: 'Log in',
          onTap: _openLogin,
        ),
      ],
    );
  }
}
