import 'package:flutter/material.dart';

import '../widgets/game_board.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int targetNumber = 24;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 520;

    return Scaffold(
      backgroundColor: const Color(0xFF063B2B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isNarrow ? 18 : 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildTableCard(isNarrow),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(bool isNarrow) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 18 : 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F7A4D),
            Color(0xFF063B2B),
            Color(0xFF04251D),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF4C95D), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMiniCards(isNarrow),
          SizedBox(height: isNarrow ? 18 : 24),
          const Text(
            '24\u70b9\u724c\u684c',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFFFF8E7),
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SOLVABLE PRACTICE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF4C95D),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: isNarrow ? 22 : 28),
          _buildTargetSelector(isNarrow),
          SizedBox(height: isNarrow ? 22 : 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4C95D),
                foregroundColor: const Color(0xFF21150D),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GameBoard(targetNumber: targetNumber),
                  ),
                );
              },
              child: const Text('\u5165\u5ea7\u5f00\u5c40'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(bool isNarrow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF21150D).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC89432)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildRoundIconButton(
            icon: Icons.remove,
            onPressed: targetNumber <= 1
                ? null
                : () {
                    setState(() {
                      targetNumber--;
                    });
                  },
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'TARGET',
                  style: TextStyle(
                    color: Color(0xFFF8E7B1),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  targetNumber.toString(),
                  style: TextStyle(
                    color: const Color(0xFFFFF8E7),
                    fontSize: isNarrow ? 44 : 52,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          _buildRoundIconButton(
            icon: Icons.add,
            onPressed: () {
              setState(() {
                targetNumber++;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 46,
      height: 46,
      child: IconButton.filled(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFC2413A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF3A2415),
          disabledForegroundColor: const Color(0xFF8B735A),
          shape: const CircleBorder(),
        ),
      ),
    );
  }

  Widget _buildMiniCards(bool isNarrow) {
    final width = isNarrow ? 44.0 : 54.0;
    final cards = [
      ('A', '\u2660', const Color(0xFF111827)),
      ('10', '\u2665', const Color(0xFFC2413A)),
      ('Q', '\u2666', const Color(0xFFC2413A)),
      ('K', '\u2663', const Color(0xFF111827)),
    ];

    return SizedBox(
      height: width * 1.38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var index = 0; index < cards.length; index++)
            Transform.translate(
              offset: Offset((index - 1.5) * width * 0.54, 0),
              child: Transform.rotate(
                angle: (index - 1.5) * 0.09,
                child: _buildMiniCard(
                  width: width,
                  value: cards[index].$1,
                  suit: cards[index].$2,
                  color: cards[index].$3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniCard({
    required double width,
    required String value,
    required String suit,
    required Color color,
  }) {
    return Container(
      width: width,
      height: width * 1.36,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE8D9B5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$value\n$suit',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: width * 0.28,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
      ),
    );
  }
}
