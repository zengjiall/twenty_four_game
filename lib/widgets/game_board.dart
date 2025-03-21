import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../widgets/card_face_painter.dart';
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
  late GameState gameState;
  final Map<String, Map<String, PlayingCard?>> operatorCards = {};
  final List<Map<String, dynamic>> history = [];
  bool? _initialHasSolution; // 存储初始牌组是否有解
  List<String>? _initialSolutions; // 存储初始解法

  final Map<String, GlobalKey> _operatorKeys = {
    '+': GlobalKey(),
    '-': GlobalKey(),
    '×': GlobalKey(),
    '÷': GlobalKey(),
  };

  final GlobalKey _cardAreaKey = GlobalKey();

  // 添加一个类成员变量来存储 OverlayEntry
  OverlayEntry? _currentOverlay;

  // 计时相关变量
  Timer? _timer;
  int _remainingSeconds = 60;
  List<int> _successTimes = []; // 存储成功时的用时
  List<int> _allTimes = []; // 存储所有回合的用时（包括成功和失败）
  int _correctNoSolutionCount = 0; // 正确判断无解的次数
  int _failureCount = 0; // 失败的总次数
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
    _initializeOperatorCards();
    _calculateInitialSolutions();
    _startTimer();
  }

  void _initializeOperatorCards() {
    operatorCards.clear();
    operatorCards.addAll({
      '+': {'left': null, 'right': null},
      '-': {'left': null, 'right': null},
      '×': {'left': null, 'right': null},
      '÷': {'left': null, 'right': null},
    });
  }

  void _calculateInitialSolutions() {
    List<String> solutions = _findAllSolutions(
        gameState.currentCards.map((card) => card.value).toList(),
        widget.targetNumber);
    _initialSolutions = _normalizeAndDeduplicateSolutions(solutions);
    _initialHasSolution = _initialSolutions!.isNotEmpty;
  }

  bool _findSolution(List<int> numbers, int target) {
    if (numbers.length == 1) {
      return numbers[0] == target;
    }

    for (int i = 0; i < numbers.length; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        int num1 = numbers[i];
        int num2 = numbers[j];

        // 创建新的数字列表，移除已使用的数字
        List<int> remainingNumbers = List.from(numbers);
        remainingNumbers.removeAt(j);
        remainingNumbers.removeAt(i);

        // 尝试所有可能的运算
        // 加法
        remainingNumbers.add(num1 + num2);
        if (_findSolution(remainingNumbers, target)) return true;
        remainingNumbers.removeLast();

        // 减法（两种顺序都要尝试）
        remainingNumbers.add(num1 - num2);
        if (_findSolution(remainingNumbers, target)) return true;
        remainingNumbers.removeLast();

        remainingNumbers.add(num2 - num1);
        if (_findSolution(remainingNumbers, target)) return true;
        remainingNumbers.removeLast();

        // 乘法
        remainingNumbers.add(num1 * num2);
        if (_findSolution(remainingNumbers, target)) return true;
        remainingNumbers.removeLast();

        // 除法（两种顺序都要尝试，且需要检查除数不为0且能整除）
        if (num2 != 0 && num1 % num2 == 0) {
          remainingNumbers.add(num1 ~/ num2);
          if (_findSolution(remainingNumbers, target)) return true;
          remainingNumbers.removeLast();
        }

        if (num1 != 0 && num2 % num1 == 0) {
          remainingNumbers.add(num2 ~/ num1);
          if (_findSolution(remainingNumbers, target)) return true;
          remainingNumbers.removeLast();
        }

        // 分数运算（如果结果是整数）
        if (num2 != 0) {
          double divResult = num1 / num2;
          if (divResult == divResult.roundToDouble()) {
            remainingNumbers.add(divResult.round());
            if (_findSolution(remainingNumbers, target)) return true;
            remainingNumbers.removeLast();
          }
        }

        if (num1 != 0) {
          double divResult = num2 / num1;
          if (divResult == divResult.roundToDouble()) {
            remainingNumbers.add(divResult.round());
            if (_findSolution(remainingNumbers, target)) return true;
            remainingNumbers.removeLast();
          }
        }
      }
    }

    return false;
  }

  // 可选：添加一个方法来找到所有可能的解
  List<String> _findAllSolutions(List<int> numbers, int target) {
    List<String> solutions = [];
    _findSolutionsHelper(numbers, target, [], solutions);
    return solutions;
  }

  void _findSolutionsHelper(
    List<int> numbers,
    int target,
    List<String> steps,
    List<String> solutions,
  ) {
    if (numbers.length == 1 && numbers[0] == target) {
      solutions.add(steps.join(' '));
      return;
    }

    for (int i = 0; i < numbers.length; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        int num1 = numbers[i];
        int num2 = numbers[j];
        List<int> remainingNumbers = List.from(numbers);
        remainingNumbers.removeAt(j);
        remainingNumbers.removeAt(i);

        // 尝试所有运算
        void tryOperation(String op, int result) {
          remainingNumbers.add(result);
          steps.add('$num1 $op $num2 = $result');
          _findSolutionsHelper(remainingNumbers, target, steps, solutions);
          steps.removeLast();
          remainingNumbers.removeLast();
        }

        // 加法
        tryOperation('+', num1 + num2);

        // 减法
        tryOperation('-', num1 - num2);
        if (num1 != num2) {
          tryOperation('-', num2 - num1);
        }

        // 乘法
        tryOperation('×', num1 * num2);

        // 除法
        if (num2 != 0 && num1 % num2 == 0) {
          tryOperation('÷', num1 ~/ num2);
        }
        if (num1 != 0 && num2 % num1 == 0 && num1 != num2) {
          tryOperation('÷', num2 ~/ num1);
        }
      }
    }
  }

  void _undoLastMove() {
    if (history.isEmpty) return;

    setState(() {
      final lastMove = history.removeLast();

      // 移除新生成的牌
      gameState.currentCards.remove(lastMove['resultCard'] as PlayingCard);

      // 恢复原来的牌
      gameState.currentCards.addAll(
          (lastMove['removedCards'] as List<PlayingCard>).map((card) => card));

      // 清空运算符位置
      final operator = lastMove['operator'] as String;
      operatorCards[operator]!['left'] = null;
      operatorCards[operator]!['right'] = null;
    });
  }

  String _getCardLabel(int value) {
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

  String _getCardImageName(int value, String suit) {
    String valueName;
    switch (value) {
      case 1:
        valueName = 'ace';
        break;
      case 11:
        valueName = 'jack';
        break;
      case 12:
        valueName = 'queen';
        break;
      case 13:
        valueName = 'king';
        break;
      default:
        valueName = value.toString();
    }

    String suitName;
    switch (suit) {
      case '♠':
        suitName = 'spades';
        break;
      case '♥':
        suitName = 'hearts';
        break;
      case '♦':
        suitName = 'diamonds';
        break;
      case '♣':
        suitName = 'clubs';
        break;
      default:
        suitName = '';
    }

    return '${valueName}_of_$suitName.png';
  }

  List<Widget> _buildCardPattern(String suit, int value, double size) {
    String imagePath = 'assets/images/${_getCardImageName(value, suit)}';

    return [
      Center(
        child: Image.asset(
          imagePath,
          width: size * 0.8,
          height: size * 1.0,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // 如果图片加载失败，显示文字
            return Text(
              _getCardLabel(value),
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                color:
                    (suit == '♥' || suit == '♦') ? Colors.red : Colors.black87,
              ),
            );
          },
        ),
      ),
    ];
  }

  List<Offset> _getPatternPositions(int value) {
    // 预定义的花色位置，根据牌面数字返回对应的位置
    switch (value) {
      case 1:
        return [const Offset(0.5, 0.5)]; // A
      case 2:
        return [const Offset(0.5, 0.3), const Offset(0.5, 0.7)];
      case 3:
        return [
          const Offset(0.5, 0.2),
          const Offset(0.5, 0.5),
          const Offset(0.5, 0.8)
        ];
      // ... 可以继续添加其他数字的位置
      default:
        return List.generate(
            value, (i) => Offset(0.3 + (i % 2) * 0.4, 0.2 + (i ~/ 2) * 0.2));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取设备信息，用于适配不同平台
    final mediaQuery = MediaQuery.of(context);
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断

    // 计算适配系数，确保iOS上的显示与网页版保持一致的比例
    final double scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    // 适配字体大小
    final double titleFontSize =
        24 * (isIOS ? min(scaleFactor * 1.2, 1.0) : 1.0);
    final double subtitleFontSize =
        20 * (isIOS ? min(scaleFactor * 1.2, 1.0) : 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        title: Row(
          children: [
            Text(
              '目标数字: ${widget.targetNumber}',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 20 * (isIOS ? scaleFactor : 1.0)),
            Text(
              '轮数: ${gameState.currentRound}/${GameState.totalRounds}',
              style: TextStyle(
                color: Colors.white,
                fontSize: subtitleFontSize,
              ),
            ),
            SizedBox(width: 20 * (isIOS ? scaleFactor : 1.0)),
            Text(
              '得分: ${gameState.score}',
              style: TextStyle(
                color: Colors.white,
                fontSize: subtitleFontSize,
              ),
            ),
          ],
        ),
        actions: [],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 获取屏幕方向和移动设备判断
          final isMobile = mediaQuery.size.width < 600;
          final isPortrait = mediaQuery.orientation == Orientation.portrait;

          // 计算合适的卡片大小，适配不同设备和方向
          double cardSize;
          if (isMobile) {
            if (isPortrait) {
              // 移动设备竖屏模式
              cardSize =
                  (constraints.maxWidth - (isIOS ? 120 * scaleFactor : 140)) /
                      4;
            } else {
              // 移动设备横屏模式
              cardSize =
                  (constraints.maxWidth - (isIOS ? 180 * scaleFactor : 200)) /
                      6;
            }
          } else {
            // 桌面模式
            cardSize =
                (constraints.maxWidth - (isIOS ? 180 * scaleFactor : 200)) / 6;
          }

          // 限制卡片大小范围
          cardSize = cardSize.clamp(isIOS ? 50.0 : 60.0, isIOS ? 90.0 : 100.0);

          // 移动设备竖屏模式使用不同的布局
          if (isMobile && isPortrait) {
            return Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildCardArea(cardSize: cardSize),
                    ),
                    Expanded(
                      flex: 3,
                      child: _buildOperatorArea(cardSize: cardSize),
                    ),
                    // 底部按钮区域
                    Container(
                      height: 80,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _undoLastMove,
                              icon: const Icon(Icons.undo, size: 20),
                              label: const Text('撤销'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleNoSolution(),
                              icon: const Icon(Icons.close, size: 20),
                              label: const Text('无解'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 倒计时器窗口 - 竖屏模式放在顶部中间
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(child: _buildCountdownTimer()),
                ),
              ],
            );
          } else {
            // 横屏或桌面模式使用原有布局
            return Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildCardArea(cardSize: cardSize),
                          ),
                          Expanded(
                            flex: 3,
                            child: _buildOperatorArea(cardSize: cardSize),
                          ),
                        ],
                      ),
                    ),
                    // 右侧按钮区域
                    Container(
                      width: isMobile ? 100 : 120,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _undoLastMove,
                            icon: const Icon(Icons.undo),
                            label: const Text('撤销'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 10 : 20, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _handleNoSolution(),
                            icon: const Icon(Icons.close),
                            label: const Text('无解'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 10 : 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // 倒计时器窗口 - 横屏模式放在右侧按钮区域左边
                Positioned(
                  top: 20,
                  right: isMobile ? 110 : 140,
                  child: _buildCountdownTimer(),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCardArea({required double cardSize}) {
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    // 根据屏幕方向调整间距
    final double spacing = isMobile && isPortrait
        ? 12 // 移动设备竖屏模式使用更小的间距
        : (isIOS ? 16 * scaleFactor : 16);

    return Container(
      key: _cardAreaKey,
      padding: EdgeInsets.all(
          isMobile && isPortrait ? 8 : (isIOS ? 16 * scaleFactor : 16)),
      child: Center(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          alignment: WrapAlignment.center,
          children: gameState.currentCards.map((card) {
            // 检查卡片是否已经在运算区域
            bool isInOperatorArea = false;
            operatorCards.forEach((op, sides) {
              if (sides['left'] == card || sides['right'] == card) {
                isInOperatorArea = true;
              }
            });

            // 如果卡片在运算区域，则不显示
            if (isInOperatorArea) {
              return const SizedBox.shrink();
            }

            return Draggable<PlayingCard>(
              data: card,
              feedback: _buildCard(card, size: cardSize, opacity: 0.8),
              childWhenDragging: const SizedBox.shrink(), // 拖拽时原位置不显示
              child: _buildCard(card, size: cardSize),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDraggableCard(PlayingCard card) {
    return Draggable<PlayingCard>(
      data: card,
      feedback: _buildCard(card, size: 70),
      childWhenDragging: _buildCard(card, opacity: 0.3),
      child: _buildCard(card),
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.translucent,
    );
  }

  // 添加一个辅助方法来生成分数表示
  String _formatNumber(int numerator, int denominator) {
    if (denominator == 1) {
      return numerator.toString();
    }
    return '$numerator/$denominator';
  }

  // 修改运算结果的处理
  void _performOperation(String operator, PlayingCard left, PlayingCard right) {
    int resultNum, resultDen;
    String operationString;

    // 将数字转换为分数形式
    int leftNum = left.numerator == 0 ? left.value : left.numerator;
    int leftDen = left.denominator;
    int rightNum = right.numerator == 0 ? right.value : right.numerator;
    int rightDen = right.denominator;

    switch (operator) {
      case '+':
        resultNum = leftNum * rightDen + rightNum * leftDen;
        resultDen = leftDen * rightDen;
        operationString = '$leftNum/$leftDen + $rightNum/$rightDen';
        break;
      case '-':
        resultNum = leftNum * rightDen - rightNum * leftDen;
        resultDen = leftDen * rightDen;
        operationString = '$leftNum/$leftDen - $rightNum/$rightDen';
        break;
      case '×':
        resultNum = leftNum * rightNum;
        resultDen = leftDen * rightDen;
        operationString = '$leftNum/$leftDen × $rightNum/$rightDen';
        break;
      case '÷':
        if (rightNum == 0) {
          throw Exception('除数不能为0');
        }
        resultNum = leftNum * rightDen;
        resultDen = leftDen * rightNum;
        operationString = '$leftNum/$leftDen ÷ $rightNum/$rightDen';
        break;
      default:
        throw Exception('未知运算符');
    }

    // 处理负数，确保分母为正
    if (resultDen < 0) {
      resultNum = -resultNum;
      resultDen = -resultDen;
    }

    // 化简分数
    int gcd = _findGCD(resultNum.abs(), resultDen.abs());
    resultNum = resultNum ~/ gcd;
    resultDen = resultDen ~/ gcd;

    // 创建结果卡片并更新状态
    PlayingCard resultCard = PlayingCard(
      value: -1,
      numerator: resultNum,
      denominator: resultDen,
    );

    setState(() {
      // 更新游戏状态
      gameState.currentCards.remove(left);
      gameState.currentCards.remove(right);
      operatorCards[operator]!['left'] = null;
      operatorCards[operator]!['right'] = null;

      // 记录历史
      history.add({
        'operator': operator,
        'removedCards': [left, right],
        'resultCard': resultCard,
      });
    });

    // 显示动画
    _showResultAnimation(resultCard, operator, () {
      setState(() {
        gameState.currentCards.add(resultCard);

        // 检查是否只剩下一张牌
        if (gameState.currentCards.length == 1) {
          _checkFinalResult();
        }
      });
    });

    // 将使用过的牌加入弃牌堆
    gameState.addToDiscardPile(left);
    gameState.addToDiscardPile(right);
  }

  void _checkFinalResult() {
    PlayingCard finalCard = gameState.currentCards.first;
    int finalValue = finalCard.numerator == 0
        ? finalCard.value
        : (finalCard.numerator / finalCard.denominator).round();

    if (finalValue == widget.targetNumber) {
      // 成功
      int usedTime = _calculateUsedTime();
      _successTimes.add(usedTime);
      _showGameResult(true, '恭喜你成功得到 ${widget.targetNumber}！',
          usedTime: usedTime);
    } else {
      // 失败，检查是否有解
      List<String> solutions = _findAllSolutions(
          history.first['removedCards'].map<int>((card) => card.value).toList(),
          widget.targetNumber);

      if (solutions.isEmpty) {
        _showGameResult(false, '这组牌无解。', usedAllTime: true);
      } else {
        // 得到错误答案，用时记为30秒
        _showGameResult(false, '失败了，这组牌有解。\n第一种解法：\n${solutions.first}',
            usedAllTime: true);
      }
    }
  }

  void _showGameResult(bool success, String message,
      {bool usedAllTime = false, int? usedTime}) {
    _timer?.cancel();

    // 如果usedAllTime为true，则显示用时为60秒
    if (usedAllTime) {
      usedTime = 60;
    }

    // 记录所有回合的用时
    if (usedTime != null) {
      _allTimes.add(usedTime);
    }

    // 记录失败次数
    if (!success) {
      _failureCount++;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(success ? '成功！' : '失败'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            if (usedTime != null) Text('本轮用时：$usedTime 秒'),
            if (_successTimes.isNotEmpty)
              Text(
                  '平均用时：${(_successTimes.reduce((a, b) => a + b) / _successTimes.length).toStringAsFixed(1)} 秒'),
            Text('当前回合：${gameState.currentRound}/${GameState.totalRounds}'),
            if (!gameState.hasNextRound())
              const Text('\n注意：这是最后一局了！', style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (gameState.hasNextRound()) {
                _startNewRound();
              } else {
                _showFinalScore();
              }
            },
            child: Text(gameState.hasNextRound() ? '下一局' : '查看最终统计'),
          ),
        ],
      ),
    );
  }

  void _showFinalScore() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('游戏结束'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('完成回合：${gameState.currentRound}/${GameState.totalRounds}'),
            const SizedBox(height: 8),
            Text('成功次数：${_successTimes.length}/${GameState.totalRounds}'),
            Text('正确判断无解次数：$_correctNoSolutionCount/${GameState.totalRounds}'),
            Text('失败次数：$_failureCount/${GameState.totalRounds}'),
            const SizedBox(height: 8),
            if (_successTimes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                  '成功平均用时：${(_successTimes.reduce((a, b) => a + b) / _successTimes.length).toStringAsFixed(1)} 秒'),
              Text('最快用时：${_successTimes.reduce(min)} 秒'),
              Text('最慢用时：${_successTimes.reduce(max)} 秒'),
            ],
            if (_allTimes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                  '所有回合平均用时：${(_allTimes.reduce((a, b) => a + b) / _allTimes.length).toStringAsFixed(1)} 秒'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomePage(),
                ),
              );
            },
            child: const Text('开始新游戏'),
          ),
        ],
      ),
    );
  }

  void _showResultAnimation(
      PlayingCard card, String operator, VoidCallback onComplete) {
    // 获取运算符的全局位置
    final RenderBox? operatorBox = _getOperatorPosition(operator);
    if (operatorBox == null) return;

    final Offset operatorPosition = operatorBox.localToGlobal(Offset.zero);
    final Size operatorSize = operatorBox.size;

    // 获取卡片区域的全局位置
    final RenderBox? cardAreaBox =
        _cardAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (cardAreaBox == null) return;

    final Offset cardAreaPosition = cardAreaBox.localToGlobal(Offset.zero);
    final Size cardAreaSize = cardAreaBox.size;

    _currentOverlay = OverlayEntry(
      builder: (context) => TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(
          begin: Offset(
            operatorPosition.dx + operatorSize.width / 2,
            operatorPosition.dy - 50,
          ),
          end: Offset(
            cardAreaPosition.dx + cardAreaSize.width / 2,
            cardAreaPosition.dy + cardAreaSize.height / 2,
          ),
        ),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (context, offset, child) {
          return Positioned(
            left: offset.dx - 50,
            top: offset.dy - 70,
            child: child!,
          );
        },
        child: _buildCard(card, size: 100),
        onEnd: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
          onComplete(); // 调用完成回调
        },
      ),
    );
    Overlay.of(context).insert(_currentOverlay!);
  }

  // 添加辅助方法计算最大公约数
  int _findGCD(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  Widget _buildCard(PlayingCard card,
      {double size = 100, double opacity = 1.0}) {
    // 修复牌值显示
    String getCardValue() {
      if (card.numerator != 0) {
        return card.denominator == 1
            ? card.numerator.toString()
            : '${card.numerator}/${card.denominator}';
      }
      // 对于初始牌，根据实际值显示
      if (card.value > 10) {
        switch (card.value) {
          case 11:
            return 'J';
          case 12:
            return 'Q';
          case 13:
            return 'K';
          default:
            return card.value.toString();
        }
      }
      return card.value.toString();
    }

    bool isInitialCard =
        gameState.currentCards.contains(card) && card.numerator == 0;

    if (!isInitialCard) {
      return Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size * 1.4,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              getCardValue(),
              style: TextStyle(
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    // 初始牌的显示逻辑
    Color cardColor =
        card.suit != null && (card.suit == '♥' || card.suit == '♦')
            ? Colors.red
            : Colors.black87;
    String label = _getCardLabel(card.value);

    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size * 1.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 5,
              left: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: size * 0.2,
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                  if (card.suit != null)
                    Text(
                      card.suit!,
                      style: TextStyle(
                        fontSize: size * 0.2,
                        color: cardColor,
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 5,
              right: 5,
              child: Transform.rotate(
                angle: 3.14159,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                    if (card.suit != null)
                      Text(
                        card.suit!,
                        style: TextStyle(
                          fontSize: size * 0.2,
                          color: cardColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Center(
              child: card.suit != null
                  ? Image.asset(
                      'assets/images/${_getCardImageName(card.value, card.suit!)}',
                      width: size * 0.8,
                      height: size * 1.0,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: size * 0.5,
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        );
                      },
                    )
                  : Text(
                      label,
                      style: TextStyle(
                        fontSize: size * 0.5,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorArea({required double cardSize}) {
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断

    return Container(
      padding: EdgeInsets.all(
          isMobile && isPortrait ? 8 : (isIOS ? 16 * scaleFactor : 16)),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isIOS ? 24 * scaleFactor : 24),
          topRight: Radius.circular(isIOS ? 24 * scaleFactor : 24),
        ),
      ),
      child: isMobile && isPortrait
          // 移动设备竖屏模式：使用网格布局
          ? GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 1.5, // 增加宽高比，使其更加宽松
              crossAxisSpacing: isIOS ? 16 * scaleFactor : 16, // 增加间距
              mainAxisSpacing: isIOS ? 16 * scaleFactor : 16, // 增加间距
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.all(8), // 添加内边距
              children: [
                _buildOperatorWithCards('+', cardSize),
                _buildOperatorWithCards('-', cardSize),
                _buildOperatorWithCards('×', cardSize),
                _buildOperatorWithCards('÷', cardSize),
              ],
            )
          // 横屏或桌面模式：使用原有的列布局
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildOperatorWithCards('+', cardSize)),
                    SizedBox(width: isIOS ? 32 * scaleFactor : 32),
                    Expanded(child: _buildOperatorWithCards('-', cardSize)),
                  ],
                ),
                SizedBox(height: isIOS ? 24 * scaleFactor : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildOperatorWithCards('×', cardSize)),
                    SizedBox(width: isIOS ? 32 * scaleFactor : 32),
                    Expanded(child: _buildOperatorWithCards('÷', cardSize)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildOperatorWithCards(String operator, double cardSize) {
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    // 竖屏模式下使用更合适的间距
    final double horizontalSpacing =
        isMobile && isPortrait ? 12 : (isIOS ? 16 * scaleFactor : 16);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(isIOS ? 16 * scaleFactor : 16),
        border: Border.all(
          color: const Color(0xFF374151),
          width: isIOS ? 1 * scaleFactor : 1,
        ),
      ),
      padding: EdgeInsets.all(
          isMobile && isPortrait ? 6 : (isIOS ? 8 * scaleFactor : 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCardDropZone(operator, 'left', cardSize),
          SizedBox(width: horizontalSpacing),
          _buildOperatorZone(operator),
          SizedBox(width: horizontalSpacing),
          _buildCardDropZone(operator, 'right', cardSize),
        ],
      ),
    );
  }

  Widget _buildOperatorZone(String operator) {
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    // 根据设备类型和方向调整大小
    final double operatorSize = isMobile && isPortrait
        ? 60 // 移动设备竖屏模式使用更合适的尺寸
        : (isIOS ? 60 * scaleFactor : 60);

    return Container(
      key: _operatorKeys[operator],
      width: operatorSize, // 增大宽度
      height: operatorSize, // 增大高度
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(isIOS ? 12 * scaleFactor : 12),
        border: Border.all(
          color: const Color(0xFF4B5563),
          width: isIOS ? 2 * scaleFactor : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: isIOS ? 4 * scaleFactor : 4,
            offset: Offset(0, isIOS ? 2 * scaleFactor : 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          operator,
          style: TextStyle(
            fontSize: isMobile && isPortrait ? 48 : 36, // 增大字号
            fontWeight: FontWeight.w900, // 加粗
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCardDropZone(String operator, String side, double cardSize) {
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    // 竖屏模式下调整卡片大小，使其更小以避免重叠
    final double dropZoneWidth =
        isMobile && isPortrait ? cardSize * 0.8 : cardSize * 1.2;
    final double dropZoneHeight =
        isMobile && isPortrait ? cardSize * 1.2 : cardSize * 1.6;

    return DragTarget<PlayingCard>(
      builder: (context, candidateData, rejectedData) {
        PlayingCard? currentCard = operatorCards[operator]![side];
        return Container(
          width: dropZoneWidth,
          height: dropZoneHeight,
          margin: EdgeInsets.all(
              isMobile && isPortrait ? 4 : (isIOS ? 8 * scaleFactor : 8)),
          decoration: BoxDecoration(
            color: const Color(0xFF2D3748),
            borderRadius: BorderRadius.circular(
                isMobile && isPortrait ? 8 : (isIOS ? 12 * scaleFactor : 12)),
            border: Border.all(
              color: candidateData.isNotEmpty
                  ? const Color(0xFF60A5FA)
                  : const Color(0xFF4B5563),
              width: isMobile && isPortrait ? 1 : (isIOS ? 2 * scaleFactor : 2),
            ),
          ),
          child: currentCard != null
              ? _buildCard(currentCard, size: cardSize)
              : Center(
                  child: Icon(
                    Icons.add_circle_outline,
                    color: const Color(0xFF6B7280),
                    size: isMobile && isPortrait
                        ? 24
                        : (isIOS ? 32 * scaleFactor : 32),
                  ),
                ),
        );
      },
      onWillAccept: (card) => operatorCards[operator]![side] == null,
      onAccept: (card) {
        setState(() {
          operatorCards[operator]![side] = card;

          // 检查是否可以执行运算
          if (operatorCards[operator]!['left'] != null &&
              operatorCards[operator]!['right'] != null) {
            // 延迟一帧执行运算，确保UI更新完成
            Future.microtask(() {
              _performOperation(operator, operatorCards[operator]!['left']!,
                  operatorCards[operator]!['right']!);
            });
          }
        });
      },
    );
  }

  void _handleNoSolution() {
    if (_initialHasSolution == true) {
      // 误判有解为无解，算作用完全部时间
      _showGameResult(
          false, '错误！这组牌是有解的。\n这是其中一种解法：\n${_initialSolutions!.first}',
          usedAllTime: true);
    } else {
      // 正确判断无解
      int usedTime = _calculateUsedTime();
      _successTimes.add(usedTime);
      _correctNoSolutionCount++; // 增加正确判断无解的计数
      _showGameResult(true, '正确！这组牌确实无解。\n用时：$usedTime 秒', usedTime: usedTime);
    }
  }

  String _normalizeSolution(String solution) {
    // 将解法拆分成步骤
    List<String> steps = solution.split(' ');
    List<List<String>> operations = [];

    // 提取每个操作步骤
    for (int i = 0; i < steps.length; i += 4) {
      if (i + 3 < steps.length) {
        operations.add([steps[i], steps[i + 1], steps[i + 2]]);
      }
    }

    // 规范化每个操作
    for (var op in operations) {
      // 处理加法和乘法的交换律
      if (op[1] == '+' || op[1] == '×') {
        var num1 = int.parse(op[0]);
        var num2 = int.parse(op[2]);
        if (num1 > num2) {
          op[0] = num2.toString();
          op[2] = num1.toString();
        }
      }

      // 处理特殊情况
      if (op[1] == '×' && op[2] == '1' || op[1] == '÷' && op[2] == '1') {
        op[1] = '×';
        op[2] = '1';
      }
      if (op[1] == '+' && op[2] == '0' || op[1] == '-' && op[2] == '0') {
        op[1] = '+';
        op[2] = '0';
      }
    }

    // 对加法和乘法的操作进行排序（结合律）
    operations.sort((a, b) {
      if ((a[1] == '+' && b[1] == '+') || (a[1] == '×' && b[1] == '×')) {
        return int.parse(a[0]).compareTo(int.parse(b[0]));
      }
      return 0;
    });

    // 重新组合成规范化的解法字符串
    String normalizedSolution = '';
    for (var op in operations) {
      normalizedSolution += '${op.join(' ')} = ';
    }
    return normalizedSolution;
  }

  List<String> _normalizeAndDeduplicateSolutions(List<String> solutions) {
    // 规范化每个解法
    List<String> normalizedSolutions = solutions.map((solution) {
      return _normalizeSolution(solution);
    }).toList();

    // 去除重复解法
    return normalizedSolutions.toSet().toList();
  }

  void _startNewRound() {
    setState(() {
      for (var card in gameState.currentCards) {
        gameState.addToDiscardPile(card);
      }

      gameState.currentRound++;
      gameState.dealNewCards();
      history.clear();
      operatorCards.clear();
      _initializeOperatorCards();
      _calculateInitialSolutions();
      _startTimer();
    });
  }

  RenderBox? _getOperatorPosition(String operator) {
    return _operatorKeys[operator]?.currentContext?.findRenderObject()
        as RenderBox?;
  }

  // 构建倒计时器窗口
  Widget _buildCountdownTimer() {
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600; // 移动设备判断
    final isPortrait = mediaQuery.orientation == Orientation.portrait; // 竖屏判断
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    // 根据剩余时间确定颜色
    Color timerColor = Colors.green;
    if (_remainingSeconds <= 20) {
      timerColor = Colors.red;
    } else if (_remainingSeconds <= 40) {
      timerColor = Colors.orange;
    }

    // 根据屏幕方向调整计时器大小
    double timerSize = isMobile && isPortrait
        ? 80 // 移动设备竖屏模式使用更小的尺寸
        : (isIOS ? 100 * scaleFactor : 100);

    return Container(
      width: timerSize,
      height: timerSize,
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.8),
        borderRadius: BorderRadius.circular(timerSize / 2),
        border: Border.all(
            color: timerColor,
            width: isMobile && isPortrait ? 2 : (isIOS ? 3 * scaleFactor : 3)),
        boxShadow: [
          BoxShadow(
            color: timerColor.withOpacity(0.5),
            blurRadius:
                isMobile && isPortrait ? 6 : (isIOS ? 10 * scaleFactor : 10),
            spreadRadius:
                isMobile && isPortrait ? 1 : (isIOS ? 2 * scaleFactor : 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 圆形进度指示器
          SizedBox(
            width: timerSize * 0.9,
            height: timerSize * 0.9,
            child: CircularProgressIndicator(
              value: _remainingSeconds / 60, // 60秒为满值
              strokeWidth:
                  isMobile && isPortrait ? 4 : (isIOS ? 8 * scaleFactor : 8),
              backgroundColor: Colors.grey.withOpacity(0.3),
              color: timerColor,
            ),
          ),
          // 倒计时数字
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_remainingSeconds',
                style: TextStyle(
                  fontSize: isMobile && isPortrait ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '秒',
                style: TextStyle(
                  fontSize: isMobile && isPortrait ? 12 : 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _roundStartTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _handleTimeUp();
        }
      });
    });
  }

  void _handleTimeUp() {
    _showGameResult(false, '时间到！', usedAllTime: true);
  }

  int _calculateUsedTime() {
    if (_roundStartTime == null) return 60;
    return 60 - _remainingSeconds;
  }
}
