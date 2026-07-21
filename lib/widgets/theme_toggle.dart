import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onion_icons.dart';

/// Переключатель темы: овальный трек, внутри которого едет кружок с
/// иконкой — солнце для светлой темы, луна для тёмной. Сама иконка
/// анимированно морфится (поворот + прозрачность) при переключении.
class ThemeToggleSwitch extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const ThemeToggleSwitch({super.key, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        width: 64,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF2A2440) : const Color(0xFFFFE9C7),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween(begin: 0.6, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: isDark
                        ? KeyedSubtree(key: const ValueKey('moon'), child: OnionIcons.moon(size: 18))
                        : KeyedSubtree(key: const ValueKey('sun'), child: OnionIcons.sun(size: 18)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка настройки темы для экрана "Настройки".
class ThemeSettingRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  final AppPalette palette;

  const ThemeSettingRow({super.key, required this.isDark, required this.onToggle, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: palette.purpleSoft, borderRadius: BorderRadius.circular(14)),
            child: Center(child: isDark ? OnionIcons.moon(size: 20) : OnionIcons.sun(size: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Тема оформления',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: palette.ink)),
                const SizedBox(height: 3),
                Text(isDark ? 'Тёмная' : 'Светлая',
                    style: TextStyle(fontSize: 12, color: palette.inkSoft)),
              ],
            ),
          ),
          ThemeToggleSwitch(isDark: isDark, onTap: onToggle),
        ],
      ),
    );
  }
}
