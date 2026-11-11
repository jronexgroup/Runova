import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bilingual_text.dart';

/// Visual Split Ratio Bar showing Cash vs UPI metrics (from Dashboard prototype).
class TenderSplitBar extends StatelessWidget {
  final Money cashAmount;
  final Money upiAmount;

  const TenderSplitBar({
    super.key,
    required this.cashAmount,
    required this.upiAmount,
  });

  @override
  Widget build(BuildContext context) {
    final totalPaise = cashAmount.paise + upiAmount.paise;
    final totalMoney = Money.fromPaise(totalPaise);

    final cashPercent = totalPaise > 0 ? (cashAmount.paise / totalPaise) : 0.5;
    final upiPercent = totalPaise > 0 ? (upiAmount.paise / totalPaise) : 0.5;

    final cashDisplayPct = (cashPercent * 100).toStringAsFixed(1);
    final upiDisplayPct = (upiPercent * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  const BilingualText(
                    primary: 'Tender Split',
                    secondary: 'নগদ ও ইউপিআই অনুপাত',
                    primaryStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              Text(
                totalMoney.format(),
                style: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Split Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (cashPercent * 1000).toInt().clamp(1, 999),
                    child: Container(color: AppColors.secondaryContainer),
                  ),
                  Expanded(
                    flex: (upiPercent * 1000).toInt().clamp(1, 999),
                    child: Container(color: AppColors.primaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cash: ${cashAmount.format()} ($cashDisplayPct%)',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'UPI: ${upiAmount.format()} ($upiDisplayPct%)',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
