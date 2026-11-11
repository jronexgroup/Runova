import 'package:test/test.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  group('Money Arithmetic and Formatting', () {
    test('Integer paise conversion and arithmetic', () {
      final m1 = Money.fromRupees(700); // 70000 paise
      final m2 = Money.fromRupees(30.50); // 3050 paise

      expect(m1.paise, equals(70000));
      expect(m2.paise, equals(3050));
      expect((m1 + m2).paise, equals(73050));
      expect((m1 - m2).paise, equals(66950));
      expect((m2 * 2).paise, equals(6100));
    });

    test('Indian Rupee formatting', () {
      expect(Money.fromRupees(18450).format(), equals('₹18,450'));
      expect(Money.fromRupees(5.50).format(omitZeroDecimals: false), equals('₹5.50'));
      expect(Money.fromPaise(24000).format(), equals('₹240'));
    });
  });

  group('Mobile Cover Shared Stock Logic', () {
    test('CoverGroup searches Base Name and Linked Models correctly', () {
      final cover = CoverGroup(
        id: 'cov-1',
        baseName: 'iPhone 13 / 14 Clear MagSafe Case',
        linkedModels: ['iPhone 13', 'iPhone 14'],
        wholesaler: 'Mobile Hub Burrabazar',
        buyPrice: Money.fromRupees(120),
        defaultSellPrice: Money.fromRupees(250),
        stockQuantity: 14,
      );

      expect(cover.matchesModel('iPhone 13'), isTrue);
      expect(cover.matchesModel('iphone 14'), isTrue);
      expect(cover.matchesModel('Clear MagSafe'), isTrue);
      expect(cover.matchesModel('Samsung S23'), isFalse);
    });
  });

  group('Repair Ticket Workflow and Permissions', () {
    final now = DateTime.now();

    final ticket = RepairTicket(
      id: 'REP-101',
      deviceName: 'Redmi Note 8 Pro',
      reportedProblem: 'Phone does not turn on',
      inspectedProblem: 'Battery damaged',
      description: 'Needs replacement battery',
      status: RepairStatus.inspected,
      createdAt: now,
      updatedAt: now,
    );

    test('Worker can advance to Inspected, Part Bought, Done, but NEVER Delivered', () {
      expect(ticket.canTransitionTo(RepairStatus.partBought, UserRole.worker), isTrue);
      expect(ticket.canTransitionTo(RepairStatus.done, UserRole.worker), isTrue);
      expect(ticket.canTransitionTo(RepairStatus.delivered, UserRole.worker), isFalse);
    });

    test('Admin can advance to Delivered only if status is Done', () {
      // Current status is 'inspected', cannot jump straight to delivered
      expect(ticket.canTransitionTo(RepairStatus.delivered, UserRole.admin), isFalse);

      final doneTicket = ticket.copyWith(status: RepairStatus.done);
      expect(doneTicket.canTransitionTo(RepairStatus.delivered, UserRole.admin), isTrue);
    });

    test('Delivery validation requires Done status, Customer Name, and Positive Payment', () {
      // Missing customer name
      expect(
        RepairTicket.validateDeliveryPrerequisites(
          currentStatus: RepairStatus.done,
          customerName: '',
          paymentAmount: Money.fromRupees(1000),
        ),
        contains('Customer name is required'),
      );

      // Status not done
      expect(
        RepairTicket.validateDeliveryPrerequisites(
          currentStatus: RepairStatus.partBought,
          customerName: 'Rahul Sen',
          paymentAmount: Money.fromRupees(1000),
        ),
        contains('must be "Done"'),
      );

      // Payment zero
      expect(
        RepairTicket.validateDeliveryPrerequisites(
          currentStatus: RepairStatus.done,
          customerName: 'Rahul Sen',
          paymentAmount: Money.zero,
        ),
        contains('greater than zero'),
      );

      // Valid case
      expect(
        RepairTicket.validateDeliveryPrerequisites(
          currentStatus: RepairStatus.done,
          customerName: 'Rahul Sen',
          paymentAmount: Money.fromRupees(1000),
        ),
        isNull,
      );
    });

    test('Repair Profit calculation (PRD 6.3.5 example: 1000 payment - 700 battery = 300)', () {
      final ticketWithParts = ticket.copyWith(
        parts: [
          RepairPart(
            id: 'part-1',
            repairId: 'REP-101',
            description: 'Replacement battery',
            cost: Money.fromRupees(700),
            createdAt: now,
          ),
        ],
        customerPayment: Money.fromRupees(1000),
      );

      expect(ticketWithParts.totalPartsCost, equals(Money.fromRupees(700)));
      expect(ticketWithParts.netProfit, equals(Money.fromRupees(300)));
    });
  });

  group('Retail COGS Profit Calculation', () {
    test('Sale transaction calculates retail profit via COGS (PRD 6.5)', () {
      final sale = SaleTransaction(
        id: 'sale-1',
        invoiceNumber: 'INV-202611-0001',
        items: [
          SaleItem(
            id: 'item-1',
            productId: 'prod-1',
            productName: 'Boat Type-C Fast Cable 1.5m',
            quantity: 2,
            unitCost: Money.fromRupees(90), // Total cost: ₹180
            unitSellPrice: Money.fromRupees(220), // Total price: ₹440
          ),
        ],
        totalAmount: Money.fromRupees(440),
        tenderType: TenderType.cash,
        cashAmount: Money.fromRupees(440),
        upiAmount: Money.zero,
        createdAt: DateTime.now(),
      );

      expect(sale.totalCogs, equals(Money.fromRupees(180)));
      expect(sale.retailProfit, equals(Money.fromRupees(260)));
    });
  });
}
