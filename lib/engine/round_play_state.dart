import '../models/card.dart';
import 'rational.dart';

class RoundPlayState {
  final List<PlayingCard> pool;
  final List<OperationMove> history;

  const RoundPlayState({
    required this.pool,
    required this.history,
  });

  factory RoundPlayState.initial(List<PlayingCard> cards) {
    return RoundPlayState(
      pool: List.unmodifiable(cards),
      history: const [],
    );
  }

  bool get canApplyOperation => history.length < 3 && pool.length >= 2;

  bool get isComplete => history.length == 3 && pool.length == 1;

  bool isWinningTarget(int target) {
    return isComplete && pool.single.rationalValue == Rational(target);
  }

  RoundPlayState? applyOperation({
    required String operatorSymbol,
    required PlayingCard left,
    required PlayingCard right,
  }) {
    if (!canApplyOperation || identical(left, right)) {
      return null;
    }

    final resultValue = calculateOperation(
      operatorSymbol,
      left.rationalValue,
      right.rationalValue,
    );
    if (resultValue == null) {
      return null;
    }

    final nextPool = List<PlayingCard>.from(pool);
    if (!_removeByIdentity(nextPool, left) ||
        !_removeByIdentity(nextPool, right)) {
      return null;
    }

    final resultCard = PlayingCard.virtual(resultValue);
    final move = OperationMove(
      operatorSymbol: operatorSymbol,
      left: left,
      right: right,
      result: resultCard,
    );

    return RoundPlayState(
      pool: List.unmodifiable([...nextPool, resultCard]),
      history: List.unmodifiable([...history, move]),
    );
  }

  RoundPlayState undoLastOperation() {
    if (history.isEmpty) {
      return this;
    }

    final lastMove = history.last;
    final nextPool = List<PlayingCard>.from(pool);
    _removeByIdentity(nextPool, lastMove.result);

    return RoundPlayState(
      pool: List.unmodifiable([...nextPool, lastMove.left, lastMove.right]),
      history: List.unmodifiable(history.take(history.length - 1)),
    );
  }

  static Rational? calculateOperation(
    String operatorSymbol,
    Rational left,
    Rational right,
  ) {
    switch (operatorSymbol) {
      case '+':
        return left + right;
      case '-':
        return left - right;
      case '*':
      case '\u00d7':
        return left * right;
      case '/':
      case '\u00f7':
        if (right.isZero) {
          return null;
        }
        return left / right;
      default:
        return null;
    }
  }

  static bool _removeByIdentity(List<PlayingCard> cards, PlayingCard card) {
    final index = cards.indexWhere((candidate) => identical(candidate, card));
    if (index == -1) {
      return false;
    }

    cards.removeAt(index);
    return true;
  }
}

class OperationMove {
  final String operatorSymbol;
  final PlayingCard left;
  final PlayingCard right;
  final PlayingCard result;

  const OperationMove({
    required this.operatorSymbol,
    required this.left,
    required this.right,
    required this.result,
  });
}
