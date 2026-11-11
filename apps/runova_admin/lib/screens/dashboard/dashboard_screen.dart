import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/tender_split_bar.dart';
import 'quick_xerox_tray.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateToTab;

  const DashboardScreen({super.key, required this.onNavigateToTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool showXeroxTray = false;

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final totalSales = state.cashCollected + state.upiCollected;
        final pendingRepairs = state.repairTickets.where((t) => !t.status.isDelivered).length;
        final readyForDelivery = state.repairTickets.where((t) => t.status.isDone).length;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Shift & Status Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Today, ${DateFormat('d MMM').format(DateTime.now())}',
                                style: AppTypography.headlineSm,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.tertiaryFixedDim,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${state.counterName} Open',
                                      style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'আজকের শিফট • কাউন্টার ১ চালু আছে',
                            style: AppTypography.labelSecondaryBilingual,
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      side: const BorderSide(color: AppColors.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.sync_alt, size: 16, color: AppColors.primary),
                    label: const Text('Shift', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shift sync completed with cloud database.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Tender Split Bar
            TenderSplitBar(
              cashAmount: state.cashCollected,
              upiAmount: state.upiCollected,
            ),
            const SizedBox(height: 12),

            // 3. Quick Action Launchers
            Row(
              children: [
                Expanded(
                  child: _quickActionButton(
                    icon: Icons.print,
                    title: 'Quick Xerox',
                    subtitle: 'তাত্ক্ষণিক জেরক্স',
                    color: AppColors.primaryContainer,
                    onTap: () {
                      setState(() {
                        showXeroxTray = !showXeroxTray;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickActionButton(
                    icon: Icons.search,
                    title: 'Cover Finder',
                    subtitle: 'কভার সামঞ্জস্য',
                    color: AppColors.secondaryContainer,
                    onTap: () => widget.onNavigateToTab(1), // Go to Retail tab
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickActionButton(
                    icon: Icons.build,
                    title: 'Repairs ($readyForDelivery Ready)',
                    subtitle: 'মেরামত ডেলিভারি',
                    color: AppColors.tertiaryContainer,
                    onTap: () => widget.onNavigateToTab(3), // Go to Repairs tab
                  ),
                ),
              ],
            ),

            // Collapsible Quick Xerox Drawer
            if (showXeroxTray)
              QuickXeroxTray(
                onClose: () => setState(() => showXeroxTray = false),
              ),

            const SizedBox(height: 14),

            // 4. Financial KPI Cards Grid
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'Today Collected',
                    bilingual: 'আজকের মোট বিক্রয়',
                    amount: totalSales.format(),
                    icon: Icons.payments,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _metricCard(
                    title: 'Active Repairs',
                    bilingual: 'চলমান মেরামত কাজ',
                    amount: '$pendingRepairs Jobs',
                    icon: Icons.engineering,
                    color: AppColors.secondary,
                    subtitleDetail: '$readyForDelivery ready to deliver',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 5. Active Repair Delivery Spotlight
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BilingualText(
                        primary: 'Ready for Delivery',
                        secondary: 'ডেলিভারির জন্য প্রস্তুত টিকিট',
                        primaryStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigateToTab(3),
                        child: const Text('View All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (state.repairTickets.where((t) => t.status == RepairStatus.done).isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 28, color: AppColors.outline),
                          const SizedBox(height: 6),
                          Text(
                            'All caught up! No repairs awaiting delivery',
                            style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'ডেলিভারির জন্য কোনো মেরামত কাজ অপেক্ষমাণ নেই',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  else
                    ...state.repairTickets
                        .where((t) => t.status == RepairStatus.done)
                        .take(2)
                        .map((ticket) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.statusDoneBorder.withValues(alpha: 0.5)),
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
                                          ticket.id,
                                          style: AppTypography.labelMd.copyWith(
                                            fontFeatures: const [FontFeature.tabularFigures()],
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        StatusChip(status: ticket.status, showBengaliSubtitle: false),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(ticket.deviceName, style: AppTypography.headlineSm),
                                    Text(
                                      'Customer: ${ticket.customerName ?? "Not confirmed"}',
                                      style: AppTypography.bodySm,
                                    ),
                                  ],
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryContainer,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline, size: 16),
                                  label: const Text('Deliver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                  onPressed: () => widget.onNavigateToTab(3),
                                ),
                              ],
                            ),
                          )),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 6. End Shift Close Prompt
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_clock, color: AppColors.primary, size: 24),
                      const SizedBox(width: 10),
                      const BilingualText(
                        primary: 'End Shift Audit',
                        secondary: 'দিনের হিসাব মিলিয়ে ক্যাশ ক্লোজ করুন',
                        primaryStyle: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Shift closing summary generated: Total Tender ${totalSales.format()}',
                          ),
                        ),
                      );
                    },
                    child: const Text('Audit Shift', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.outlineVariant, width: 0.5),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMd.copyWith(fontSize: 11),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.labelSecondaryBilingual.copyWith(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String bilingual,
    required String amount,
    required IconData icon,
    required Color color,
    String? subtitleDetail,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BilingualText(
                primary: title,
                secondary: bilingual,
                primaryStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: AppTypography.displayNumericMobile.copyWith(
              color: AppColors.onSurface,
              fontSize: 22,
            ),
          ),
          if (subtitleDetail != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitleDetail,
              style: AppTypography.bodySm.copyWith(color: AppColors.tertiaryContainer, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
