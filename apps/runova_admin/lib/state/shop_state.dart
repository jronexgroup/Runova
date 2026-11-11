import 'package:flutter/material.dart';
import 'package:runova_core/runova_core.dart';
import 'package:uuid/uuid.dart';

/// Central state management for Runova Admin counter operations.
class ShopState extends ChangeNotifier {
  static final ShopState instance = ShopState._();
  ShopState._() {
    _loadInitialData();
  }

  final _uuid = const Uuid();

  // Shift & Cashier state
  String counterName = 'Counter 1';
  bool isShiftOpen = true;
  DateTime shiftStartTime = DateTime.now().subtract(const Duration(hours: 4));

  // Transactions & Financials
  Money cashCollected = Money.fromRupees(9250);
  Money upiCollected = Money.fromRupees(9200);

  // Print & POS Recent Transactions
  final List<PrintTransaction> printTransactions = [];

  // Retail Products
  final List<Product> products = [];
  final List<CoverGroup> coverGroups = [];

  // Repair Tickets
  final List<RepairTicket> repairTickets = [];

  // Invoices generated
  final List<Invoice> invoices = [];

  // General Expenses
  final List<Expense> expenses = [];

  void _loadInitialData() {
    // 1. Initial Print Transactions
    printTransactions.addAll([
      PrintTransaction(
        id: _uuid.v4(),
        receiptNumber: 'PX-8842',
        serviceDescription: 'Xerox • 4 Copies (B&W)',
        quantity: 4,
        totalAmount: Money.fromRupees(10),
        tenderType: TenderType.cash,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      PrintTransaction(
        id: _uuid.v4(),
        receiptNumber: 'PX-8841',
        serviceDescription: 'Photo Print • 6 Copies',
        quantity: 6,
        totalAmount: Money.fromRupees(35),
        tenderType: TenderType.upi,
        createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
      ),
      PrintTransaction(
        id: _uuid.v4(),
        receiptNumber: 'PX-8840',
        serviceDescription: 'Normal Print • PDF Colour (3)',
        quantity: 3,
        totalAmount: Money.fromRupees(30),
        tenderType: TenderType.cash,
        createdAt: DateTime.now().subtract(const Duration(minutes: 42)),
      ),
    ]);

    // 2. Initial Retail Products
    products.addAll([
      Product(
        id: 'PRD-101',
        name: 'Boat Type-C Fast Cable 1.5m',
        category: 'Cables',
        supplier: 'Anand Electronics',
        buyPrice: Money.fromRupees(90),
        defaultSellPrice: Money.fromRupees(220),
        stockQuantity: 18,
        barcode: '8901234567890',
      ),
      Product(
        id: 'PRD-102',
        name: 'Realme 33W Dart Charger (No Guarantee)',
        category: 'Chargers',
        supplier: 'Kolkata Mobile Spares',
        buyPrice: Money.fromRupees(280),
        defaultSellPrice: Money.fromRupees(450),
        stockQuantity: 9,
      ),
      Product(
        id: 'PRD-103',
        name: 'Noise ColorFit Pulse Smartwatch',
        category: 'Smartwatches',
        supplier: 'Tech Distribution Hub',
        buyPrice: Money.fromRupees(950),
        defaultSellPrice: Money.fromRupees(1499),
        stockQuantity: 4,
      ),
    ]);

    // 3. Initial Mobile Cover Groups (Shared Stock by Base Name)
    coverGroups.addAll([
      CoverGroup(
        id: 'COV-1',
        baseName: 'iPhone 13 / 14 Clear MagSafe Armor Case',
        linkedModels: ['iPhone 13', 'iPhone 14'],
        wholesaler: 'Burrabazar Mobile Hub',
        buyPrice: Money.fromRupees(110),
        defaultSellPrice: Money.fromRupees(250),
        stockQuantity: 12,
      ),
      CoverGroup(
        id: 'COV-2',
        baseName: 'Redmi Note 12 / Poco X5 Matte Silicon Shockproof',
        linkedModels: ['Redmi Note 12 5G', 'Poco X5 5G'],
        wholesaler: 'Burrabazar Mobile Hub',
        buyPrice: Money.fromRupees(65),
        defaultSellPrice: Money.fromRupees(150),
        stockQuantity: 0, // Out of Stock demonstration
      ),
      CoverGroup(
        id: 'COV-3',
        baseName: 'Samsung Galaxy A14 / A14 5G Leather Wallet Case',
        linkedModels: ['Samsung Galaxy A14', 'Samsung A14 5G'],
        wholesaler: 'Chandni Chowk Accessories',
        buyPrice: Money.fromRupees(95),
        defaultSellPrice: Money.fromRupees(220),
        stockQuantity: 7,
      ),
    ]);

    // 4. Initial Repair Tickets
    final now = DateTime.now();
    repairTickets.addAll([
      RepairTicket(
        id: 'REP-8401',
        deviceName: 'Redmi Note 8 Pro',
        reportedProblem: 'Phone does not turn on',
        inspectedProblem: 'Battery damaged, requires replacement',
        description: 'Customer says it shut down during call. Battery swollen.',
        audioUrl: 'sample_audio_note.aac',
        status: RepairStatus.done,
        assignedWorkerId: 'WORKER-1',
        customerName: 'Rahul Sen',
        customerPhone: '+91 98301 23456',
        parts: [
          RepairPart(
            id: 'PART-1',
            repairId: 'REP-8401',
            description: 'Original Compatible Battery BN52',
            cost: Money.fromRupees(700),
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      RepairTicket(
        id: 'REP-8402',
        deviceName: 'Samsung Galaxy M31',
        reportedProblem: 'Screen cracked & flickering touch',
        inspectedProblem: 'Display IC burned, combo replacement needed',
        description: 'Dropped from bike. Frame slightly bent.',
        status: RepairStatus.partBought,
        assignedWorkerId: 'WORKER-1',
        customerName: 'Subhasish Roy',
        customerPhone: '+91 98312 98765',
        parts: [
          RepairPart(
            id: 'PART-2',
            repairId: 'REP-8402',
            description: 'Super AMOLED Display Combo',
            cost: Money.fromRupees(1800),
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 7)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      RepairTicket(
        id: 'REP-8403',
        deviceName: 'Vivo Y20',
        reportedProblem: 'Mic not working on calls',
        inspectedProblem: 'Sub-board CC board mic pin rusted',
        description: 'Water ingress in bottom port. Cleaning & charging flex replacement needed.',
        status: RepairStatus.inspected,
        assignedWorkerId: 'WORKER-1',
        customerName: 'Priya Mondal',
        customerPhone: '+91 97488 44321',
        parts: [],
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      RepairTicket(
        id: 'REP-8399',
        deviceName: 'OnePlus Nord CE 2',
        reportedProblem: 'Charging port loose',
        inspectedProblem: 'Charging flex jack replaced',
        description: 'Cleaned lint and replaced pin connector',
        status: RepairStatus.delivered,
        assignedWorkerId: 'WORKER-1',
        customerName: 'Amitava Das',
        customerPhone: '+91 98300 11223',
        parts: [
          RepairPart(
            id: 'PART-3',
            repairId: 'REP-8399',
            description: 'Charging jack pin',
            cost: Money.fromRupees(150),
            createdAt: now.subtract(const Duration(days: 1)),
          ),
        ],
        customerPayment: Money.fromRupees(450),
        deliveredBy: 'Shop Owner (Admin)',
        deliveredAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
    ]);

    // 5. Initial Expenses
    expenses.addAll([
      Expense(
        id: 'EXP-1',
        title: 'JK Copier A4 Paper (2 Reams)',
        category: 'Printing supplies',
        amount: Money.fromRupees(620),
        date: now.subtract(const Duration(hours: 4)),
      ),
      Expense(
        id: 'EXP-2',
        title: 'Epson 003 Black Ink Refill',
        category: 'Printing supplies',
        amount: Money.fromRupees(350),
        date: now.subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  // --- Print Actions ---
  void recordPrintTransaction({
    required String serviceDescription,
    required int quantity,
    required Money totalAmount,
    required TenderType tenderType,
  }) {
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

    printTransactions.insert(0, txn);

    if (tenderType == TenderType.cash) {
      cashCollected = cashCollected + totalAmount;
    } else {
      upiCollected = upiCollected + totalAmount;
    }

    notifyListeners();
  }

  // --- Retail Actions ---
  void recordRetailSale({
    required Product product,
    required int quantity,
    required Money actualSellPrice,
    required TenderType tenderType,
    String? customerName,
    String? customerPhone,
  }) {
    if (product.stockQuantity < quantity) {
      throw StateError('Requested quantity exceeds available stock.');
    }

    final totalAmount = actualSellPrice * quantity;
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
  }

  // --- Mobile Cover Actions ---
  void recordCoverSale({
    required CoverGroup coverGroup,
    required Money actualSellPrice,
    required TenderType tenderType,
  }) {
    if (coverGroup.stockQuantity <= 0) {
      throw StateError('Cover is out of stock.');
    }

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
  }

  // --- Repair Delivery Action ---
  Invoice deliverRepair({
    required RepairTicket ticket,
    required String customerName,
    required String? customerPhone,
    required Money paymentAmount,
  }) {
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

    final index = repairTickets.indexWhere((t) => t.id == ticket.id);
    if (index != -1) {
      repairTickets[index] = updatedTicket;
    }

    // Default to Cash or UPI split for delivery payment
    cashCollected = cashCollected + paymentAmount;

    notifyListeners();
    return invoice;
  }

  void addExpense({
    required String title,
    required String category,
    required Money amount,
  }) {
    expenses.add(
      Expense(
        id: 'EXP-${expenses.length + 1}',
        title: title,
        category: category,
        amount: amount,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
