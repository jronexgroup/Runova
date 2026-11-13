import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import '../../data/auth/worker_auth_service.dart';
import '../../state/worker_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/status_chip.dart';
import 'intake_modal.dart';

class WorkerWorkbenchScreen extends StatefulWidget {
  const WorkerWorkbenchScreen({super.key});

  @override
  State<WorkerWorkbenchScreen> createState() => _WorkerWorkbenchScreenState();
}

class _WorkerWorkbenchScreenState extends State<WorkerWorkbenchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openIntakeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const IntakeModal(),
    );
  }

  void _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Technician Shift'),
        content: const Text('Are you sure you want to sign out of this technician bench session?'),
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
      await WorkerAuthService.instance.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = WorkerAuthService.instance;
    final workerState = WorkerState.instance;

    return AnimatedBuilder(
      animation: Listenable.merge([auth, workerState]),
      builder: (context, _) {
        final myQueue = workerState.myQueue;
        final unassigned = workerState.unassignedPool;

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: AppColors.surfaceContainerLowest,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.activeShopName.isNotEmpty ? auth.activeShopName : 'Runova Shop',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  '${auth.activeWorkerName} • ${auth.activeWorkerCode}',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.error),
                tooltip: 'Sign Out',
                onPressed: _confirmSignOut,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.secondaryContainer,
              unselectedLabelColor: AppColors.outline,
              indicatorColor: AppColors.secondaryContainer,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('My Queue • আমার কাজ'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${myQueue.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Unassigned Pool • খালি কাজ'),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${unassigned.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildTicketList(myQueue, isMyQueue: true),
              _buildTicketList(unassigned, isMyQueue: false),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.secondaryContainer,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New Intake • নতুন মেরামত', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _openIntakeModal,
          ),
        );
      },
    );
  }

  Widget _buildTicketList(List<RepairTicket> list, {required bool isMyQueue}) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMyQueue ? Icons.assignment_turned_in_outlined : Icons.inbox_outlined,
                size: 48,
                color: AppColors.outline,
              ),
              const SizedBox(height: 12),
              Text(
                isMyQueue
                    ? 'No repair jobs currently assigned to you'
                    : 'No unassigned tickets in the shop pool',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isMyQueue
                    ? 'Check the Unassigned Pool or register a new intake.'
                    : 'All customer devices are currently claimed by technicians.',
                style: const TextStyle(fontSize: 12, color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final ticket = list[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.deviceName,
                        style: AppTypography.headlineSm.copyWith(fontSize: 16),
                      ),
                    ),
                    StatusChip(status: ticket.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket.id} • ${ticket.createdAt.day}/${ticket.createdAt.month} ${ticket.createdAt.hour}:${ticket.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: AppColors.outline, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 16),

                // Problem Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reported: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(ticket.reportedProblem, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Inspected: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Expanded(
                      child: Text(ticket.inspectedProblem, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),

                if (ticket.customerName != null && ticket.customerName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${ticket.customerName} (${ticket.customerPhone ?? "No phone"})',
                        style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Action Area
                if (!isMyQueue)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.touch_app, size: 16),
                    label: const Text('Claim This Job • কাজটি গ্রহণ করুন', style: TextStyle(fontWeight: FontWeight.w700)),
                    onPressed: () => WorkerState.instance.claimTicket(ticket.id),
                  )
                else ...[
                  if (ticket.status == RepairStatus.inspected)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Mark Part Bought • যন্ত্রাংশ কেনা হয়েছে', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => WorkerState.instance.advanceStatus(ticket.id, RepairStatus.partBought),
                    )
                  else if (ticket.status == RepairStatus.partBought)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tertiaryContainer,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Mark Repair Done • কাজ সম্পন্ন', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () => WorkerState.instance.advanceStatus(ticket.id, RepairStatus.done),
                    )
                  else if (ticket.status == RepairStatus.done)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'Ready for Delivery • দোকান মালিক কর্তৃক বিতরণ সম্পন্ন হবে',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tertiaryContainer),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
