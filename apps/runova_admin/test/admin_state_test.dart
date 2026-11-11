import 'package:flutter_test/flutter_test.dart';
import 'package:runova_admin/state/shop_state.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  group('Runova Admin App State Tests', () {
    late ShopState state;

    setUp(() {
      state = ShopState.instance;
    });

    test('Initial state loads products, covers, and repair tickets', () {
      expect(state.products.isNotEmpty, isTrue);
      expect(state.coverGroups.isNotEmpty, isTrue);
      expect(state.repairTickets.isNotEmpty, isTrue);
      expect(state.printTransactions.isNotEmpty, isTrue);
    });

    test('Recording print transaction updates ledger and tender amounts', () {
      final initialCash = state.cashCollected;
      final total = PrintPricingCalculator.calculateXerox(4); // ₹10

      state.recordPrintTransaction(
        serviceDescription: 'Xerox • 4 Copies',
        quantity: 4,
        totalAmount: total,
        tenderType: TenderType.cash,
      );

      expect(state.printTransactions.first.receiptNumber, startsWith('PX-'));
      expect(state.cashCollected, equals(initialCash + total));
    });

    test('Selling mobile cover reduces shared stock for that Base Name', () {
      final cover = state.coverGroups.firstWhere((c) => c.stockQuantity > 0);
      final initialStock = cover.stockQuantity;

      state.recordCoverSale(
        coverGroup: cover,
        actualSellPrice: cover.defaultSellPrice,
        tenderType: TenderType.upi,
      );

      final updatedCover = state.coverGroups.firstWhere((c) => c.id == cover.id);
      expect(updatedCover.stockQuantity, equals(initialStock - 1));
    });

    test('Admin confirms repair delivery and generates repair invoice', () {
      final doneTicket = state.repairTickets.firstWhere((t) => t.status == RepairStatus.done);

      final invoice = state.deliverRepair(
        ticket: doneTicket,
        customerName: 'Rahul Sen',
        customerPhone: '+91 98301 23456',
        paymentAmount: Money.fromRupees(1200),
      );

      expect(invoice.invoiceNumber, startsWith('REP-'));
      expect(invoice.totalAmount, equals(Money.fromRupees(1200)));
      expect(invoice.customerName, equals('Rahul Sen'));

      final deliveredTicket = state.repairTickets.firstWhere((t) => t.id == doneTicket.id);
      expect(deliveredTicket.status, equals(RepairStatus.delivered));
      expect(deliveredTicket.netProfit, equals(Money.fromRupees(500))); // 1200 - 700 parts
    });

    test('Adding general expense tracks correctly', () {
      final initialCount = state.expenses.length;
      state.addExpense(
        title: 'Printer Toner Cartridge',
        category: 'Printing supplies',
        amount: Money.fromRupees(850),
      );

      expect(state.expenses.length, equals(initialCount + 1));
      expect(state.expenses.last.title, equals('Printer Toner Cartridge'));
      expect(state.expenses.last.amount, equals(Money.fromRupees(850)));
    });
  });
}
