import '../engine/rational.dart';

class PlayingCard {
  final int value;
  final String? suit;
  final int numerator;
  final int denominator;
  final bool isVirtual;

  PlayingCard({
    required this.value,
    this.suit,
    this.numerator = 0,
    this.denominator = 1,
    this.isVirtual = false,
  });

  factory PlayingCard.virtual(Rational rationalValue) {
    return PlayingCard(
      value: rationalValue.numerator,
      numerator: rationalValue.numerator,
      denominator: rationalValue.denominator,
      isVirtual: true,
    );
  }

  Rational get rationalValue {
    if (isVirtual) {
      return Rational(numerator, denominator);
    }

    return Rational(value);
  }

  String get display {
    final displayValue = rationalValue;
    if (isVirtual || !displayValue.isInteger) {
      return displayValue.toString();
    }

    final integerValue = displayValue.numerator;
    if (integerValue > 13) return integerValue.toString();

    switch (integerValue) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return integerValue.toString();
    }
  }
}
