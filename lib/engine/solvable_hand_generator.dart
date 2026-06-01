import 'dart:math';

import '../models/card.dart';
import 'twenty_four_solver.dart';

typedef HandCandidateFactory = List<PlayingCard> Function();

class SolvableHandGenerator {
  final TwentyFourSolver solver;
  final Random random;
  final int maxAttempts;
  final HandCandidateFactory? candidateFactory;

  SolvableHandGenerator({
    TwentyFourSolver? solver,
    Random? random,
    this.maxAttempts = 5000,
    this.candidateFactory,
  })  : solver = solver ?? const TwentyFourSolver(maxSolutions: 1),
        random = random ?? Random();

  List<PlayingCard> generate({int target = 24}) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = candidateFactory?.call() ?? _drawRandomHand();
      if (candidate.length != 4) {
        throw StateError('A 24-point hand must contain exactly four cards.');
      }

      final values = candidate.map((card) => card.value).toList();
      if (solver.hasSolution(values, target: target)) {
        return List.unmodifiable(candidate);
      }
    }

    throw StateError(
      'Could not generate a solvable hand for target $target in '
      '$maxAttempts attempts.',
    );
  }

  List<PlayingCard> _drawRandomHand() {
    final deck = standardDeck()..shuffle(random);
    return deck.take(4).toList(growable: false);
  }

  static List<PlayingCard> standardDeck() {
    return [
      for (var value = 1; value <= 13; value++)
        for (final suit in const ['\u2660', '\u2665', '\u2666', '\u2663'])
          PlayingCard(value: value, suit: suit),
    ];
  }
}
