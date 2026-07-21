import 'dart:math';

/// Размер "открытого мира" — квадратного холста, за пределы которого
/// карточки заметок не должны выходить. Достаточно большой, чтобы
/// комфортно поместить много заметок, но не безграничный — чтобы они не
/// терялись где-то в пустоте.
const double kWorldSize = 2600;
const double kCardWidth = 130;
const double kCardHeight = 70;

/// Расставляет N новых карточек по кругу вокруг заданного центра — нужно,
/// когда ИИ присылает сразу несколько заметок и не может (и не должен)
/// пытаться угадывать пиксельные координаты сам.
class LayoutService {
  static List<(double, double)> circlePositions(
    int count, {
    double centerX = kWorldSize / 2,
    double centerY = kWorldSize / 2,
    double baseRadius = 260,
  }) {
    if (count <= 0) return [];
    if (count == 1) return [(centerX, centerY)];
    final radius = baseRadius + count * 26;
    final positions = <(double, double)>[];
    for (var i = 0; i < count; i++) {
      final angle = (2 * pi * i) / count;
      var x = centerX + radius * cos(angle) - kCardWidth / 2;
      var y = centerY + radius * sin(angle) - kCardHeight / 2;
      x = x.clamp(0, kWorldSize - kCardWidth);
      y = y.clamp(0, kWorldSize - kCardHeight);
      positions.add((x, y));
    }
    return positions;
  }
}
