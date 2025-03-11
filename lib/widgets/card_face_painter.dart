import 'package:flutter/material.dart';

class CardFacePainter extends CustomPainter {
  final String type; // 'J', 'Q', 或 'K'
  final String suit;
  final Color color;

  CardFacePainter({
    required this.type,
    required this.suit,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制基本轮廓
    if (type == 'J') {
      _drawJack(canvas, size, paint);
    } else if (type == 'Q') {
      _drawQueen(canvas, size, paint);
    } else if (type == 'K') {
      _drawKing(canvas, size, paint);
    }

    // 在适当位置绘制花色
    final textPainter = TextPainter(
      text: TextSpan(
        text: suit,
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        size.height * 0.8,
      ),
    );
  }

  void _drawJack(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    // 简化的人物轮廓
    path.moveTo(size.width * 0.4, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.4, size.height * 0.4);
    path.close();
    
    // 添加帽子
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.lineTo(size.width * 0.7, size.height * 0.2);
    path.lineTo(size.width * 0.5, size.height * 0.1);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawQueen(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    // 皇冠
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.lineTo(size.width * 0.4, size.height * 0.1);
    path.lineTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.6, size.height * 0.1);
    path.lineTo(size.width * 0.7, size.height * 0.2);
    
    // 脸部轮廓
    path.moveTo(size.width * 0.4, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.4,
      size.width * 0.6, size.height * 0.3,
    );
    
    canvas.drawPath(path, paint);
  }

  void _drawKing(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    // 王冠
    path.moveTo(size.width * 0.3, size.height * 0.2);
    path.lineTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.7, size.height * 0.2);
    
    // 胡须
    path.moveTo(size.width * 0.4, size.height * 0.3);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.3);
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CardFacePainter oldDelegate) {
    return oldDelegate.type != type || 
           oldDelegate.suit != suit || 
           oldDelegate.color != color;
  }
} 