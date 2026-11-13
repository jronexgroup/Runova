import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import 'package:uuid/uuid.dart';
import '../data/local/app_database.dart';
import '../data/sync/sync_service.dart';

/// Clean, production-ready state manager for Runova Shop.
/// Backed by Local SQLite with High-Priority Cloud Synchronization.
/// Zero hardcoded junk data.
class ShopState extends ChangeNotifier {
  static final ShopState instance = ShopState._();
  ShopState._();

  final _uuid = const Uuid();
  bool isInitialized = false;

  // Shift & Cashier state
  String counterName = 'Counter 1';
  bool isShiftOpen = true;
  DateTime shiftStartTime = DateTime.now();

  // Financial totals for the active shift
  Money cashCollected = Money.zero;
  Money upiCollected = Money.zero;

  // Live Records (Loaded from SQLite)
  final List<PrintTransaction> printTransactions = [];
  final List<Product> products = [];
  final List<CoverGroup> coverGroups = [];
  final List<RepairTicket> repairTickets = [];
  final List<Invoice> invoices = [];
  final List<Expense> expenses = [];
  final List<Supplier> suppliers = [];

  /// Initializes the state from the local SQLite database.
  Future<void> init({bool force = false}) async {
    if (isInitialized && !force) return;

    final db = AppDatabase.instance;

    // Load from local SQLite
    products.clear();
    products.addAll(await db.getProducts());

    coverGroups.clear();
    coverGroups.addAll(await db.getCoverGroups());

    repairTickets.clear();
    repairTickets.addAll(await db.getRepairTickets());

    printTransactions.clear();
    printTransactions.addAll(await db.getPrintTransactions());

    expenses.clear();
    expenses.addAll(await db.getExpenses());

    suppliers.clear();
    suppliers.addAll(await db.getSuppliers());

    // Recompute shift totals from transactions created today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    cashCollected = Money.zero;
    upiCollected = Money.zero;

    for (final txn in printTransactions) {
      if (txn.createdAt.isAfter(todayStart)) {
        if (txn.tenderType == TenderType.cash) {
          cashCollected = cashCollected + txn.totalAmount;
        } else {
          upiCollected = upiCollected + txn.totalAmount;
        }
      }
    }

    for (final ticket in repairTickets) {
      if (ticket.status == RepairStatus.delivered &&
          ticket.deliveredAt != null &&
          ticket.deliveredAt!.isAfter(todayStart) &&
          ticket.customerPayment != null) {
        cashCollected = cashCollected + ticket.customerPayment!;
      }
    }

    isInitialized = true;
    notifyListeners();

    // Trigger sync drainage and keep periodic background sync running (every 15s)
    SyncService.instance.syncOutbox();
    SyncService.instance.startPeriodicSync();
  }

  // --- Product Management (Admin) ---
  Future<void> addProduct({
    required String name,
    required String category,
    required String supplier,
    required Money buyPrice,
    required Money defaultSellPrice,
    required int initialStock,
    String? barcode,
  }) async {
    final product = Product(
      id: 'PRD-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: name.trim(),
      category: category.trim(),
      supplier: supplier.trim(),
      buyPrice: buyPrice,
      defaultSellPrice: defaultSellPrice,
      stockQuantity: initialStock,
      barcode: barcode?.trim().isNotEmpty == true ? barcode!.trim() : null,
    );

    await AppDatabase.instance.upsertProduct(product);
    products.add(product);
    notifyListeners();

    SyncService.instance.syncOutbox();
  }

  // --- Cover Group Management (Admin) ---
  Future<void> addCoverGroup({
    required String baseName,
    required List<String> linkedModels,
    required String wholesaler,
    required Money buyPrice,
    required Money defaultSellPrice,
    required int initialStock,
  }) async {
    final group = CoverGroup(
      id: 'COV-${DateTime.now().millisecondsSinceEpoch % 100000}',
      baseName: baseName.trim(),
      linkedModels: linkedModels,
      wholesaler: wholesaler.trim(),
      buyPrice: buyPrice,
      defaultSellPrice: defaultSellPrice,
      stockQuantity: initialStock,
    );

    await AppDatabase.instance.upsertCoverGroup(group);
    coverGroups.add(group);
    notifyListeners();

    SyncService.instance.syncOutbox();
  }

