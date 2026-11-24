import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// The red "K" square followed by "Kharcha".
class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 32});

  /// Size of the red square. The word scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kharcha',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.red,
              borderRadius: BorderRadius.circular(size * 0.19),
            ),
            child: Text(
              'K',
              style: AppText.mono(
                size: size * 0.56,
                weight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          SizedBox(width: size * 0.31),
          Text(
            'Kharcha',
            style: GoogleFonts.ibmPlexSans(
              fontSize: size * 0.625,
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
