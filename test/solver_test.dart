import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_four_game/engine/rational.dart';
import 'package:twenty_four_game/engine/round_play_state.dart';
import 'package:twenty_four_game/engine/solvable_hand_generator.dart';
import 'package:twenty_four_game/engine/twenty_four_solver.dart';
import 'package:twenty_four_game/models/card.dart';
import 'package:twenty_four_game/models/game_state.dart';

void main() {
  group('Rational', () {
    test('normalizes values and keeps arithmetic exact', () {
      expect(Rational(2, 4), Rational(1, 2));
      expect(Rational(1, -3), Rational(-1, 3));
      expect(Rational(1, 2) + Rational(1, 3), Rational(5, 6));
      expect(Rational(3, 4) * Rational(8, 9), Rational(2, 3));
      expect(Rational(1, 2) / Rational(3, 5), Rational(5, 6));
    });

    test('rejects zero denominators and zero divisors', () {
      expect(() => Rational(1, 0), throwsArgumentError);
      expect(() => Rational(1) / Rational(0), throwsArgumentError);
    });
  });

  group('TwentyFourSolver', () {
    const solver = TwentyFourSolver();

    test('finds a basic expression that reaches 24', () {
      final result = solver.solve([1, 2, 3, 4]);

      expect(result.hasSolution, isTrue);
      expect(result.firstExpression, isNotNull);
    });

    test('uses exact fractions for hands that need them', () {
      final result = solver.solve([1, 5, 5, 5]);

      expect(result.hasSolution, isTrue);
      expect(
        result.expressions.any((expression) => expression.contains('/')),
        isTrue,
      );
    });

    test('supports duplicate card values', () {
      final result = solver.solve([3, 3, 8, 8]);

      expect(result.hasSolution, isTrue);
      expect(
        result.expressions.any((expression) => expression.contains('/')),
        isTrue,
      );
    });

    test('supports face-card values and labels', () {
      final result = solver.solve(
        [1, 11, 12, 13],
        labels: ['A', 'J', 'Q', 'K'],
      );

      expect(result.hasSolution, isTrue);
      expect(result.firstExpression, contains('A'));
      expect(result.firstExpression, contains('J'));
      expect(result.firstExpression, contains('Q'));
      expect(result.firstExpression, contains('K'));
    });

    test('reports unsolvable hands', () {
      final result = solver.solve([1, 1, 1, 1]);

      expect(result.hasSolution, isFalse);
      expect(result.expressions, isEmpty);
    });
  });

  group('GameState', () {
    test('starts with a generated solvable hand', () {
      final generator = SolvableHandGenerator(
        maxAttempts: 2,
        candidateFactory: _candidateSequence([
          [1, 1, 1, 1],
          [1, 2, 3, 4],
        ]),
      );
      final gameState = GameState(
        targetNumber: 24,
        handGenerator: generator,
      );
      const solver = TwentyFourSolver(maxSolutions: 1);

      expect(gameState.currentCards, hasLength(4));
      expect(
        gameState.currentCards.map((card) => card.value),
        [1, 2, 3, 4],
      );
      expect(
        solver.hasSolution(
          gameState.currentCards.map((card) => card.value).toList(),
          target: 24,
        ),
        isTrue,
      );
      expect(gameState.dealtHands, hasLength(1));
      expect(gameState.hasNextRound(), isTrue);
    });

    test('deals independently generated solvable hands across rounds', () {
      final generator = SolvableHandGenerator(
        candidateFactory: _candidateSequence([
          [1, 2, 3, 4],
          [3, 3, 8, 8],
        ]),
      );
      final gameState = GameState(
        targetNumber: 24,
        handGenerator: generator,
      );

      gameState.currentRound = 2;
      gameState.dealNewCards();

      expect(
        gameState.currentCards.map((card) => card.value),
        [3, 3, 8, 8],
      );
      expect(gameState.dealtHands, hasLength(2));
    });

    test('reports no next round after the thirteenth round', () {
      final gameState = GameState(
        targetNumber: 24,
        handGenerator: SolvableHandGenerator(
          candidateFactory: _candidateSequence([
            [1, 2, 3, 4],
          ]),
        ),
      );

      gameState.currentRound = GameState.totalRounds;

      expect(gameState.hasNextRound(), isFalse);
    });
  });

  group('SolvableHandGenerator', () {
    test('builds a standard 52-card deck', () {
      final deck = SolvableHandGenerator.standardDeck();

      expect(deck, hasLength(52));
      expect(
        deck.map((card) => '${card.value}-${card.suit}').toSet(),
        hasLength(52),
      );
    });

    test('skips unsolvable candidates and returns a solvable hand', () {
      final generator = SolvableHandGenerator(
        maxAttempts: 2,
        candidateFactory: _candidateSequence([
          [1, 1, 1, 1],
          [1, 2, 3, 4],
        ]),
      );

      final hand = generator.generate(target: 24);

      expect(hand.map((card) => card.value), [1, 2, 3, 4]);
      expect(
        const TwentyFourSolver(maxSolutions: 1).hasSolution(
          hand.map((card) => card.value).toList(),
          target: 24,
        ),
        isTrue,
      );
    });

    test('throws if no solvable hand is found within the attempt limit', () {
      final generator = SolvableHandGenerator(
        maxAttempts: 2,
        candidateFactory: _candidateSequence([
          [1, 1, 1, 1],
          [1, 1, 1, 1],
        ]),
      );

      expect(() => generator.generate(target: 24), throwsStateError);
    });
  });

  group('PlayingCard', () {
    test('represents virtual fraction result cards exactly', () {
      final card = PlayingCard.virtual(Rational(24, 5));

      expect(card.rationalValue, Rational(24, 5));
      expect(card.display, '24/5');
      expect(PlayingCard.virtual(Rational(24)).display, '24');
      expect(PlayingCard.virtual(Rational(11)).display, '11');
      expect(PlayingCard(value: 11, suit: '\u2660').display, 'J');
    });
  });

  group('RoundPlayState', () {
    test('does not accept an intermediate 24 as a win', () {
      final cards = _cards([12, 2, 1, 1]);
      final state = RoundPlayState.initial(cards).applyOperation(
        operatorSymbol: '\u00d7',
        left: cards[0],
        right: cards[1],
      )!;

      expect(state.history, hasLength(1));
      expect(state.pool, hasLength(3));
      expect(state.pool.last.rationalValue, Rational(24));
      expect(state.isWinningTarget(24), isFalse);
    });

    test('wins only after exactly three operations and one remaining card', () {
      final cards = _cards([1, 2, 3, 4]);
      var state = RoundPlayState.initial(cards);

      state = state.applyOperation(
        operatorSymbol: '+',
        left: cards[0],
        right: cards[1],
      )!;
      state = state.applyOperation(
        operatorSymbol: '+',
        left: state.history.last.result,
        right: cards[2],
      )!;
      state = state.applyOperation(
        operatorSymbol: '\u00d7',
        left: state.history.last.result,
        right: cards[3],
      )!;

      expect(state.history, hasLength(3));
      expect(state.pool, hasLength(1));
      expect(state.isWinningTarget(24), isTrue);
    });

    test(
        'marks a three-operation non-target result as complete but not winning',
        () {
      final cards = _cards([1, 1, 1, 1]);
      var state = RoundPlayState.initial(cards);

      state = state.applyOperation(
        operatorSymbol: '+',
        left: cards[0],
        right: cards[1],
      )!;
      state = state.applyOperation(
        operatorSymbol: '+',
        left: cards[2],
        right: cards[3],
      )!;
      state = state.applyOperation(
        operatorSymbol: '+',
        left: state.pool[0],
        right: state.pool[1],
      )!;

      expect(state.isComplete, isTrue);
      expect(state.pool.single.rationalValue, Rational(4));
      expect(state.isWinningTarget(24), isFalse);
    });

    test('undo restores the cards consumed by the last operation', () {
      final cards = _cards([8, 3, 2, 1]);
      final state = RoundPlayState.initial(cards).applyOperation(
        operatorSymbol: '-',
        left: cards[0],
        right: cards[1],
      )!;

      final undone = state.undoLastOperation();

      expect(undone.history, isEmpty);
      expect(undone.pool, hasLength(4));
      for (final card in cards) {
        expect(
          undone.pool.any((candidate) => identical(candidate, card)),
          isTrue,
        );
      }
    });

    test('rejects division by zero without changing the round', () {
      final cards = _cards([1, 1, 2, 3]);
      final state = RoundPlayState.initial(cards).applyOperation(
        operatorSymbol: '-',
        left: cards[0],
        right: cards[1],
      )!;
      final zeroCard = state.history.last.result;

      final rejected = state.applyOperation(
        operatorSymbol: '\u00f7',
        left: cards[2],
        right: zeroCard,
      );

      expect(rejected, isNull);
      expect(state.history, hasLength(1));
      expect(state.pool, hasLength(3));
    });
  });
}

List<PlayingCard> _cards(List<int> values) {
  return [for (final value in values) PlayingCard(value: value)];
}

HandCandidateFactory _candidateSequence(List<List<int>> hands) {
  var index = 0;

  return () {
    final hand = index < hands.length ? hands[index] : hands.last;
    index++;
    return _cards(hand);
  };
}
