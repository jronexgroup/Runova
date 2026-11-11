import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runova_core/runova_core.dart';
import '../theme/app_colors.dart';

/// Status indicator chip conforming to Counter Precision design specs.
class StatusChip extends StatelessWidget {
  final RepairStatus status;
  final bool showBengaliSubtitle;

  const StatusChip({
    super.key,
    required this.status,
    this.showBengaliSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case RepairStatus.inspected:
        bg = AppColors.statusInspectedBg;
        border = AppColors.statusInspectedBorder;
        text = AppColors.statusInspectedText;
        break;
      case RepairStatus.partBought:
        bg = AppColors.statusPartBoughtBg;
        border = AppColors.statusPartBoughtBorder;
        text = AppColors.statusPartBoughtText;
        break;
      case RepairStatus.done:
        bg = AppColors.statusDoneBg;
        border = AppColors.statusDoneBorder;
        text = AppColors.statusDoneText;
        break;
      case RepairStatus.delivered:
        bg = AppColors.statusDeliveredBg;
        border = AppColors.statusDeliveredBorder;
        text = AppColors.statusDeliveredText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: text,
            ),
          ),
          if (showBengaliSubtitle)
            Text(
              status.labelBengali,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: text.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}
