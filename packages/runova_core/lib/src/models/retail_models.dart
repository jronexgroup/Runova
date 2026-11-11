import '../money/money.dart';

/// General Retail Product (PRD 6.2.1).
class Product {
  final String id;
  final String name;
  final String category;
  final String supplier;
  final Money buyPrice;
  final Money defaultSellPrice;
  final int stockQuantity;
  final String? barcode;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.supplier,
    required this.buyPrice,
    required this.defaultSellPrice,
    required this.stockQuantity,
    this.barcode,
  });

  bool get isInStock => stockQuantity > 0;

  Product copyWith({
    String? name,
    String? category,
    String? supplier,
    Money? buyPrice,
    Money? defaultSellPrice,
    int? stockQuantity,
    String? barcode,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      supplier: supplier ?? this.supplier,
      buyPrice: buyPrice ?? this.buyPrice,
      defaultSellPrice: defaultSellPrice ?? this.defaultSellPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      barcode: barcode ?? this.barcode,
    );
  }
}

/// Mobile Cover Stock Group (PRD 6.2.3).
/// All linked models share one pooled stock quantity under the Base Name.
class CoverGroup {
  final String id;
  final String baseName;
  final List<String> linkedModels;
  final String wholesaler;
  final Money buyPrice;
  final Money defaultSellPrice;
  final int stockQuantity;

  const CoverGroup({
    required this.id,
    required this.baseName,
    required this.linkedModels,
    required this.wholesaler,
    required this.buyPrice,
    required this.defaultSellPrice,
    required this.stockQuantity,
  });

  bool get isInStock => stockQuantity > 0;

  /// Checks if this cover group matches a searched model name (case-insensitive substring or exact).
  bool matchesModel(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return false;
    if (baseName.toLowerCase().contains(cleanQuery)) return true;
    return linkedModels.any((m) => m.toLowerCase().contains(cleanQuery));
  }

  CoverGroup copyWith({
    String? baseName,
    List<String>? linkedModels,
    String? wholesaler,
    Money? buyPrice,
    Money? defaultSellPrice,
    int? stockQuantity,
  }) {
    return CoverGroup(
      id: id,
      baseName: baseName ?? this.baseName,
      linkedModels: linkedModels ?? this.linkedModels,
      wholesaler: wholesaler ?? this.wholesaler,
      buyPrice: buyPrice ?? this.buyPrice,
      defaultSellPrice: defaultSellPrice ?? this.defaultSellPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}

/// Result enum for Cover Finder search (PRD 6.2.3)
enum CoverSearchResultStatus {
  available('Available', 'স্টকে আছে'),
  outOfStock('Out of Stock — 0', 'স্টক শেষ — ০'),
  notFound('Not Found', 'খুঁজে পাওয়া যায়নি');

  final String label;
  final String labelBengali;

  const CoverSearchResultStatus(this.label, this.labelBengali);
}

/// Tempered Glass bulk stock item (PRD 6.2.4).
class TemperedGlassItem {
  final String id;
  final String name;
  final int stockQuantity;
  final Money pricePerPiece;

  const TemperedGlassItem({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.pricePerPiece,
  });

  Money calculateTotal(int quantitySold) => pricePerPiece * quantitySold;
}

/// Small Item (₹1–2 items, PRD 6.2.5).
class SmallItem {
  final String id;
  final String name;
  final int stockQuantity;
  final Money pricePerPiece;

  const SmallItem({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.pricePerPiece,
  });

  Money calculateTotal(int quantitySold) => pricePerPiece * quantitySold;
}
