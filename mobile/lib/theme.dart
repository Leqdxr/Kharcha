import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Colors from design/DESIGN.md.
class AppColors {
  static const red = Color(0xFFB42318);
  static const redDark = Color(0xFF8F1C13);
  static const redTint = Color(0xFFFBEDEB);
  static const ink = Color(0xFF1B1918);
  static const muted = Color(0xFF6B6560);
  static const surface = Color(0xFFF6F4F1);
  static const line = Color(0xFFE6E2DC);
  static const inputBorder = Color(0xFFD6D0C9);
  static const rowHover = Color(0xFFFBFAF8);
  static const white = Color(0xFFFFFFFF);

  /// Softer than ink, for icons and secondary numbers.
  static const inkSoft = Color(0xFF3D3835);

  /// Thin lines between list rows.
  static const rowLine = Color(0xFFEFECE8);
}

/// Material icons for each category (see DESIGN.md).
const categoryIcons = <String, IconData>{
  'Food': Icons.restaurant,
  'Travel': Icons.directions_bus,
  'Bills': Icons.bolt,
  'Other': Icons.sell,
};

/// Text styles used outside the Material text theme.
class AppText {
  /// Geist Mono, for amounts and dates.
  static TextStyle mono({
    double size = 15,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.geistMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  /// Small red uppercase label, e.g. "NOVEMBER 2026".
  static TextStyle eyebrow({Color color = AppColors.red}) {
    return GoogleFonts.geistMono(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.7,
      color: color,
    );
  }
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final textTheme = GoogleFonts.interTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);

  final radius6 = BorderRadius.circular(6);
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: radius6,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  final buttonText = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  final buttonShape = RoundedRectangleBorder(borderRadius: radius6);

  return base.copyWith(
    colorScheme: const ColorScheme.light(
      primary: AppColors.red,
      onPrimary: AppColors.white,
      secondary: AppColors.ink,
      onSecondary: AppColors.white,
      error: AppColors.red,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      outline: AppColors.inputBorder,
      outlineVariant: AppColors.line,
    ),
    scaffoldBackgroundColor: AppColors.white,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
      titleTextStyle: textTheme.titleLarge,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
      errorStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.red),
      border: border(AppColors.inputBorder),
      enabledBorder: border(AppColors.inputBorder),
      focusedBorder: border(AppColors.red, 2),
      errorBorder: border(AppColors.red),
      focusedErrorBorder: border(AppColors.red, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        shape: WidgetStatePropertyAll(buttonShape),
        textStyle: WidgetStatePropertyAll(buttonText),
        foregroundColor: const WidgetStatePropertyAll(AppColors.white),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.red.withValues(alpha: 0.6);
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered)) {
            return AppColors.redDark;
          }
          return AppColors.red;
        }),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: buttonText,
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.inputBorder),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: buttonShape,
        textStyle: buttonText,
        foregroundColor: AppColors.red,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.red,
      foregroundColor: AppColors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.white,
      selectedColor: AppColors.ink,
      checkmarkColor: AppColors.white,
      showCheckmark: false,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.inputBorder,
        ),
      ),
      labelStyle: WidgetStateTextStyle.resolveWith(
        (states) => GoogleFonts.inter(
          fontSize: 14,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.ink,
        ),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.red,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.white),
    ),
  );
}
