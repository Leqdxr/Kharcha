import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'logo.dart';

/// Shared layout for login and register: logo, illustration, heading,
/// then the form. Scrolls so the keyboard never covers the fields.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.illustration,
    required this.illustrationLabel,
    required this.panelColor,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  /// Path under assets/images/, e.g. 'assets/images/login.svg'.
  final String illustration;
  final String illustrationLabel;
  final Color panelColor;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // On short screens (landscape) the illustration would push the form
    // out of view, so leave it out.
    final showIllustration = size.height >= 560;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Logo()),
                    const SizedBox(height: 20),
                    if (showIllustration) ...[
                      Container(
                        height: 180,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: panelColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SvgPicture.asset(
                          illustration,
                          semanticsLabel: illustrationLabel,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "New here? Create an account" style line with a tappable link.
class SwitchAuthLink extends StatelessWidget {
  const SwitchAuthLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  final String text;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: Text(linkText),
        ),
      ],
    );
  }
}
