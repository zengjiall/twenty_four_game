import 'rational.dart';

class TwentyFourSolver {
  final int maxSolutions;

  const TwentyFourSolver({this.maxSolutions = 100});

  TwentyFourSolveResult solve(
    List<int> values, {
    int target = 24,
    List<String>? labels,
  }) {
    if (labels != null && labels.length != values.length) {
      throw ArgumentError.value(
        labels,
        'labels',
        'Labels must match the value count.',
      );
    }

    final targetValue = Rational(target);
    final terms = <_Term>[
      for (var index = 0; index < values.length; index++)
        _Term(
          value: Rational(values[index]),
          expression: labels == null ? values[index].toString() : labels[index],
        ),
    ];
    final expressions = <String>{};
    final visited = <String>{};

    _search(terms, targetValue, expressions, visited);

    return TwentyFourSolveResult(
      target: targetValue,
      expressions: expressions.toList(growable: false),
    );
  }

  bool hasSolution(List<int> values, {int target = 24}) {
    return const TwentyFourSolver(maxSolutions: 1)
        .solve(values, target: target)
        .hasSolution;
  }

  void _search(
    List<_Term> terms,
    Rational target,
    Set<String> expressions,
    Set<String> visited,
  ) {
    if (expressions.length >= maxSolutions) {
      return;
    }

    final stateKey = _stateKey(terms);
    if (!visited.add(stateKey)) {
      return;
    }

    if (terms.length == 1) {
      if (terms.first.value == target) {
        expressions.add(terms.first.expression);
      }
      return;
    }

    for (var leftIndex = 0; leftIndex < terms.length; leftIndex++) {
      for (var rightIndex = leftIndex + 1;
          rightIndex < terms.length;
          rightIndex++) {
        final left = terms[leftIndex];
        final right = terms[rightIndex];
        final rest = <_Term>[
          for (var index = 0; index < terms.length; index++)
            if (index != leftIndex && index != rightIndex) terms[index],
        ];

        for (final candidate in _combine(left, right)) {
          _search([...rest, candidate], target, expressions, visited);
          if (expressions.length >= maxSolutions) {
            return;
          }
        }
      }
    }
  }

  Iterable<_Term> _combine(_Term left, _Term right) sync* {
    yield _binary(left, right, '+', left.value + right.value);
    yield _binary(left, right, '-', left.value - right.value);
    yield _binary(right, left, '-', right.value - left.value);
    yield _binary(left, right, '*', left.value * right.value);

    if (!right.value.isZero) {
      yield _binary(left, right, '/', left.value / right.value);
    }
    if (!left.value.isZero) {
      yield _binary(right, left, '/', right.value / left.value);
    }
  }

  _Term _binary(_Term left, _Term right, String operator, Rational value) {
    return _Term(
      value: value,
      expression: '(${left.expression} $operator ${right.expression})',
    );
  }

  String _stateKey(List<_Term> terms) {
    final parts = [
      for (final term in terms) '${term.value}|${term.expression}',
    ]..sort();

    return parts.join(';');
  }
}

class TwentyFourSolveResult {
  final Rational target;
  final List<String> expressions;

  const TwentyFourSolveResult({
    required this.target,
    required this.expressions,
  });

  bool get hasSolution => expressions.isNotEmpty;

  String? get firstExpression {
    if (expressions.isEmpty) {
      return null;
    }

    return expressions.first;
  }
}

class _Term {
  final Rational value;
  final String expression;

  const _Term({
    required this.value,
    required this.expression,
  });
}
