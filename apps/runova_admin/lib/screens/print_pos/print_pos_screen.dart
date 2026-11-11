import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

enum PrintTab { xerox, normal, photo, lamination }

class PrintPosScreen extends StatefulWidget {
  const PrintPosScreen({super.key});

  @override
  State<PrintPosScreen> createState() => _PrintPosScreenState();
}

class _PrintPosScreenState extends State<PrintPosScreen> {
  PrintTab activeTab = PrintTab.xerox;

  // Tab 1: Xerox state
  int xeroxQty = 4;

  // Tab 2: Normal Print state
  NormalPrintType normalType = NormalPrintType.imageBlackAndWhite;
  int normalQty = 1;

  // Tab 3: Passport Photo state
  int photoQty = 6;

  // Tab 4: Lamination state
  int laminationQty = 1;

  Money get currentTotal {
    switch (activeTab) {
      case PrintTab.xerox:
        return PrintPricingCalculator.calculateXerox(xeroxQty);
      case PrintTab.normal:
        return PrintPricingCalculator.calculateNormalPrint(type: normalType, quantity: normalQty);
      case PrintTab.photo:
        return PrintPricingCalculator.calculatePassportPhotos(photoQty);
      case PrintTab.lamination:
        return PrintPricingCalculator.calculateLamination(laminationQty);
    }
  }

  String get currentDescription {
    switch (activeTab) {
      case PrintTab.xerox:
        return 'Xerox • $xeroxQty Copies';
      case PrintTab.normal:
        return 'Normal Print • ${normalType.label} ($normalQty)';
      case PrintTab.photo:
        return 'Passport Photos • $photoQty Copies';
      case PrintTab.lamination:
        return 'Doc Lamination • $laminationQty Docs';
    }
  }

  int get currentQuantity {
    switch (activeTab) {
      case PrintTab.xerox:
        return xeroxQty;
      case PrintTab.normal:
        return normalQty;
      case PrintTab.photo:
        return photoQty;
      case PrintTab.lamination:
        return laminationQty;
    }
  }

