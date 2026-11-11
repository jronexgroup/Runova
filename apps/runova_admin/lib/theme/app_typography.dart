import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Counter Precision Typography Tokens (Inter with Tabular Figures)
class AppTypography {
  static TextStyle get displayNumeric => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
        letterSpacing: -0.02 * 36,
        color: AppColors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get displayNumericMobile => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.01 * 28,
        color: AppColors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle get headlineLg => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.01 * 28,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineLgMobile => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 28 / 22,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineMd => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        color: AppColors.onSurface,
      );

  static TextStyle get headlineSm => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: AppColors.onSurface,
      );

  static TextStyle get bodySm => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get labelLg => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: AppColors.onSurface,
      );

  static TextStyle get labelMd => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        color: AppColors.onSurface,
      );

  static TextStyle get labelSecondaryBilingual => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get numericKeypad => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 32 / 24,
        color: AppColors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