  // --- Repair Ticket Intake (Worker & Admin) ---
  Future<RepairTicket> registerRepairTicket({
    required String deviceName,
    required String reportedProblem,
    required String inspectedProblem,
    required String description,
    String? audioUrl,
    String? customerName,
    String? customerPhone,
    String? assignedWorkerId,
  }) async {
    final now = DateTime.now();
    final nextId = 'REP-${now.millisecondsSinceEpoch % 100000}';

    final ticket = RepairTicket(
      id: nextId,
      deviceName: deviceName.trim(),
      reportedProblem: reportedProblem.trim(),
      inspectedProblem: inspectedProblem.trim(),
      description: description.trim(),
      audioUrl: audioUrl,
      status: RepairStatus.inspected,
      assignedWorkerId: assignedWorkerId,
      customerName: customerName?.trim().isNotEmpty == true ? customerName!.trim() : null,
      customerPhone: customerPhone?.trim().isNotEmpty == true ? customerPhone!.trim() : null,
      parts: [],
      createdAt: now,
      updatedAt: now,
    );

    await AppDatabase.instance.upsertRepairTicket(ticket);
    repairTickets.insert(0, ticket);
    notifyListeners();

    SyncService.instance.syncOutbox();
    return ticket;
  }

  Future<void> updateRepairStatus(String ticketId, RepairStatus newStatus) async {
    final index = repairTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final updated = repairTickets[index].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await AppDatabase.instance.upsertRepairTicket(updated);
    repairTickets[index] = updated;
    notifyListeners();
    SyncService.instance.syncOutbox();
  }

  Future<void> addRepairPart({
    required String ticketId,
    required String partName,
    required Money cost,
  }) async {
    final index = repairTickets.indexWhere((t) => t.id == ticketId);
    if (index == -1) return;

    final part = RepairPart(
      id: 'PRT-${DateTime.now().millisecondsSinceEpoch % 100000}',
      repairId: ticketId,
      description: partName.trim(),
      cost: cost,
      createdAt: DateTime.now(),
    );

    await AppDatabase.instance.insertRepairPart(part);

    final currentTicket = repairTickets[index];
    final updatedParts = List<RepairPart>.from(currentTicket.parts)..add(part);
    final updatedTicket = currentTicket.copyWith(
      parts: updatedParts,
      updatedAt: DateTime.now(),
    );
    repairTickets[index] = updatedTicket;
    notifyListeners();
    SyncService.instance.syncOutbox();
  }

  // --- Supplier Operations ---
  Future<Supplier> addSupplier({
    required String name,
    String phone = '',
    String category = 'General',
    String address = '',
  }) async {
    final supplier = Supplier(
      id: 'SUP-${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: name.trim(),
      phone: phone.trim(),
      category: category.trim(),
      address: address.trim(),
      createdAt: DateTime.now(),
    );

    await AppDatabase.instance.saveSupplier(supplier);
    suppliers.add(supplier);
    notifyListeners();
    SyncService.instance.syncOutbox();
    return supplier;
  }

  Future<void> deleteSupplier(String id) async {
    await AppDatabase.instance.deleteSupplier(id);
    suppliers.removeWhere((s) => s.id == id);
    notifyListeners();
    SyncService.instance.syncOutbox();
  }

  // --- Print & Xerox POS Recording ---
  Future<void> recordPrintTransaction({
    required String serviceDescription,
    required int quantity,
    required Money totalAmount,
    required TenderType tenderType,
  }) async {
    final nextNumber = 8840 + printTransactions.length + 1;
    final receiptNumber = 'PX-$nextNumber';

    final txn = PrintTransaction(
      id: _uuid.v4(),
      receiptNumber: receiptNumber,
      serviceDescription: serviceDescription,
      quantity: quantity,
      totalAmount: totalAmount,
      tenderType: tenderType,
      createdAt: DateTime.now(),
    );

    await AppDatabase.instance.insertPrintTransaction(txn);
    printTransactions.insert(0, txn);

    if (tenderType == TenderType.cash) {
      cashCollected = cashCollected + totalAmount;
    } else {
      upiCollected = upiCollected + totalAmount;
    }

    notifyListeners();
    SyncService.instance.syncOutbox();
  }

