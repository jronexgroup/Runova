import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:runova_admin/data/local/app_database.dart';
import 'package:runova_admin/state/shop_state.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Runova Admin App State Tests with SQLite Persistence', () {
    late ShopState state;
    late Database testDb;

    setUp(() async {
      // Create fresh in-memory database for each test
      testDb = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await AppDatabase.instance.createSchema(testDb);
      AppDatabase.setDatabaseForTesting(testDb);

      state = ShopState.instance;
      await state.init(force: true);
    });

    tearDown(() async {
      await testDb.close();
      AppDatabase.setDatabaseForTesting(null);
    });

    test('Initial clean database starts empty without dummy mock data', () {
      expect(state.products.isEmpty, isTrue);
      expect(state.coverGroups.isEmpty, isTrue);
      expect(state.repairTickets.isEmpty, isTrue);
      expect(state.printTransactions.isEmpty, isTrue);
      expect(state.expenses.isEmpty, isTrue);
      expect(state.cashCollected, equals(Money.zero));
      expect(state.upiCollected, equals(Money.zero));
    });

    test('Adding product persists to SQLite and updates state', () async {
      await state.addProduct(
        name: 'Boat Bassheads 100',
        category: 'Earphones',
        supplier: 'ABC Distributors',
        buyPrice: Money.fromRupees(150),
        defaultSellPrice: Money.fromRupees(350),
        initialStock: 10,
        barcode: '890123456789',
      );

      expect(state.products.length, equals(1));
      final p = state.products.first;
      expect(p.name, equals('Boat Bassheads 100'));
      expect(p.stockQuantity, equals(10));
      expect(p.defaultSellPrice, equals(Money.fromRupees(350)));
    });

    test('Adding cover group and selling cover reduces pooled stock', () async {
      await state.addCoverGroup(
        baseName: 'iPhone 13 / 14 Case',
        linkedModels: ['iPhone 13', 'iPhone 14'],
        wholesaler: 'Mobile King',
        buyPrice: Money.fromRupees(40),
        defaultSellPrice: Money.fromRupees(150),
        initialStock: 5,
      );

      expect(state.coverGroups.length, equals(1));
      final cover = state.coverGroups.first;
      expect(cover.stockQuantity, equals(5));

      await state.recordCoverSale(
        coverGroup: cover,
        actualSellPrice: Money.fromRupees(120),
        tenderType: TenderType.cash,
      );

      expect(state.coverGroups.first.stockQuantity, equals(4));
      expect(state.cashCollected, equals(Money.fromRupees(120)));
    });

    test('Recording print transaction updates ledger and tender amounts', () async {
      final total = PrintPricingCalculator.calculateXerox(4); // 4 copies = ₹10

      await state.recordPrintTransaction(
        serviceDescription: 'Xerox • 4 Copies',
        quantity: 4,
        totalAmount: total,
        tenderType: TenderType.upi,
      );

      expect(state.printTransactions.length, equals(1));
      expect(state.printTransactions.first.receiptNumber, startsWith('PX-'));
      expect(state.upiCollected, equals(total));
    });

    test('Repair intake, part addition, and delivery invoice generation', () async {
      await state.registerRepairTicket(
        deviceName: 'Redmi Note 10 Pro',
        reportedProblem: 'Display flickering & broken touch',
        inspectedProblem: 'Cracked digitizer layer',
        description: 'Screen replacement required',
        customerName: 'Rahul Sen',
        customerPhone: '+91 98301 23456',
        assignedWorkerId: 'WORKER-1',
      );

      expect(state.repairTickets.length, equals(1));
      var ticket = state.repairTickets.first;
      expect(ticket.status, equals(RepairStatus.inspected));

      // Worker changes status to Part Bought
      await state.updateRepairStatus(ticket.id, RepairStatus.partBought);
      ticket = state.repairTickets.firstWhere((t) => t.id == ticket.id);
      expect(ticket.status, equals(RepairStatus.partBought));

      // Add a part costing ₹1200
      await state.addRepairPart(
        ticketId: ticket.id,
        partName: 'OLED Display Combo Original',
        cost: Money.fromRupees(1200),
      );

      // Transition to Done
      await state.updateRepairStatus(ticket.id, RepairStatus.done);
      ticket = state.repairTickets.firstWhere((t) => t.id == ticket.id);
      expect(ticket.status, equals(RepairStatus.done));
      expect(ticket.totalPartsCost, equals(Money.fromRupees(1200)));

      // Admin delivers repair, taking ₹1800 payment
      final invoice = await state.deliverRepair(
        ticket: ticket,
        customerName: 'Rahul Sen',
        customerPhone: '+91 98301 23456',
        paymentAmount: Money.fromRupees(1800),
        tenderType: TenderType.cash,
      );

      expect(invoice.invoiceNumber, startsWith('REP-'));
      expect(invoice.totalAmount, equals(Money.fromRupees(1800)));
      expect(invoice.customerName, equals('Rahul Sen'));

      final deliveredTicket = state.repairTickets.firstWhere((t) => t.id == ticket.id);
      expect(deliveredTicket.status, equals(RepairStatus.delivered));
      expect(deliveredTicket.customerPayment, equals(Money.fromRupees(1800)));
      expect(deliveredTicket.netProfit, equals(Money.fromRupees(600))); // 1800 - 1200 parts
      expect(state.cashCollected, equals(Money.fromRupees(1800)));
    });

    test('Adding operating expenses tracks correctly in ledger', () async {
      await state.addExpense(
        title: 'Printer Toner Cartridge',
        category: 'Printing supplies',
        amount: Money.fromRupees(850),
      );

      expect(state.expenses.length, equals(1));
      expect(state.expenses.first.title, equals('Printer Toner Cartridge'));
      expect(state.expenses.first.amount, equals(Money.fromRupees(850)));
    });
  });
}