  void _processPayment(TenderType tenderType) {
    if (currentTotal.isZero) return;

    final state = ShopState.instance;
    state.recordPrintTransaction(
      serviceDescription: currentDescription,
      quantity: currentQuantity,
      totalAmount: currentTotal,
      tenderType: tenderType,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.tertiaryContainer,
        content: Text(
          'Recorded $currentDescription for ${currentTotal.format()} via ${tenderType.label}!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Module Selector Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabBtn(PrintTab.xerox, 'Xerox', 'জেরক্স', Icons.copy),
                  const SizedBox(width: 8),
                  _tabBtn(PrintTab.normal, 'Normal Print', 'সাধারণ প্রিন্ট', Icons.description),
                  const SizedBox(width: 8),
                  _tabBtn(PrintTab.photo, 'Passport Photo', 'পাসপোর্ট ছবি', Icons.account_box),
                  const SizedBox(width: 8),
                  _tabBtn(PrintTab.lamination, 'Lamination', 'লেমিনেশন', Icons.layers),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Active Tab Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: _buildActiveTabContent(),
            ),
            const SizedBox(height: 14),

            // 3. POS Checkout Tender Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Payable', style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                          Text(currentDescription, style: AppTypography.labelMd),
                        ],
                      ),
                      Text(
                        currentTotal.format(),
                        style: AppTypography.displayNumericMobile.copyWith(
                          color: AppColors.primaryContainer,
                          fontSize: 26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Cash Button (Emerald)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tertiary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.payments, size: 20),
                            label: const Text('Cash • নগদ', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () => _processPayment(TenderType.cash),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // UPI Button (Sapphire)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            label: const Text('UPI / QR • কিউআর', style: TextStyle(fontWeight: FontWeight.w700)),
                            onPressed: () => _processPayment(TenderType.upi),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Recent Receipts & Reprint Ledger
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BilingualText(
                    primary: 'Recent POS Receipts',
                    secondary: 'সাম্প্রতিক প্রিন্ট ও জেরক্স রসিদ',
                    primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  if (state.printTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 28, color: AppColors.outline),
                          const SizedBox(height: 6),
                          Text(
                            'No receipts generated yet today',
                            style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'আজ এখনও কোনো প্রিন্ট বা জেরক্স রসিদ তৈরি হয়নি',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.printTransactions.take(5).map((txn) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      txn.receiptNumber,
                                      style: AppTypography.labelMd.copyWith(
                                        color: AppColors.primaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: txn.tenderType == TenderType.cash
                                            ? AppColors.secondaryContainer.withValues(alpha: 0.2)
                                            : AppColors.primaryContainer.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        txn.tenderType.label,
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(txn.serviceDescription, style: AppTypography.bodySm),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  txn.totalAmount.format(),
                                  style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    side: const BorderSide(color: AppColors.outlineVariant),
                                  ),
                                  icon: const Icon(Icons.print, size: 14, color: AppColors.primary),
                                  label: const Text('Reprint', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Reprinting thermal receipt ${txn.receiptNumber}...')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _tabBtn(PrintTab tab, String label, String bengali, IconData icon) {
    final isSelected = activeTab == tab;
    return InkWell(
      onTap: () => setState(() => activeTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.onSurfaceVariant),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.onSurface,
                  ),
                ),
                Text(
                  bengali,
                  style: TextStyle(
                    fontSize: 9,
                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (activeTab) {
      case PrintTab.xerox:
        final pairs = xeroxQty ~/ 2;
        final remainder = xeroxQty % 2;
        final formulaText = xeroxQty > 0
            ? '$xeroxQty Pages = $pairs pairs @ ₹5 ${remainder > 0 ? "+ 1 odd @ ₹3" : ""} = ${currentTotal.format()}'
            : '0 Pages = ₹0';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BilingualText(
              primary: 'Xerox Photocopy (Tiered Pricing)',
              secondary: 'জেরক্স মূল্যতালিকা: ১ পাতা ₹৩, ২ পাতা ₹৫',
              primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),

            // Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepBtn(Icons.remove, () {
                  if (xeroxQty > 0) setState(() => xeroxQty--);
                }),
                Column(
                  children: [
                    Text(
                      '$xeroxQty',
                      style: AppTypography.displayNumericMobile.copyWith(fontSize: 32),
                    ),
                    const Text('Pages / Copies', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                _stepBtn(Icons.add, () => setState(() => xeroxQty++)),
              ],
            ),
            const SizedBox(height: 12),

            // Quick increment chips (+1, +2, +5, +10, +20)
            Row(
              children: [1, 2, 5, 10, 20].map((step) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: AppColors.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => setState(() => xeroxQty += step),
                      child: Text('+$step', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Formula banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formulaText, style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600)),
                  Text(currentTotal.format(), style: AppTypography.headlineSm.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        );

      case PrintTab.normal:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BilingualText(
              primary: 'Normal Document Print',
              secondary: 'ছবি ও পিডিএফ প্রিন্টিং অপশন',
              primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: NormalPrintType.values.map((type) {
                final isSelected = normalType == type;
                return InkWell(
                  onTap: () => setState(() => normalType = type),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${type.unitPrice.format()}/copy',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepBtn(Icons.remove, () {
                  if (normalQty > 1) setState(() => normalQty--);
                }),
                Text('$normalQty Copies', style: AppTypography.headlineSm),
                _stepBtn(Icons.add, () => setState(() => normalQty++)),
              ],
            ),
          ],
        );

      case PrintTab.photo:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BilingualText(
              primary: 'Passport-Size Photos (Multiples of 3)',
              secondary: '৩ কপি ₹২০, প্রতি অতিরিক্ত ৩ কপি ₹১৫',
              primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [3, 6, 9, 12, 15].map((count) {
                final isSelected = photoQty == count;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
                        foregroundColor: isSelected ? Colors.white : AppColors.onSurface,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => setState(() => photoQty = count),
                      child: Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepBtn(Icons.remove, () {
                  if (photoQty > 3) setState(() => photoQty -= 3);
                }),
                Text('$photoQty Photos', style: AppTypography.headlineSm),
                _stepBtn(Icons.add, () => setState(() => photoQty += 3)),
              ],
            ),
          ],
        );

      case PrintTab.lamination:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BilingualText(
              primary: 'Large Document Lamination',
              secondary: 'বড় নথিপত্র লেমিনেশন (প্রতিটি ₹৫০)',
              primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _stepBtn(Icons.remove, () {
                  if (laminationQty > 1) setState(() => laminationQty--);
                }),
                Text('$laminationQty Documents', style: AppTypography.headlineSm),
                _stepBtn(Icons.add, () => setState(() => laminationQty++)),
              ],
            ),
          ],
        );
    }
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.onSurface),
      ),
    );
  }
}
