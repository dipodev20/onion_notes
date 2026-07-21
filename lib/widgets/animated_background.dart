import 'dart:math';
import 'package:flutter/material.dart';

/// Реестр доступных анимированных фонов заметки.
class BackgroundStyles {
  static const List<String> ids = [
    'plainWhite',
    'lavenderDrift',
    'sunsetGlow',
    'mintBreeze',
    'nightIndigo',
    'sakura',
    'wavesJapan',
    'paperWashi',
    'rainy',
    'snowy',
    'starryNight',
    'foggy',
    'matrixHacker',
  ];

  /// Тёмные фоны — на них включается белый текст по умолчанию.
  static const Set<String> _dark = {'nightIndigo', 'starryNight', 'matrixHacker'};

  static bool isDark(String id) => _dark.contains(id);

  static String label(String id) {
    switch (id) {
      case 'lavenderDrift':
        return 'Лавандовый поток';
      case 'sunsetGlow':
        return 'Закатное сияние';
      case 'mintBreeze':
        return 'Мятный бриз';
      case 'plainWhite':
        return 'Чистый белый';
      case 'nightIndigo':
        return 'Ночной индиго';
      case 'sakura':
        return 'Сакура';
      case 'wavesJapan':
        return 'Волна Канагавы';
      case 'paperWashi':
        return 'Бумага васи';
      case 'rainy':
        return 'Дождь';
      case 'snowy':
        return 'Снегопад';
      case 'starryNight':
        return 'Звёздная ночь';
      case 'foggy':
        return 'Туман';
      case 'matrixHacker':
        return 'Хакер';
      default:
        return id;
    }
  }
}

class AnimatedNoteBackground extends StatefulWidget {
  final String styleId;
  final Widget child;
  const AnimatedNoteBackground({super.key, required this.styleId, required this.child});

  @override
  State<AnimatedNoteBackground> createState() => _AnimatedNoteBackgroundState();
}

class _AnimatedNoteBackgroundState extends State<AnimatedNoteBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.styleId == 'plainWhite') {
      return Container(color: const Color(0xFFFBFAFF), child: widget.child);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _BackgroundPainter(widget.styleId, _controller.value),
          child: widget.child,
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final String styleId;
  final double t; // 0..1, зациклено

  _BackgroundPainter(this.styleId, this.t);

