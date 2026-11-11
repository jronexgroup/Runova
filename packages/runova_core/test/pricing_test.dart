import 'package:test/test.dart';
import 'package:runova_core/runova_core.dart';

void main() {
  group('Print & Xerox Pricing Tests', () {
    test('Xerox matches PRD 6.1.1 pricing table exactly', () {
      expect(PrintPricingCalculator.calculateXerox(1), equals(Money.fromRupees(3)));
      expect(PrintPricingCalculator.calculateXerox(2), equals(Money.fromRupees(5)));
      expect(PrintPricingCalculator.calculateXerox(3), equals(Money.fromRupees(8)));
      expect(PrintPricingCalculator.calculateXerox(4), equals(Money.fromRupees(10)));
      expect(PrintPricingCalculator.calculateXerox(5), equals(Money.fromRupees(13)));
      expect(PrintPricingCalculator.calculateXerox(6), equals(Money.fromRupees(15)));
      expect(PrintPricingCalculator.calculateXerox(7), equals(Money.fromRupees(18)));
      expect(PrintPricingCalculator.calculateXerox(8), equals(Money.fromRupees(20)));
      expect(PrintPricingCalculator.calculateXerox(0), equals(Money.zero));
    });

    test('Normal Print rates match PRD 6.1.2', () {
      expect(
        PrintPricingCalculator.calculateNormalPrint(
          type: NormalPrintType.imageBlackAndWhite,
          quantity: 2,
        ),
        equals(Money.fromRupees(20)),
      );
      expect(
        PrintPricingCalculator.calculateNormalPrint(
          type: NormalPrintType.pdfBlackAndWhite,
          quantity: 4,
        ),
        equals(Money.fromRupees(20)),
      );
      expect(
        PrintPricingCalculator.calculateNormalPrint(
          type: NormalPrintType.imageColour,
          quantity: 2,
        ),
        equals(Money.fromRupees(30)),
      );
      expect(
        PrintPricingCalculator.calculateNormalPrint(
          type: NormalPrintType.pdfColour,
          quantity: 3,
        ),
        equals(Money.fromRupees(30)),
      );
    });

    test('Passport Photo pricing matches PRD 6.1.3 rule (Base 20 + 15 per extra group of 3)', () {
      expect(PrintPricingCalculator.calculatePassportPhotos(3), equals(Money.fromRupees(20)));
      expect(PrintPricingCalculator.calculatePassportPhotos(6), equals(Money.fromRupees(35)));
      expect(PrintPricingCalculator.calculatePassportPhotos(9), equals(Money.fromRupees(50)));
      expect(PrintPricingCalculator.calculatePassportPhotos(12), equals(Money.fromRupees(65)));
      expect(PrintPricingCalculator.calculatePassportPhotos(15), equals(Money.fromRupees(80)));

      // Quantities below 3 or not divisible by 3 must throw ArgumentError
      expect(() => PrintPricingCalculator.calculatePassportPhotos(2), throwsArgumentError);
      expect(() => PrintPricingCalculator.calculatePassportPhotos(4), throwsArgumentError);
      expect(() => PrintPricingCalculator.calculatePassportPhotos(5), throwsArgumentError);
      expect(() => PrintPricingCalculator.calculatePassportPhotos(7), throwsArgumentError);

      expect(PrintPricingCalculator.isValidPassportQuantity(3), isTrue);
      expect(PrintPricingCalculator.isValidPassportQuantity(6), isTrue);
      expect(PrintPricingCalculator.isValidPassportQuantity(5), isFalse);
      expect(PrintPricingCalculator.isValidPassportQuantity(2), isFalse);
    });

    test('Lamination matches PRD 6.1.4 (₹50 per doc)', () {
      expect(PrintPricingCalculator.calculateLamination(1), equals(Money.fromRupees(50)));
      expect(PrintPricingCalculator.calculateLamination(3), equals(Money.fromRupees(150)));
    });
  });
}
