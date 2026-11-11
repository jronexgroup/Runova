import 'package:intl/intl.dart';

/// Immutable representation of monetary values stored as integer paise.
/// Prevents floating-point rounding errors across transactions, COGS, and invoices.
class Money implements Comparable<Money> {
  final int paise;

  const Money._(this.paise);

  /// Creates a [Money] instance from integer paise.
  const Money.fromPaise(int paise) : paise = paise;

  /// Creates a [Money] instance from rupees (e.g. 240.50 -> 24050 paise).
  factory Money.fromRupees(num rupees) {
    return Money._((rupees * 100).round());
  }

  static const Money zero = Money._(0);

  /// Value in decimal rupees.
  double get inRupees => paise / 100.0;

  /// Returns true if this amount is zero.
  bool get isZero => paise == 0;

  /// Returns true if this amount is strictly positive.
  bool get isPositive => paise > 0;

  /// Returns true if this amount is strictly negative.
  bool get isNegative => paise < 0;

  Money operator +(Money other) => Money._(paise + other.paise);

  Money operator -(Money other) => Money._(paise - other.paise);

  Money operator *(num multiplier) => Money._((paise * multiplier).round());

  Money operator -() => Money._(-paise);

  bool operator <(Money other) => paise < other.paise;
  bool operator <=(Money other) => paise <= other.paise;
  bool operator >(Money other) => paise > other.paise;
  bool operator >=(Money other) => paise >= other.paise;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Money && paise == other.paise);

  @override
  int get hashCode => paise.hashCode;

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  /// Formats the money into Indian Rupee display format (e.g. ₹18,450 or ₹5.50).
  String format({bool showSymbol = true, bool omitZeroDecimals = true}) {
    final absPaise = paise.abs();
    final rupeesPart = absPaise ~/ 100;
    final paisePart = absPaise % 100;

    final formatter = NumberFormat('#,##,###', 'en_IN');
    final formattedRupees = formatter.format(rupeesPart);

    final sign = paise < 0 ? '-' : '';
    final symbol = showSymbol ? '₹' : '';

    if (paisePart == 0 && omitZeroDecimals) {
      return '$sign$symbol$formattedRupees';
    } else {
      final paddedPaise = paisePart.toString().padLeft(2, '0');
      return '$sign$symbol$formattedRupees.$paddedPaise';
    }
  }

  @override
  String toString() => format();
}
