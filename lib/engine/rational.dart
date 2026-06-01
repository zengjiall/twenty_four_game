class Rational implements Comparable<Rational> {
  final int numerator;
  final int denominator;

  factory Rational(int numerator, [int denominator = 1]) {
    if (denominator == 0) {
      throw ArgumentError.value(denominator, 'denominator', 'Cannot be zero.');
    }

    if (numerator == 0) {
      return const Rational._(0, 1);
    }

    final sign = denominator < 0 ? -1 : 1;
    final signedNumerator = numerator * sign;
    final positiveDenominator = denominator.abs();
    final divisor = _gcd(signedNumerator.abs(), positiveDenominator);

    return Rational._(
      signedNumerator ~/ divisor,
      positiveDenominator ~/ divisor,
    );
  }

  const Rational._(this.numerator, this.denominator);

  bool get isZero => numerator == 0;

  bool get isInteger => denominator == 1;

  Rational operator +(Rational other) {
    return Rational(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator,
    );
  }

  Rational operator -(Rational other) {
    return Rational(
      numerator * other.denominator - other.numerator * denominator,
      denominator * other.denominator,
    );
  }

  Rational operator *(Rational other) {
    return Rational(
      numerator * other.numerator,
      denominator * other.denominator,
    );
  }

  Rational operator /(Rational other) {
    if (other.isZero) {
      throw ArgumentError('Cannot divide by zero.');
    }

    return Rational(
      numerator * other.denominator,
      denominator * other.numerator,
    );
  }

  @override
  int compareTo(Rational other) {
    return (numerator * other.denominator).compareTo(
      other.numerator * denominator,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Rational &&
        numerator == other.numerator &&
        denominator == other.denominator;
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() {
    if (isInteger) {
      return numerator.toString();
    }

    return '$numerator/$denominator';
  }

  static int _gcd(int a, int b) {
    var left = a;
    var right = b;

    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }

    return left == 0 ? 1 : left;
  }
}
