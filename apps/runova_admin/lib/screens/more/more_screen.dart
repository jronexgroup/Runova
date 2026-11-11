import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../state/shop_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bilingual_text.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  void _openAddExpenseModal() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String category = 'Printing supplies';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Operating Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Expense Title (e.g. Paper Ream)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: const [
                DropdownMenuItem(value: 'Printing supplies', child: Text('Printing supplies')),
                DropdownMenuItem(value: 'Shop maintenance', child: Text('Shop maintenance')),
                DropdownMenuItem(value: 'General expense', child: Text('General expense')),
              ],
              onChanged: (val) => category = val ?? category,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (title.isNotEmpty && amount > 0) {
                final state = ShopState.instance;
                state.addExpense(
                  title: title,
                  category: category,
                  amount: Money.fromRupees(amount),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Expense'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ShopState.instance;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final totalCollected = state.cashCollected + state.upiCollected;

        // Calculate total recorded expenses
        final totalExpenses = state.expenses.fold<Money>(
          Money.zero,
          (sum, exp) => sum + exp.amount,
        );

        // Calculate repair parts costs for delivered repairs
        final deliveredRepairs = state.repairTickets.where((t) => t.status == RepairStatus.delivered);
        final totalRepairCost = deliveredRepairs.fold<Money>(
          Money.zero,
          (sum, t) => sum + t.totalPartsCost,
        );

        final netShopProfit = totalCollected - totalExpenses - totalRepairCost;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Shift Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BilingualText(
                        primary: 'Current Shift Financials',
                        secondary: 'চলতি শিফটের মোট হিসাব',
                        primaryStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${state.counterName} ACTIVE',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Revenue Collected:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(totalCollected.format(), style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Operating Expenses Recorded:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(totalExpenses.format(), style: AppTypography.labelLg.copyWith(color: AppColors.error)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Repair Parts Costs (Delivered):', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(totalRepairCost.format(), style: AppTypography.labelLg.copyWith(color: AppColors.error)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Business Surplus:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(
                        netShopProfit.format(),
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.tertiaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Expenses Management Header & Add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BilingualText(
                  primary: 'General Shop Expenses',
                  secondary: 'দোকানের সাধারণ খরচ',
                  primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Expense', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: _openAddExpenseModal,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Expenses List
            if (state.expenses.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.outline),
                      SizedBox(height: 8),
                      Text(
                        'No operating expenses recorded today',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'আজ কোনো দোকান খরচ রেকর্ড করা হয়নি',
                        style: TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...state.expenses.map((exp) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.surfaceContainerHigh,
                        child: Icon(Icons.receipt, color: AppColors.primary, size: 20),
                      ),
                      title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${exp.category} • ${exp.date.hour}:${exp.date.minute.toString().padLeft(2, '0')}'),
                      trailing: Text(
                        exp.amount.format(),
                        style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700, color: AppColors.error),
                      ),
                    ),
                  )),

            const SizedBox(height: 20),

            // 3. User & Access Information
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
                  const Text('System & Security Access', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  const Text(
                    'Logged in as Shop Owner (Admin) with full financial and invoice generation authority.',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('1 Active Worker: WORKER-1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Local SQLite Sync: ONLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tertiaryContainer)),
                      ),
                    ],
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
}
