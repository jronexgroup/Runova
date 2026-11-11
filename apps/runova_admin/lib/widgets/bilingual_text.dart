import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Renders primary English text stacked with a secondary Bengali label underneath.
class BilingualText extends StatelessWidget {
  final String primary;
  final String secondary;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final CrossAxisAlignment crossAxisAlignment;

  const BilingualText({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryStyle,
    this.secondaryStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          style: primaryStyle ?? AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        ),
        const SizedBox(height: 1),
        Text(
          secondary,
          style: secondaryStyle ?? AppTypography.labelSecondaryBilingual,
        ),
      ],
    );
  }
}
