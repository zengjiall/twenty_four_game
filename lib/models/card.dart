class PlayingCard {
  final int value;      // 牌面值 (1-13)
  final String? suit;    // 花色
  final int numerator;
  final int denominator;
  final bool isVirtual; // 是否是计算后的虚拟卡牌

  PlayingCard({
    required this.value,
    this.suit,
    this.numerator = 0,
    this.denominator = 1,
    this.isVirtual = false,
  });

  String get display {
    if (value > 13) return value.toString();
    switch (value) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return value.toString();
    }
  }
}