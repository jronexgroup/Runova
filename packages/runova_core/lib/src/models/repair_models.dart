import '../money/money.dart';
import 'user_role.dart';

/// The 4 standard statuses in the repair lifecycle (PRD 6.3.2).
enum RepairStatus {
  inspected('Inspected', 'পরীক্ষিত', 1),
  partBought('Part Bought', 'যন্ত্রাংশ কেনা হয়েছে', 2),
  done('Done', 'কাজ সম্পন্ন', 3),
  delivered('Delivered', 'বিতরণ সম্পন্ন', 4);

  final String label;
  final String labelBengali;
  final int stepIndex;

  const RepairStatus(this.label, this.labelBengali, this.stepIndex);

  bool get isDelivered => this == RepairStatus.delivered;
  bool get isDone => this == RepairStatus.done;
}

/// Repair part recorded by Admin (PRD 6.3.3).
class RepairPart {
  final String id;
  final String repairId;
  final String description;
  final Money cost;
  final DateTime createdAt;

  const RepairPart({
    required this.id,
    required this.repairId,
    required this.description,
    required this.cost,
    required this.createdAt,
  });
}

/// Mobile Repair Service Ticket (PRD 6.3).
class RepairTicket {
  final String id;
  final String deviceName;
  final String reportedProblem;
  final String inspectedProblem;
  final String description;
  final String? audioUrl;
  final RepairStatus status;
  final String? assignedWorkerId;
  final String? customerName;
  final String? customerPhone;
  final List<RepairPart> parts;
  final Money? customerPayment;
  final String? deliveredBy;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RepairTicket({
    required this.id,
    required this.deviceName,
    required this.reportedProblem,
    required this.inspectedProblem,
    required this.description,
    this.audioUrl,
    required this.status,
    this.assignedWorkerId,
    this.customerName,
    this.customerPhone,
    this.parts = const [],
    this.customerPayment,
    this.deliveredBy,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total recorded parts cost for this repair.
  Money get totalPartsCost {
    return parts.fold<Money>(
      Money.zero,
      (sum, part) => sum + part.cost,
    );
  }

  /// Net repair profit: customer payment minus sum of recorded part costs (PRD 6.3.5).
  Money? get netProfit {
    if (customerPayment == null) return null;
    return customerPayment! - totalPartsCost;
  }

  /// Validates whether a user with [role] can transition to [targetStatus] (PRD 6.3.2).
  bool canTransitionTo(RepairStatus targetStatus, UserRole role) {
    if (status == RepairStatus.delivered) {
      // Delivered jobs are locked
      return false;
    }

    if (targetStatus == RepairStatus.delivered) {
      // Only Admin can deliver, and only when currently in 'done' status
      if (!role.isAdmin) return false;
      if (status != RepairStatus.done) return false;
      return true;
    }

    // Workers can update to inspected, partBought, or done
    if (role.isWorker) {
      return targetStatus == RepairStatus.inspected ||
          targetStatus == RepairStatus.partBought ||
          targetStatus == RepairStatus.done;
    }

    // Admin can transition to any intermediate status
    return true;
  }

  /// Validates all delivery prerequisites before confirming delivery (PRD 6.3.4).
  static String? validateDeliveryPrerequisites({
    required RepairStatus currentStatus,
    required String? customerName,
    required Money? paymentAmount,
  }) {
    if (currentStatus != RepairStatus.done) {
      return 'Repair status must be "Done" before confirming delivery.';
    }
    if (customerName == null || customerName.trim().isEmpty) {
      return 'Customer name is required at delivery.';
    }
    if (paymentAmount == null || !paymentAmount.isPositive) {
      return 'Payment amount received must be greater than zero.';
    }
    return null;
  }

  RepairTicket copyWith({
    String? deviceName,
    String? reportedProblem,
    String? inspectedProblem,
    String? description,
    String? audioUrl,
    RepairStatus? status,
    String? assignedWorkerId,
    String? customerName,
    String? customerPhone,
    List<RepairPart>? parts,
    Money? customerPayment,
    String? deliveredBy,
    DateTime? deliveredAt,
    DateTime? updatedAt,
  }) {
    return RepairTicket(
      id: id,
      deviceName: deviceName ?? this.deviceName,
      reportedProblem: reportedProblem ?? this.reportedProblem,
      inspectedProblem: inspectedProblem ?? this.inspectedProblem,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      status: status ?? this.status,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      parts: parts ?? this.parts,
      customerPayment: customerPayment ?? this.customerPayment,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
