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
    return Scaffold(
      appBar: AppBar(
        title: const Text('24点游戏'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '请选择目标数字',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  onPressed: () {
                    setState(() {
                      if (targetNumber > 1) targetNumber--;
                    });
                  },
                ),
                Container(
                  width: 100,
                  alignment: Alignment.center,
                  child: Text(
                    targetNumber.toString(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  onPressed: () {
                    setState(() {
                      targetNumber++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GameBoard(targetNumber: targetNumber),
                  ),
                );
              },
              child: const Text('开始游戏'),
            ),
          ],
        ),
      ),
    );
  }
} 