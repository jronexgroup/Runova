import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

/// One-tap collapsible Xerox Quick-Tray on the Dashboard.
class QuickXeroxTray extends StatefulWidget {
  final VoidCallback onClose;

  const QuickXeroxTray({super.key, required this.onClose});

  @override
  State<QuickXeroxTray> createState() => _QuickXeroxTrayState();
}

class _QuickXeroxTrayState extends State<QuickXeroxTray> {
  int bwCount = 1;
  int colorCount = 0;
  bool isSuccess = false;

  Money get total {
    final bwMoney = PrintPricingCalculator.calculateXerox(bwCount);
    final colorMoney = Money.fromRupees(colorCount * 5);
    return bwMoney + colorMoney;
  }

  void _collect() {
    if (total.isZero) return;

    final state = ShopState.instance;
    state.recordPrintTransaction(
      serviceDescription: 'Quick Xerox • $bwCount B&W, $colorCount Colour',
      quantity: bwCount + colorCount,
      totalAmount: total,
      tenderType: TenderType.cash,
    );

    setState(() {
      isSuccess = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.3), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1200288E),
            blurRadius: 8,
            offset: Offset(0, 3),
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
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.print, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const BilingualText(
                    primary: 'Quick Xerox POS',
                    secondary: 'তাত্ক্ষণিক জেরক্স কাউন্টার',
                    primaryStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: widget.onClose,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stepper Row
          Row(
            children: [
              // B&W Stepper
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'B&W (Tiered)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleBtn(
                            icon: Icons.remove,
                            onTap: () {
                              if (bwCount > 0) setState(() => bwCount--);
                            },
                          ),
                          Text(
                            '$bwCount',
                            style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          _circleBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => bwCount++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Colour Stepper
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Colour (₹5)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _circleBtn(
                            icon: Icons.remove,
                            onTap: () {
                              if (colorCount > 0) setState(() => colorCount--);
                            },
                          ),
                          Text(
                            '$colorCount',
                            style: AppTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          _circleBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => colorCount++),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Total & Collect Action
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Calculated', style: AppTypography.bodySm),
                    Text(
                      total.format(),
                      style: AppTypography.displayNumericMobile.copyWith(
                        color: AppColors.primaryContainer,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.tertiaryContainer : AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: Icon(isSuccess ? Icons.check : Icons.payments, size: 18),
                  label: Text(
                    isSuccess ? 'Recorded! ✓' : 'Collect ${total.format()}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  onPressed: isSuccess ? null : _collect,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.onSurface),
      ),
    );
  }
}
