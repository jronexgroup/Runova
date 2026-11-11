import '../money/money.dart';

/// Supported payment tender types (PRD 6.2 & design mockups).
enum TenderType {
  cash('Cash', 'নগদ'),
  upi('UPI / QR', 'ইউপিআই'),
  split('Split Tender', 'নগদ ও ইউপিআই');

  final String label;
  final String labelBengali;

  const TenderType(this.label, this.labelBengali);
}

/// A line item within a retail sale transaction.
class SaleItem {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final Money unitCost;
  final Money unitSellPrice;

  const SaleItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.unitSellPrice,
  });

  Money get totalPrice => unitSellPrice * quantity;
  Money get totalCost => unitCost * quantity;
  Money get profit => totalPrice - totalCost;
}

/// Retail Sale Transaction record.
class SaleTransaction {
  final String id;
  final String? invoiceNumber; // e.g. INV-202611-0001 (null for covers/tempered glass)
  final List<SaleItem> items;
  final Money totalAmount;
  final TenderType tenderType;
  final Money cashAmount;
  final Money upiAmount;
  final String? customerName;
  final String? customerPhone;
  final DateTime createdAt;

  const SaleTransaction({
    required this.id,
    this.invoiceNumber,
    required this.items,
    required this.totalAmount,
    required this.tenderType,
    required this.cashAmount,
    required this.upiAmount,
    this.customerName,
    this.customerPhone,
    required this.createdAt,
  });

  /// Cost of goods sold (COGS) for this sale transaction (PRD 6.5).
  Money get totalCogs {
    return items.fold<Money>(Money.zero, (sum, item) => sum + item.totalCost);
  }

  /// Net retail profit from this transaction based on COGS.
  Money get retailProfit => totalAmount - totalCogs;
}

/// Print & Xerox POS service transaction record (PRD 6.1).
class PrintTransaction {
  final String id;
  final String receiptNumber; // e.g. PX-8842
  final String serviceDescription;
  final int quantity;
  final Money totalAmount;
  final TenderType tenderType;
  final DateTime createdAt;

  const PrintTransaction({
    required this.id,
    required this.receiptNumber,
    required this.serviceDescription,
    required this.quantity,
    required this.totalAmount,
    required this.tenderType,
    required this.createdAt,
  });
}

/// General shop operating expense (PRD 6.4).
class Expense {
  final String id;
  final String title;
  final String category; // e.g. Printing supplies, Shop maintenance, General
  final Money amount;
  final DateTime date;
  final String? description;
  final String? referenceId;

  const Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.referenceId,
  });
}

/// Formal invoice for retail accessories or delivered mobile repairs (PRD 6.2.7 & 6.3.6).
class Invoice {
  final String id;
  final String invoiceNumber;
  final InvoiceType type;
  final String referenceId; // saleTransactionId or repairId
  final String customerName;
  final String? customerPhone;
  final String? deviceName;
  final String? workDescription;
  final Money totalAmount;
  final DateTime issuedAt;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.type,
    required this.referenceId,
    required this.customerName,
    this.customerPhone,
    this.deviceName,
    this.workDescription,
    required this.totalAmount,
    required this.issuedAt,
  });
}

enum InvoiceType {
  retail('Retail Invoice', 'খুচরা ইনভয়েস'),
  repair('Repair Invoice', 'মেরামত ইনভয়েস');

  final String label;
  final String labelBengali;

  const InvoiceType(this.label, this.labelBengali);
}
