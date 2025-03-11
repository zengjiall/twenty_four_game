import 'dart:math';
import 'card.dart';

class GameState {
  final int targetNumber;
  List<PlayingCard> currentCards = [];
  List<PlayingCard> deck = []; // 牌组
  List<PlayingCard> discardPile = []; // 弃牌堆
  int currentRound = 1;
  int score = 0;
  static const int totalRounds = 13; // 修改为13轮

  GameState({required this.targetNumber}) {
    _initializeDeck();
    dealNewCards();
  }

  void _initializeDeck() {
    deck.clear();
    // 创建一副完整的扑克牌（52张）
    for (int value = 1; value <= 13; value++) {
      for (String suit in ['♠', '♥', '♦', '♣']) {
        deck.add(PlayingCard(value: value, suit: suit));
      }
    }
    deck.shuffle(); // 洗牌
  }

  void dealNewCards() {
    if (deck.length >= 4) {
      currentCards = deck.take(4).toList(); // 发4张牌
      deck.removeRange(0, 4); // 从牌组中移除这些牌
    }
  }

  bool hasNextRound() {
    return deck.length >= 4; // 检查牌组是否还有足够的牌
  }

  void addToDiscardPile(PlayingCard card) {
    if (!discardPile.contains(card)) {
      discardPile.add(card);
    }
  }
}