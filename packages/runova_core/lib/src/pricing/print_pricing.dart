import '../money/money.dart';

/// Calculation engine for Print & Xerox services based on PRD Section 6.1.
class PrintPricingCalculator {
  /// Xerox pricing:
  /// `total_price = 5 × floor(quantity / 2) + 3 × (quantity mod 2)` (in Rupees)
  ///
  /// Examples:
  /// 1 copy: ₹3
  /// 2 copies: ₹5
  /// 3 copies: ₹8
  /// 4 copies: ₹10
  /// 5 copies: ₹13
  /// 6 copies: ₹15
  /// 7 copies: ₹18
  /// 8 copies: ₹20
  static Money calculateXerox(int quantity) {
    if (quantity <= 0) return Money.zero;
    final pairs = quantity ~/ 2;
    final remainder = quantity % 2;
    final totalRupees = (5 * pairs) + (3 * remainder);
    return Money.fromRupees(totalRupees);
  }

  /// Normal Print options and unit rates (PRD 6.1.2):
  /// - Image Black & White: ₹10
  /// - PDF Black & White: ₹5
  /// - Image Colour: ₹15
  /// - PDF Colour: ₹10
  static Money calculateNormalPrint({
    required NormalPrintType type,
    required int quantity,
  }) {
    if (quantity <= 0) return Money.zero;
    return type.unitPrice * quantity;
  }

  /// Passport-size Photo Print pricing (PRD 6.1.3):
  /// - Minimum quantity: 3
  /// - Must be multiple of 3
  /// - Formula: `20 + 15 × ((quantity / 3) - 1)` (in Rupees)
  ///
  /// 3: ₹20, 6: ₹30, 9: ₹45, 12: ₹60, 15: ₹75
  static Money calculatePassportPhotos(int quantity) {
    if (quantity < 3) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Passport photo print requires a minimum quantity of 3.',
      );
    }
    if (quantity % 3 != 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'Passport photo quantity must be a multiple of 3.',
      );
    }
    final groups = quantity ~/ 3;
    final totalRupees = 20 + 15 * (groups - 1);
    return Money.fromRupees(totalRupees);
  }

  /// Checks whether a passport photo quantity is valid.
  static bool isValidPassportQuantity(int quantity) {
    return quantity >= 3 && (quantity % 3 == 0);
  }

  /// Large Document Print with Lamination (PRD 6.1.4):
  /// - Fixed ₹50 per document
  static Money calculateLamination(int quantity) {
    if (quantity <= 0) return Money.zero;
    return Money.fromRupees(50 * quantity);
  }
}

/// Normal Print Type enum with exact rates from PRD 6.1.2
enum NormalPrintType {
  imageBlackAndWhite('Image — Black & White', 'ছবি — সাদা-কালো', Money.fromPaise(1000)),
  pdfBlackAndWhite('PDF — Black & White', 'পিডিএফ — সাদা-কালো', Money.fromPaise(500)),
  imageColour('Image — Colour', 'ছবি — রঙিন', Money.fromPaise(1500)),
  pdfColour('PDF — Colour', 'পিডিএফ — রঙিন', Money.fromPaise(1000));

  final String label;
  final String labelBengali;
  final Money unitPrice;

  const NormalPrintType(this.label, this.labelBengali, this.unitPrice);
}
