import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/status_chip.dart';
import 'delivery_modal.dart';

class RepairsScreen extends StatefulWidget {
  const RepairsScreen({super.key});

  @override
  State<RepairsScreen> createState() => _RepairsScreenState();
}

class _RepairsScreenState extends State<RepairsScreen> {
  RepairStatus? selectedFilter;
  final Set<String> playingAudioNotes = {};

  void _openDeliveryModal(RepairTicket ticket) async {
    final invoice = await showModalBottomSheet<Invoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryModal(ticket: ticket),
    );

    if (invoice != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.tertiaryContainer),
              SizedBox(width: 8),
              Text('Delivery Confirmed!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invoice: ${invoice.invoiceNumber}', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Customer: ${invoice.customerName}'),
              Text('Device: ${invoice.deviceName}'),
              Text('Payment Received: ${invoice.totalAmount.format()}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.print, size: 16),
              label: const Text('Print Invoice'),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Printing PDF Invoice ${invoice.invoiceNumber}...')),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final filteredTickets = state.repairTickets.where((t) {
          if (selectedFilter == null) return true;
          return t.status == selectedFilter;
        }).toList();

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Search Bar
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, size: 20, color: AppColors.outline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search ticket #, device, or phone...',
                      style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                  Icon(Icons.qr_code_scanner, size: 20, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Status Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterPill(
                    label: 'All (${state.repairTickets.length})',
                    isSelected: selectedFilter == null,
                    onTap: () => setState(() => selectedFilter = null),
                  ),
                  ...RepairStatus.values.map((status) {
                    final count = state.repairTickets.where((t) => t.status == status).length;
                    return _filterPill(
                      label: '${status.label} ($count)',
                      isSelected: selectedFilter == status,
                      onTap: () => setState(() => selectedFilter = status),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Ticket Cards
            ...filteredTickets.map((ticket) {
              final isDone = ticket.status == RepairStatus.done;
              final isDelivered = ticket.status == RepairStatus.delivered;
              final hasAudio = ticket.audioUrl != null;
              final isAudioPlaying = playingAudioNotes.contains(ticket.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDone ? AppColors.statusDoneBorder : AppColors.outlineVariant,
                    width: isDone ? 1.5 : 0.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Ticket ID, SLA, Status Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              ticket.id,
                              style: AppTypography.labelLg.copyWith(
                                fontWeight: FontWeight.w800,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Worker: ${ticket.assignedWorkerId ?? "Unassigned"}',
                                style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        StatusChip(status: ticket.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Device & Issue
                    Text(ticket.deviceName, style: AppTypography.headlineSm.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      'Reported: ${ticket.reportedProblem}',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      'Inspection: ${ticket.inspectedProblem}',
                      style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),

                    // Audio Note preview if present
                    if (hasAudio) ...[
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isAudioPlaying) {
                              playingAudioNotes.remove(ticket.id);
                            } else {
                              playingAudioNotes.add(ticket.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isAudioPlaying ? 'Playing Audio Note...' : 'Audio Note (0:18) • ভয়েস রেকর্ড',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Parts Recorded (Admin view)
                    if (ticket.parts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Part: ${ticket.parts.first.description}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            Text(
                              'Cost: ${ticket.totalPartsCost.format()}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),

                    // Bottom Row: Customer Info & Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.customerName ?? 'No customer assigned',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            if (ticket.customerPhone != null)
                              Text(
                                ticket.customerPhone!,
                                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                          ],
                        ),

                        if (isDone)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.local_shipping, size: 16),
                            label: const Text('Deliver & Collect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            onPressed: () => _openDeliveryModal(ticket),
                          )
                        else if (isDelivered)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.statusDoneBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 14, color: AppColors.statusDoneText),
                                const SizedBox(width: 4),
                                Text(
                                  'Delivered • ${ticket.customerPayment?.format() ?? ""}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.statusDoneText),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Awaiting Done status',
                              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _filterPill({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primaryContainer,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.onSurface,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
