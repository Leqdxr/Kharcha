import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// The red piggy bank icon followed by "Kharcha".
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 30});

  /// Size of the piggy bank icon. The word scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kharcha',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/piggy-bank.svg',
            width: size,
            height: size,
          ),
          SizedBox(width: size * 0.33),
          Text(
            'Kharcha',
            style: GoogleFonts.onest(
              fontSize: size * 0.66,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
