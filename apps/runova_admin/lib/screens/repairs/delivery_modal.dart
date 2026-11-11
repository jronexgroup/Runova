import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

/// Modal for Admin to confirm repair delivery and generate repair invoice (PRD 6.3.4).
class DeliveryModal extends StatefulWidget {
  final RepairTicket ticket;

  const DeliveryModal({super.key, required this.ticket});

  @override
  State<DeliveryModal> createState() => _DeliveryModalState();
}

class _DeliveryModalState extends State<DeliveryModal> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _amountController;

  Money paymentAmount = Money.fromRupees(1000);
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ticket.customerName ?? '');
    _phoneController = TextEditingController(text: widget.ticket.customerPhone ?? '');
    _amountController = TextEditingController(text: '1000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final parsed = double.tryParse(val) ?? 0;
    setState(() {
      paymentAmount = Money.fromRupees(parsed);
      errorMessage = null;
    });
  }

  void _confirmDelivery() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    final validationError = RepairTicket.validateDeliveryPrerequisites(
      currentStatus: widget.ticket.status,
      customerName: name,
      paymentAmount: paymentAmount,
    );

    if (validationError != null) {
      setState(() => errorMessage = validationError);
      return;
    }

    try {
      final state = ShopState.instance;
      final invoice = state.deliverRepair(
        ticket: widget.ticket,
        customerName: name,
        customerPhone: phone.isNotEmpty ? phone : null,
        paymentAmount: paymentAmount,
      );

      Navigator.pop(context, invoice);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPartsCost = widget.ticket.totalPartsCost;
    final netProfit = paymentAmount - totalPartsCost;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      BilingualText(
                        primary: 'Delivery & Invoice (${widget.ticket.id})',
                        secondary: 'ডেলিভারি নিশ্চিতকরণ ও ইনভয়েস তৈরি',
                        primaryStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Device & Findings Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.ticket.deviceName, style: AppTypography.headlineSm),
                    const SizedBox(height: 2),
                    Text(
                      'Work: ${widget.ticket.inspectedProblem}',
                      style: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Internal Parts Cost: ${totalPartsCost.format()}',
                      style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Customer Name Input (Mandatory at delivery)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name (Required) / গ্রাহকের নাম *',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              // Customer Phone Input (Optional)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Customer Phone (Optional) / ফোন নম্বর',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),

              // Payment Amount Input (Mandatory positive)
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Amount Received (₹) / প্রাপ্ত টাকা *',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: AppColors.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: _onAmountChanged,
              ),
              const SizedBox(height: 12),

              // Profit Calculation Preview
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Net Repair Profit (PRD 6.3.5):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        Text(
                          '${paymentAmount.format()} - ${totalPartsCost.format()} parts',
                          style: AppTypography.bodySm,
                        ),
                      ],
                    ),
                    Text(
                      netProfit.format(),
                      style: AppTypography.headlineSm.copyWith(
                        color: netProfit.isPositive ? AppColors.tertiaryContainer : AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],

              const SizedBox(height: 18),

              // Delivery Execution Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle, size: 22),
                  label: const Text(
                    'Confirm Delivery & Issue Invoice',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: _confirmDelivery,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