  List<Color> _colors() {
    switch (styleId) {
      case 'sunsetGlow':
        return const [Color(0xFFFFE3D1), Color(0xFFFFC1E0), Color(0xFFE7C9FF)];
      case 'mintBreeze':
        return const [Color(0xFFDFFBEE), Color(0xFFE3F6FF), Color(0xFFF1EBFF)];
      case 'nightIndigo':
        return const [Color(0xFF231A4A), Color(0xFF3A2B7A), Color(0xFF1B1338)];
      case 'sakura':
        return const [Color(0xFFFFF0F4), Color(0xFFFFD9E6), Color(0xFFFFF7FA)];
      case 'wavesJapan':
        return const [Color(0xFFE3F1FF), Color(0xFFC7E4FF), Color(0xFFF3FAFF)];
      case 'paperWashi':
        return const [Color(0xFFFBF6EA), Color(0xFFF3EAD3), Color(0xFFFDFAF2)];
      case 'rainy':
        return const [Color(0xFFD9E2EC), Color(0xFFB9C6D6), Color(0xFFE9EEF4)];
      case 'snowy':
        return const [Color(0xFFEAF3FB), Color(0xFFDCEBFA), Color(0xFFF7FBFF)];
      case 'starryNight':
        return const [Color(0xFF0B1030), Color(0xFF181A45), Color(0xFF060814)];
      case 'foggy':
        return const [Color(0xFFE7E7EA), Color(0xFFD6D8DE), Color(0xFFF0F1F3)];
      case 'matrixHacker':
        return const [Color(0xFF020703), Color(0xFF041006), Color(0xFF010401)];
      case 'lavenderDrift':
      default:
        return const [Color(0xFFF3EEFF), Color(0xFFEAE1FF), Color(0xFFFDF7FF)];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = _colors();
    final angle = 2 * pi * t;
    final begin = Alignment(cos(angle), sin(angle));
    final end = Alignment(-cos(angle), -sin(angle));
    final gradientPaint = Paint()
      ..shader = LinearGradient(colors: colors, begin: begin, end: end).createShader(rect);
    canvas.drawRect(rect, gradientPaint);

    switch (styleId) {
      case 'sakura':
        _paintSakura(canvas, size);
        break;
      case 'wavesJapan':
        _paintWaves(canvas, size);
        break;
      case 'paperWashi':
        _paintPaperGrid(canvas, size);
        break;
      case 'rainy':
        _paintRain(canvas, size);
        break;
      case 'snowy':
        _paintSnow(canvas, size);
        break;
      case 'starryNight':
        _paintStars(canvas, size);
        break;
      case 'foggy':
        _paintFog(canvas, size);
        break;
      case 'matrixHacker':
        _paintMatrix(canvas, size);
        break;
      default:
        _paintBubbles(canvas, size);
    }
  }

  void _paintBubbles(Canvas canvas, Size size) {
    final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (int i = 0; i < 4; i++) {
      final phase = t * 2 * pi + i * pi / 2;
      final dx = size.width * (0.2 + 0.6 * (0.5 + 0.5 * sin(phase + i)));
      final dy = size.height * (0.15 + 0.7 * (0.5 + 0.5 * cos(phase * 0.7 + i)));
      canvas.drawCircle(Offset(dx, dy), size.width * 0.18, bubblePaint);
    }
  }

  void _paintSakura(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF9EC0).withValues(alpha: 0.55);
    for (int i = 0; i < 16; i++) {
      final speed = 0.5 + (i % 5) * 0.12;
      final fall = ((t * speed + i / 16) % 1.0);
      final dx = size.width * (0.05 + 0.9 * ((i * 37) % 100) / 100) +
          14 * sin(t * 2 * pi * 2 + i);
      final dy = fall * (size.height + 40) - 20;
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(t * 2 * pi * 3 + i);
      final path = Path()
        ..moveTo(0, -6)
        ..quadraticBezierTo(6, -6, 6, 0)
        ..quadraticBezierTo(6, 6, 0, 6)
        ..quadraticBezierTo(-6, 6, -6, 0)
        ..quadraticBezierTo(-6, -6, 0, -6);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _paintWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFF3E7CB8).withValues(alpha: 0.28);
    for (int line = 0; line < 4; line++) {
      final path = Path();
      final baseY = size.height * (0.25 + line * 0.2);
      path.moveTo(-20, baseY);
      for (double x = -20; x <= size.width + 20; x += 12) {
        final y = baseY +
            18 * sin((x / size.width) * 4 * pi + t * 2 * pi + line * 1.4);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _paintPaperGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFB79B62).withValues(alpha: 0.10);
    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF5A7691).withValues(alpha: 0.45);
    for (int i = 0; i < 34; i++) {
      final speed = 0.6 + (i % 6) * 0.1;
      final fall = ((t * speed + i / 34) % 1.0);
      final dx = size.width * ((i * 53) % 100) / 100;
      final dy = fall * (size.height + 60) - 30;
      canvas.drawLine(Offset(dx, dy), Offset(dx - 4, dy + 16), paint);
    }
  }

  void _paintSnow(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (int i = 0; i < 26; i++) {
      final speed = 0.35 + (i % 5) * 0.09;
      final fall = ((t * speed + i / 26) % 1.0);
      final dx = size.width * ((i * 41) % 100) / 100 + 10 * sin(t * 2 * pi + i);
      final dy = fall * (size.height + 40) - 20;
      canvas.drawCircle(Offset(dx, dy), 2.2 + (i % 3), paint);
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final rand = Random(21);
    for (int i = 0; i < 46; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * size.height;
      final twinkle = (sin(t * 2 * pi * 2 + i) + 1) / 2;
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.15 + twinkle * 0.55);
      canvas.drawCircle(Offset(x, y), 1.0 + twinkle * 1.5, paint);
    }
  }

  void _paintFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    for (int i = 0; i < 3; i++) {
      final phase = t * 2 * pi + i * 2;
      final dx = size.width * (0.5 + 0.4 * sin(phase * 0.6));
      final dy = size.height * (0.3 + 0.3 * i + 0.1 * cos(phase));
      canvas.drawCircle(Offset(dx, dy), size.shortestSide * 0.5, paint);
    }
  }

  void _paintMatrix(Canvas canvas, Size size) {
    const cols = 14;
    final colWidth = size.width / cols;
    for (int c = 0; c < cols; c++) {
      final speed = 0.4 + (c % 5) * 0.15;
      final fall = ((t * speed + c / cols) % 1.0);
      final headY = fall * (size.height + 120) - 60;
      for (int seg = 0; seg < 5; seg++) {
        final y = headY - seg * 16;
        if (y < -16 || y > size.height + 16) continue;
        final opacity = (1 - seg / 5).clamp(0.0, 1.0) * 0.6;
        final paint = Paint()..color = const Color(0xFF3CFF7A).withValues(alpha: opacity);
        canvas.drawRect(Rect.fromLTWH(c * colWidth + colWidth * 0.35, y, 3, 10), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.styleId != styleId;
}
