import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Shown instead of a list's header while rows are selected:
/// close, "3 selected", Select all and Delete.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.allSelected,
    required this.onClose,
    required this.onSelectAll,
    required this.onDelete,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Stop selecting',
          icon: const Icon(Icons.close),
          onPressed: onClose,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              '$count selected',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (!allSelected)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            onPressed: onSelectAll,
            child: const Text('Select all'),
          ),
        TextButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}

/// The square in front of a row while selecting.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      child: Icon(
        selected ? Icons.check_box : Icons.check_box_outline_blank,
        color: selected ? AppColors.red : AppColors.muted,
      ),
    );
  }
}
