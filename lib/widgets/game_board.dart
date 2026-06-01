import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/round_play_state.dart';
import '../engine/twenty_four_solver.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../pages/home_page.dart';

class GameBoard extends StatefulWidget {
  final int targetNumber;

  const GameBoard({
    super.key,
    required this.targetNumber,
  });

  @override
  GameBoardState createState() => GameBoardState();
}

class GameBoardState extends State<GameBoard> {
  static const _operators = ['+', '-', '\u00d7', '\u00f7'];
  static const _solver = TwentyFourSolver(maxSolutions: 1);

  late GameState gameState;
  late RoundPlayState roundState;
  late TwentyFourSolveResult _openingSolveResult;

  final Map<String, _OperationDraft> _rowDrafts = {};

  Timer? _timer;
  int _remainingSeconds = 60;
  final List<int> _successTimes = [];
  final List<int> _allTimes = [];
  int _failureCount = 0;
  DateTime? _roundStartTime;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    gameState = GameState(targetNumber: widget.targetNumber);
    _startRoundFromCurrentCards();
  }

  void _startRoundFromCurrentCards() {
    _openingSolveResult = _solveOpeningHand();
    roundState = RoundPlayState.initial(gameState.currentCards);
    _resetOperationRows();
    _startTimer();
  }

  TwentyFourSolveResult _solveOpeningHand() {
    final values = gameState.currentCards.map((card) => card.value).toList();
    final labels = gameState.currentCards.map((card) => card.display).toList();
    return _solver.solve(
      values,
      target: widget.targetNumber,
      labels: labels,
    );
  }

  void _resetOperationRows() {
    _rowDrafts
      ..clear()
      ..addEntries(
        _operators.map((operator) => MapEntry(operator, _OperationDraft())),
      );
  }

  void _startTimer() {
    _roundStartTime = DateTime.now();
    _remainingSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
        });
        _showGameResult(false, _buildTimeoutMessage());
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  int _calculateUsedTime() {
    if (_roundStartTime == null) return 60;
    return min(60, DateTime.now().difference(_roundStartTime!).inSeconds);
  }

  List<PlayingCard> get _visiblePoolCards {
    return roundState.pool.where((card) => !_isCardInDraft(card)).toList();
  }

  bool _isCardInDraft(PlayingCard card) {
    return _rowDrafts.values.any(
      (draft) => identical(draft.left, card) || identical(draft.right, card),
    );
  }

  bool _isCardInOtherDraft(String operator, PlayingCard card) {
    return _rowDrafts.entries.any((entry) {
      if (entry.key == operator) return false;
      final draft = entry.value;
      return identical(draft.left, card) || identical(draft.right, card);
    });
  }

  bool _isCardInPool(PlayingCard card) {
    return roundState.pool.any((candidate) => identical(candidate, card));
  }

  bool get _hasDraftOperands {
    return _rowDrafts.values.any(
      (draft) => draft.left != null || draft.right != null,
    );
  }

  bool _canAcceptCard(String operator, _SlotSide side, PlayingCard? card) {
    if (card == null || !roundState.canApplyOperation || !_isCardInPool(card)) {
      return false;
    }

    final draft = _rowDrafts[operator]!;
    final current = side == _SlotSide.left ? draft.left : draft.right;
    final other = side == _SlotSide.left ? draft.right : draft.left;

    if (current != null || identical(other, card)) {
      return false;
    }

    return !_isCardInOtherDraft(operator, card);
  }

  void _handleCardAccepted(
    String operator,
    _SlotSide side,
    PlayingCard card,
  ) {
    var invalidOperation = false;
    String? roundMessage;
    bool? roundSuccess;

    setState(() {
      if (!_canAcceptCard(operator, side, card)) {
        return;
      }

      final draft = _rowDrafts[operator]!;
      if (side == _SlotSide.left) {
        draft.left = card;
      } else {
        draft.right = card;
      }

      if (!draft.isReady) {
        return;
      }

      final nextState = roundState.applyOperation(
        operatorSymbol: operator,
        left: draft.left!,
        right: draft.right!,
      );

      if (nextState == null) {
        invalidOperation = true;
        draft.clearOperands();
        return;
      }

      roundState = nextState;
      gameState.currentCards = nextState.pool;
      draft.clearOperands();

      if (roundState.isWinningTarget(widget.targetNumber)) {
        roundSuccess = true;
        roundMessage =
            '\u606d\u559c\uff01\u4f60\u7528\u5b8c\u56db\u5f20\u724c\u5f97\u5230 ${widget.targetNumber}\u3002';
      } else if (roundState.isComplete) {
        roundSuccess = false;
        roundMessage =
            '\u4e09\u6b65\u5b8c\u6210\uff0c\u6700\u7ec8\u7ed3\u679c\u662f ${roundState.pool.single.display}\uff0c\u4e0d\u662f ${widget.targetNumber}\u3002';
      }
    });

    if (invalidOperation) {
      _showInvalidOperationDialog();
    } else if (roundSuccess != null && roundMessage != null) {
      _showGameResult(roundSuccess!, roundMessage!);
    }
  }

  void _clearSlot(String operator, _SlotSide side) {
    setState(() {
      final draft = _rowDrafts[operator]!;
      if (side == _SlotSide.left) {
        draft.left = null;
      } else {
        draft.right = null;
      }
    });
  }

  void _undoLastMove() {
    if (roundState.history.isEmpty) return;

    setState(() {
      roundState = roundState.undoLastOperation();
      gameState.currentCards = roundState.pool;
      _resetOperationRows();
    });
  }

  void _handleNoSolutionClaim() {
    final solution = _openingSolveResult.firstExpression;

    if (_openingSolveResult.hasSolution && solution != null) {
      _showGameResult(
        false,
        '\u672c\u5c40\u5176\u5b9e\u6709\u89e3\u3002\n${_buildSolutionLine(solution)}',
      );
      return;
    }

    _showGameResult(
      true,
      '\u5224\u65ad\u6b63\u786e\uff1a\u672c\u5c40\u65e0\u89e3\u3002',
      scoreKind: _ScoreKind.noSolution,
    );
  }

  String _buildTimeoutMessage() {
    final solution = _openingSolveResult.firstExpression;
    if (!_openingSolveResult.hasSolution || solution == null) {
      return '\u65f6\u95f4\u5230\uff01\u672c\u5c40\u65e0\u89e3\u3002';
    }

    return '\u65f6\u95f4\u5230\uff01\n${_buildSolutionLine(solution)}';
  }

  String _buildSolutionLine(String expression) {
    return '\u53c2\u8003\u7b54\u6848\uff1a${_formatExpression(expression)} = ${widget.targetNumber}';
  }

  String _formatExpression(String expression) {
    return expression.replaceAll('*', '\u00d7').replaceAll('/', '\u00f7');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 560;

    return Scaffold(
      backgroundColor: const Color(0xFF031F18),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(isNarrow ? 10 : 18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (isNarrow ? 20 : 36),
                ),
                child: _buildTableSurface(isNarrow),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableSurface(bool isNarrow) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 20),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topCenter,
          radius: 1.18,
          colors: [
            Color(0xFF0F7A4D),
            Color(0xFF063B2B),
            Color(0xFF031F18),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3A2415), width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopRail(isNarrow),
          SizedBox(height: isNarrow ? 12 : 18),
          _buildChipRail(),
          SizedBox(height: isNarrow ? 12 : 18),
          _buildHandZone(isNarrow),
          SizedBox(height: isNarrow ? 12 : 18),
          _buildOperationTable(isNarrow),
          SizedBox(height: isNarrow ? 12 : 18),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildTopRail(bool isNarrow) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: IconButton.filled(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_rounded),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF21150D),
              foregroundColor: const Color(0xFFF8E7B1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '24\u70b9\u724c\u684c',
                style: TextStyle(
                  color: const Color(0xFFFFF8E7),
                  fontSize: isNarrow ? 22 : 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Text(
                'SOLVABLE PRACTICE',
                style: TextStyle(
                  color: Color(0xFFF4C95D),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        _buildDealerButton(widget.targetNumber.toString(), 'TARGET'),
      ],
    );
  }

  Widget _buildChipRail() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildChipStat(
          label: 'ROUND',
          value: '${gameState.currentRound}/${GameState.totalRounds}',
          color: const Color(0xFFC2413A),
        ),
        _buildChipStat(
          label: 'SCORE',
          value: gameState.score.toString(),
          color: const Color(0xFF2563EB),
        ),
        _buildChipStat(
          label: 'TIME',
          value: '$_remainingSeconds',
          color: const Color(0xFFF4C95D),
          darkText: true,
        ),
        _buildChipStat(
          label: 'STEP',
          value: '${roundState.history.length}/3',
          color: const Color(0xFFF8E7B1),
          darkText: true,
        ),
      ],
    );
  }

  Widget _buildChipStat({
    required String label,
    required String value,
    required Color color,
    bool darkText = false,
  }) {
    final textColor = darkText ? const Color(0xFF21150D) : Colors.white;

    return Container(
      constraints: const BoxConstraints(minWidth: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.72), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.78),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.9,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerButton(String value, String label) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF8E7),
        border: Border.all(color: const Color(0xFFF4C95D), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF7C2D12),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                height: 1,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF21150D),
                fontSize: 28,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandZone(bool isNarrow) {
    final cardWidth = isNarrow ? 68.0 : 84.0;
    final visibleCards = _visiblePoolCards;

    return Container(
      constraints: BoxConstraints(minHeight: isNarrow ? 124 : 148),
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFF04251D).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0F7A4D), width: 2),
      ),
      child: Wrap(
        spacing: isNarrow ? 12 : 16,
        runSpacing: isNarrow ? 12 : 16,
        alignment: WrapAlignment.center,
        children: [
          for (final card in visibleCards) _buildDraggableCard(card, cardWidth),
          if (visibleCards.isEmpty) SizedBox(height: cardWidth * 1.36),
        ],
      ),
    );
  }

  Widget _buildDraggableCard(PlayingCard playingCard, double width) {
    final cardWidget = _buildCard(playingCard, width: width);
    if (!roundState.canApplyOperation) {
      return cardWidget;
    }

    return Draggable<PlayingCard>(
      data: playingCard,
      feedback: Material(
        color: Colors.transparent,
        child: _buildCard(playingCard, width: width, opacity: 0.94),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: cardWidget),
      child: cardWidget,
    );
  }

  Widget _buildOperationTable(bool isNarrow) {
    return Column(
      children: [
        for (final operator in _operators) ...[
          _buildOperationRow(operator, isNarrow),
          if (operator != _operators.last) SizedBox(height: isNarrow ? 8 : 10),
        ],
      ],
    );
  }

  Widget _buildOperationRow(String operator, bool isNarrow) {
    final slotWidth = isNarrow ? 58.0 : 72.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 7 : 12,
        vertical: isNarrow ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF21150D).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFC89432).withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOperandSlot(operator, _SlotSide.left, slotWidth),
          _buildMathGlyph(operator, isNarrow),
          _buildOperandSlot(operator, _SlotSide.right, slotWidth),
          _buildMathGlyph('=', isNarrow),
          _buildResultSlot(slotWidth),
        ],
      ),
    );
  }

  Widget _buildMathGlyph(String text, bool isNarrow) {
    return SizedBox(
      width: isNarrow ? 26 : 34,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFFF8E7B1),
          fontSize: isNarrow ? 22 : 28,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildOperandSlot(String operator, _SlotSide side, double width) {
    final draft = _rowDrafts[operator]!;
    final card = side == _SlotSide.left ? draft.left : draft.right;
    final label = side == _SlotSide.left ? 'X' : 'Y';

    return DragTarget<PlayingCard>(
      onWillAcceptWithDetails: (details) {
        return _canAcceptCard(operator, side, details.data);
      },
      onAcceptWithDetails: (details) {
        _handleCardAccepted(operator, side, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final highlighted = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: card == null ? null : () => _clearSlot(operator, side),
          child: _buildSlotFrame(
            card: card,
            label: label,
            width: width,
            highlighted: highlighted,
            isResult: false,
          ),
        );
      },
    );
  }

  Widget _buildResultSlot(double width) {
    return _buildSlotFrame(
      card: null,
      label: 'Z',
      width: width,
      highlighted: false,
      isResult: true,
    );
  }

  Widget _buildSlotFrame({
    required PlayingCard? card,
    required String label,
    required double width,
    required bool highlighted,
    required bool isResult,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: width,
      height: width * 1.36,
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFF2563EB)
            : isResult
                ? const Color(0xFF3A2415)
                : const Color(0xFF063B2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? const Color(0xFFBFDBFE)
              : isResult
                  ? const Color(0xFFC89432)
                  : const Color(0xFF0F7A4D),
          width: 2,
        ),
      ),
      child: card == null
          ? Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isResult
                      ? const Color(0xFFC89432)
                      : const Color(0xFFF8E7B1),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            )
          : _buildCard(card, width: width - 4),
    );
  }

  Widget _buildControls() {
    final canUndo = roundState.history.isNotEmpty;
    final canClaimNoSolution = roundState.history.isEmpty && !_hasDraftOperands;

    return Center(
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: canUndo ? _undoLastMove : null,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('\u64a4\u56de'),
            style: _buildControlButtonStyle(
              backgroundColor: const Color(0xFFF4C95D),
              foregroundColor: const Color(0xFF21150D),
            ),
          ),
          ElevatedButton.icon(
            onPressed: canClaimNoSolution ? _handleNoSolutionClaim : null,
            icon: const Icon(Icons.help_outline_rounded),
            label: const Text('\u65e0\u89e3'),
            style: _buildControlButtonStyle(
              backgroundColor: const Color(0xFFC2413A),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  ButtonStyle _buildControlButtonStyle({
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: const Color(0xFF3A2415),
      disabledForegroundColor: const Color(0xFF8B735A),
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildCard(
    PlayingCard card, {
    required double width,
    double opacity = 1,
  }) {
    final height = width * 1.36;
    final isRed = card.suit == '\u2665' || card.suit == '\u2666';
    final isResult = card.suit == null;
    final marker = card.suit ?? '\u2605';
    final contentColor = isResult
        ? const Color(0xFF7C2D12)
        : isRed
            ? const Color(0xFFC2413A)
            : const Color(0xFF111827);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: isResult
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF8E7),
                  Color(0xFFF8E7B1),
                ],
              )
            : null,
        color: isResult
            ? null
            : const Color(0xFFFFF8E7).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isResult ? const Color(0xFFF4C95D) : const Color(0xFFE8D9B5),
          width: isResult ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 5,
            left: 5,
            child: _buildCardCorner(card, contentColor, width, marker),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: Transform.rotate(
              angle: pi,
              child: _buildCardCorner(card, contentColor, width, marker),
            ),
          ),
          Center(
            child: Opacity(
              opacity: isResult ? 0.2 : 1,
              child: Text(
                marker,
                style: TextStyle(
                  color: contentColor,
                  fontSize: width * (isResult ? 0.62 : 0.42),
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          if (isResult)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.18),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    card.display,
                    style: TextStyle(
                      color: const Color(0xFF21150D),
                      fontSize: width * 0.46,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardCorner(
    PlayingCard card,
    Color color,
    double width,
    String marker,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.display,
          style: TextStyle(
            color: color,
            fontSize: width * 0.2,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Text(
          marker,
          style: TextStyle(
            color: color,
            fontSize: width * 0.18,
            height: 1,
          ),
        ),
      ],
    );
  }

  void _showInvalidOperationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u65e0\u6548\u7684\u8fd0\u7b97'),
        content: const Text(
          '\u8fd9\u4e2a\u8fd0\u7b97\u65e0\u6cd5\u5b8c\u6210\uff0c\u8bf7\u5c1d\u8bd5\u5176\u4ed6\u8fd0\u7b97\u3002',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u786e\u5b9a'),
          ),
        ],
      ),
    );
  }

  void _showGameResult(
    bool success,
    String message, {
    _ScoreKind scoreKind = _ScoreKind.solved,
  }) {
    final usedTime = _calculateUsedTime();
    final scoreBreakdown =
        success ? _calculateScoreBreakdown(usedTime, scoreKind) : null;
    _timer?.cancel();

    if (success) {
      _successTimes.add(usedTime);
      gameState.score += scoreBreakdown!.total;
    } else {
      _failureCount++;
    }

    _allTimes.add(usedTime);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(success ? '\u6210\u529f' : '\u5931\u8d25'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text('\u7528\u65f6\uff1a$usedTime \u79d2'),
            if (scoreBreakdown != null) ...[
              Text('\u672c\u8f6e\u5f97\u5206\uff1a${scoreBreakdown.total}'),
              Text(
                scoreBreakdown.summary,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nextRound();
            },
            child: Text(
              gameState.currentRound < GameState.totalRounds
                  ? '\u4e0b\u4e00\u8f6e'
                  : '\u67e5\u770b\u7ed3\u679c',
            ),
          ),
        ],
      ),
    );
  }

  _ScoreBreakdown _calculateScoreBreakdown(
    int usedTime,
    _ScoreKind scoreKind,
  ) {
    final baseScore = scoreKind == _ScoreKind.noSolution ? 80 : 100;
    final timeBonus = scoreKind == _ScoreKind.noSolution
        ? max(0, 60 - usedTime) ~/ 2
        : max(0, 60 - usedTime);
    final cleanBonus =
        scoreKind == _ScoreKind.solved && _isCleanIntegerPath ? 30 : 0;
    final varietyBonus =
        scoreKind == _ScoreKind.solved && _operatorVariety >= 3 ? 20 : 0;

    return _ScoreBreakdown(
      baseScore: baseScore,
      timeBonus: timeBonus,
      cleanBonus: cleanBonus,
      varietyBonus: varietyBonus,
    );
  }

  bool get _isCleanIntegerPath {
    return roundState.history.isNotEmpty &&
        roundState.history.every((move) => move.result.rationalValue.isInteger);
  }

  int get _operatorVariety {
    return roundState.history.map((move) => move.operatorSymbol).toSet().length;
  }

  void _nextRound() {
    if (gameState.currentRound < GameState.totalRounds &&
        gameState.hasNextRound()) {
      setState(() {
        gameState.currentRound++;
        gameState.dealNewCards();
        _startRoundFromCurrentCards();
      });
    } else {
      _showFinalResults();
    }
  }

  void _showFinalResults() {
    final averageSuccessTime = _successTimes.isEmpty
        ? 0
        : _successTimes.reduce((a, b) => a + b) / _successTimes.length;
    final averageTime = _allTimes.isEmpty
        ? 0
        : _allTimes.reduce((a, b) => a + b) / _allTimes.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('\u6e38\u620f\u7ed3\u675f'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('\u603b\u5f97\u5206\uff1a${gameState.score}'),
            Text('\u6210\u529f\u6b21\u6570\uff1a${_successTimes.length}'),
            Text('\u5931\u8d25\u6b21\u6570\uff1a$_failureCount'),
            Text(
              '\u5e73\u5747\u6210\u529f\u7528\u65f6\uff1a${averageSuccessTime.toStringAsFixed(1)}\u79d2',
            ),
            Text(
              '\u603b\u5e73\u5747\u7528\u65f6\uff1a${averageTime.toStringAsFixed(1)}\u79d2',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
                (route) => false,
              );
            },
            child: const Text('\u8fd4\u56de\u4e3b\u9875'),
          ),
        ],
      ),
    );
  }
}

enum _SlotSide { left, right }

class _OperationDraft {
  PlayingCard? left;
  PlayingCard? right;

  bool get isReady => left != null && right != null;

  void clearOperands() {
    left = null;
    right = null;
  }
}

enum _ScoreKind { solved, noSolution }

class _ScoreBreakdown {
  final int baseScore;
  final int timeBonus;
  final int cleanBonus;
  final int varietyBonus;

  const _ScoreBreakdown({
    required this.baseScore,
    required this.timeBonus,
    required this.cleanBonus,
    required this.varietyBonus,
  });

  int get total => baseScore + timeBonus + cleanBonus + varietyBonus;

  String get summary {
    return '\u57fa\u7840 $baseScore + \u65f6\u95f4 $timeBonus + \u6574\u6570 $cleanBonus + \u8fd0\u7b97\u7ec4\u5408 $varietyBonus';
  }
}
