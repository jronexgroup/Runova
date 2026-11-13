import 'package:flutter/foundation.dart';
import 'package:runova_core/runova_core.dart';
import '../data/auth/worker_auth_service.dart';
import '../data/local/worker_database.dart';
import '../data/sync/worker_sync_service.dart';

class WorkerState extends ChangeNotifier {
  static final WorkerState instance = WorkerState._();
  WorkerState._();

  bool isInitialized = false;
  final List<RepairTicket> tickets = [];

  List<RepairTicket> get myQueue {
    final currentCode = WorkerAuthService.instance.activeWorkerCode;
    return tickets.where((t) => t.assignedWorkerId == currentCode).toList();
  }

  List<RepairTicket> get unassignedPool {
    return tickets.where((t) => t.assignedWorkerId == null || t.assignedWorkerId!.isEmpty).toList();
  }

  Future<void> init({bool force = false}) async {
    if (isInitialized && !force) return;

    tickets.clear();
    tickets.addAll(await WorkerDatabase.instance.getTickets());

    isInitialized = true;
    notifyListeners();

    final shopId = WorkerAuthService.instance.activeShopId;
    if (shopId.isNotEmpty) {
      WorkerSyncService.instance.drainOutbox(shopId);
    }
  }

  /// Worker claims an unassigned ticket into their personal queue.
  Future<void> claimTicket(String ticketId) async {
    final index = tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final workerCode = WorkerAuthService.instance.activeWorkerCode;
    final now = DateTime.now();

    final updated = tickets[index].copyWith(
      assignedWorkerId: workerCode,
      updatedAt: now,
    );

    tickets[index] = updated;
    notifyListeners();

    final shopId = WorkerAuthService.instance.activeShopId;
    await WorkerDatabase.instance.upsertTicket(updated, shopId);
    WorkerSyncService.instance.drainOutbox(shopId);
  }

  /// Worker advances intermediate status: Inspected -> Part Bought -> Done.
  /// Hard RBAC Guard: Delivered is strictly prohibited.
  Future<void> advanceStatus(String ticketId, RepairStatus targetStatus) async {
    if (targetStatus == RepairStatus.delivered) {
      throw StateError('Technicians cannot mark tickets as Delivered. Delivery and invoice generation is restricted strictly to Shop Admin.');
    }

    final index = tickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final ticket = tickets[index];

    // Enforce role permission check
    if (!ticket.canTransitionTo(targetStatus, UserRole.worker)) {
      throw StateError('Invalid status transition for Worker: ${ticket.status.label} -> ${targetStatus.label}');
    }

    final updated = ticket.copyWith(
      status: targetStatus,
      updatedAt: DateTime.now(),
    );

    tickets[index] = updated;
    notifyListeners();

    final shopId = WorkerAuthService.instance.activeShopId;
    await WorkerDatabase.instance.upsertTicket(updated, shopId);
    WorkerSyncService.instance.drainOutbox(shopId);
  }

  /// Technician registers a new repair intake job directly from workbench.
  Future<RepairTicket> registerRepairTicket({
    required String deviceName,
    required String reportedProblem,
    required String inspectedProblem,
    required String description,
    String? customerName,
    String? customerPhone,
    String? audioUrl,
    bool selfAssign = true,
  }) async {
    final now = DateTime.now();
    final nextId = 'REP-${now.millisecondsSinceEpoch % 100000}';
    final workerCode = WorkerAuthService.instance.activeWorkerCode;

    final ticket = RepairTicket(
      id: nextId,
      deviceName: deviceName.trim(),
      reportedProblem: reportedProblem.trim(),
      inspectedProblem: inspectedProblem.trim(),
      description: description.trim(),
      audioUrl: audioUrl,
      status: RepairStatus.inspected,
      assignedWorkerId: selfAssign && workerCode.isNotEmpty ? workerCode : null,
      customerName: customerName?.trim().isNotEmpty == true ? customerName!.trim() : null,
      customerPhone: customerPhone?.trim().isNotEmpty == true ? customerPhone!.trim() : null,
      parts: const [], // Zero financial information
      createdAt: now,
      updatedAt: now,
    );

    tickets.insert(0, ticket);
    notifyListeners();

    final shopId = WorkerAuthService.instance.activeShopId;
    await WorkerDatabase.instance.upsertTicket(ticket, shopId);
    WorkerSyncService.instance.drainOutbox(shopId);
    return ticket;
  }
}
