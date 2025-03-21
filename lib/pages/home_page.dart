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
    // 获取平台信息
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final mediaQuery = MediaQuery.of(context);
    final scaleFactor = isIOS
        ? mediaQuery.size.width / 1024 // 假设网页版基准宽度为1024px
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('24点游戏'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '请选择目标数字',
              style: TextStyle(fontSize: isIOS ? 24 * scaleFactor : 24),
            ),
            SizedBox(height: isIOS ? 20 * scaleFactor : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_left),
                  iconSize: isIOS ? 24 * scaleFactor : 24,
                  onPressed: () {
                    setState(() {
                      if (targetNumber > 1) targetNumber--;
                    });
                  },
                ),
                Container(
                  width: isIOS ? 100 * scaleFactor : 100,
                  alignment: Alignment.center,
                  child: Text(
                    targetNumber.toString(),
                    style: TextStyle(fontSize: isIOS ? 32 * scaleFactor : 32),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right),
                  iconSize: isIOS ? 24 * scaleFactor : 24,
                  onPressed: () {
                    setState(() {
                      targetNumber++;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: isIOS ? 20 * scaleFactor : 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isIOS ? 16 * scaleFactor : 16,
                  vertical: isIOS ? 8 * scaleFactor : 8,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => GameBoard(targetNumber: targetNumber),
                  ),
                );
              },
              child: Text(
                '开始游戏',
                style: TextStyle(fontSize: isIOS ? 16 * scaleFactor : 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
