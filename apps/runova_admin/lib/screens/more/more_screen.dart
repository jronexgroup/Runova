import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../data/auth/auth_service.dart';
import '../../data/local/app_database.dart';
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
  List<WorkerAccount> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final workers = await AppDatabase.instance.getWorkers();
    if (mounted) setState(() => _workers = workers);
  }

  void _openAddWorkerModal() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provision Repair Worker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Worker Full Name (e.g. Subhash Ghosh)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: 'Worker Code (e.g. WORKER-1, W-02)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '4 to 6-digit Counter PIN',
                counterText: '',
              ),
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
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final code = codeCtrl.text.trim();
              final pin = pinCtrl.text.trim();

              if (name.isNotEmpty && code.isNotEmpty && pin.length >= 4) {
                await AuthService.instance.createWorker(name: name, workerCode: code, pin: pin);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadWorkers();
              }
            },
            child: const Text('Save Worker'),
          ),
        ],
      ),
    );
  }

  void _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end this shop shift session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.instance.signOut();
    }
  }

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
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tertiaryContainer),
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

            // 3. Worker Management (Admin Only)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BilingualText(
                  primary: 'Provisioned Repair Workers',
                  secondary: 'মেরামত কর্মী তালিকা ও পিন',
                  primaryStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('Add Worker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  onPressed: _openAddWorkerModal,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_workers.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.5),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.badge_outlined, size: 32, color: AppColors.outline),
                      SizedBox(height: 6),
                      Text(
                        'No repair technicians provisioned yet',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurfaceVariant),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'কাউন্টার পিন দিয়ে নতুন কর্মী যোগ করুন',
                        style: TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._workers.map((worker) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: worker.active
                            ? AppColors.tertiaryContainer.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHigh,
                        child: Icon(
                          Icons.person,
                          color: worker.active ? AppColors.tertiaryContainer : AppColors.outline,
                          size: 20,
                        ),
                      ),
                      title: Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${worker.workerCode} • Fast PIN Active'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: worker.active
                                  ? AppColors.tertiaryContainer.withValues(alpha: 0.1)
                                  : AppColors.outlineVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              worker.active ? 'ACTIVE' : 'DISABLED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: worker.active ? AppColors.tertiaryContainer : AppColors.outline,
                              ),
                            ),
                          ),
                          Switch(
                            value: worker.active,
                            onChanged: (val) async {
                              await AuthService.instance.toggleWorkerStatus(worker, val);
                              _loadWorkers();
                            },
                          ),
                        ],
                      ),
                    ),
                  )),

            const SizedBox(height: 20),

            // 4. Shop Identity & Session Information
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthService.instance.activeShopName.isNotEmpty
                                  ? AuthService.instance.activeShopName
                                  : 'Runova Shop',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Shop ID: ${AuthService.instance.activeShopId}',
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error, width: 0.8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        icon: const Icon(Icons.logout, size: 14),
                        label: const Text('Sign Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: _handleSignOut,
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'User: ${AuthService.instance.activeUserName} (${AuthService.instance.currentSession?.role.label ?? "Admin"})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Sync: ONLINE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tertiaryContainer)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }
}