  // --- Retail POS Sale ---
  Future<void> recordRetailSale({
    required Product product,
    required int quantity,
    required Money actualSellPrice,
    required TenderType tenderType,
    String? customerName,
    String? customerPhone,
  }) async {
    if (product.stockQuantity < quantity) {
      throw StateError('Requested quantity exceeds available stock.');
    }

    final totalAmount = actualSellPrice * quantity;

    await AppDatabase.instance.decrementProductStock(product.id, quantity);

    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product.copyWith(
        stockQuantity: product.stockQuantity - quantity,
      );
    }

    if (tenderType == TenderType.cash) {
      cashCollected = cashCollected + totalAmount;
    } else {
      upiCollected = upiCollected + totalAmount;
    }

    notifyListeners();
    SyncService.instance.syncOutbox();
  }

  // --- Mobile Cover Sale ---
  Future<void> recordCoverSale({
    required CoverGroup coverGroup,
    required Money actualSellPrice,
    required TenderType tenderType,
  }) async {
    if (coverGroup.stockQuantity <= 0) {
      throw StateError('Cover is out of stock.');
    }

    await AppDatabase.instance.decrementCoverStock(coverGroup.id);

    final index = coverGroups.indexWhere((c) => c.id == coverGroup.id);
    if (index != -1) {
      coverGroups[index] = coverGroup.copyWith(
        stockQuantity: coverGroup.stockQuantity - 1,
      );
    }

    if (tenderType == TenderType.cash) {
      cashCollected = cashCollected + actualSellPrice;
    } else {
      upiCollected = upiCollected + actualSellPrice;
    }

    notifyListeners();
    SyncService.instance.syncOutbox();
  }

  // --- Repair Delivery & Invoicing ---
  Future<Invoice> deliverRepair({
    required RepairTicket ticket,
    required String customerName,
    required String? customerPhone,
    required Money paymentAmount,
    TenderType tenderType = TenderType.cash,
  }) async {
    final validationError = RepairTicket.validateDeliveryPrerequisites(
      currentStatus: ticket.status,
      customerName: customerName,
      paymentAmount: paymentAmount,
    );
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final now = DateTime.now();
    final invoiceNumber = 'REP-${now.year}${now.month.toString().padLeft(2, '0')}-${(invoices.length + 101).toString()}';

    final invoice = Invoice(
      id: _uuid.v4(),
      invoiceNumber: invoiceNumber,
      type: InvoiceType.repair,
      referenceId: ticket.id,
      customerName: customerName.trim(),
      customerPhone: customerPhone?.trim(),
      deviceName: ticket.deviceName,
      workDescription: ticket.inspectedProblem,
      totalAmount: paymentAmount,
      issuedAt: now,
    );

    await AppDatabase.instance.insertInvoice(invoice);
    invoices.add(invoice);

    final updatedTicket = ticket.copyWith(
      status: RepairStatus.delivered,
      customerName: customerName.trim(),
      customerPhone: customerPhone?.trim(),
      customerPayment: paymentAmount,
      deliveredBy: 'Admin',
      deliveredAt: now,
      updatedAt: now,
    );

    await AppDatabase.instance.upsertRepairTicket(updatedTicket);

    final index = repairTickets.indexWhere((t) => t.id == ticket.id);
    if (index != -1) {
      repairTickets[index] = updatedTicket;
    }

    if (tenderType == TenderType.cash) {
      cashCollected = cashCollected + paymentAmount;
    } else {
      upiCollected = upiCollected + paymentAmount;
    }

    notifyListeners();
    SyncService.instance.syncOutbox();
    return invoice;
  }

  // --- Operating Expenses ---
  Future<void> addExpense({
    required String title,
    required String category,
    required Money amount,
  }) async {
    final expense = Expense(
      id: 'EXP-${DateTime.now().millisecondsSinceEpoch % 100000}',
      title: title.trim(),
      category: category.trim(),
      amount: amount,
      date: DateTime.now(),
    );

    await AppDatabase.instance.insertExpense(expense);
    expenses.add(expense);
    notifyListeners();

    SyncService.instance.syncOutbox();
  }
}
