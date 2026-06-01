import '../engine/solvable_hand_generator.dart';
import 'card.dart';

class GameState {
  final int targetNumber;
  final SolvableHandGenerator handGenerator;
  List<PlayingCard> currentCards = [];
  List<List<PlayingCard>> dealtHands = [];
  int currentRound = 1;
  int score = 0;

  static const int totalRounds = 13;

  GameState({
    required this.targetNumber,
    SolvableHandGenerator? handGenerator,
  }) : handGenerator = handGenerator ?? SolvableHandGenerator() {
    dealNewCards();
  }

  void dealNewCards() {
    currentCards = handGenerator.generate(target: targetNumber);
    dealtHands.add(currentCards);
  }

  bool hasNextRound() {
    return currentRound < totalRounds;
  }
}
