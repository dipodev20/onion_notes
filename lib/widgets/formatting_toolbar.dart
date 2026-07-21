import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'onion_icons.dart';

/// Панель инструментов, которая появляется над клавиатурой в редакторе.
class FormattingToolbar extends StatelessWidget {
  final VoidCallback onCheckbox;
  final VoidCallback onItalic;
  final VoidCallback onHighlight;
  final VoidCallback onColorFill;
  final VoidCallback onTextColor;
  final VoidCallback onImage;
  final VoidCallback onBackground;
  final VoidCallback onBold;
  final VoidCallback onDivider;

  /// Есть ли сейчас непустое выделение текста — инструменты стиля
  /// (жирный/курсив/маркер/заливка/цвет текста) применяются только к нему,
  /// поэтому они неактивны, если выделять нечего.
  final bool canStyleSelection;

  const FormattingToolbar({
    super.key,
    required this.onCheckbox,
    required this.onItalic,
    required this.onHighlight,
    required this.onColorFill,
    required this.onTextColor,
    required this.onImage,
    required this.onBackground,
    required this.onBold,
    required this.onDivider,
    required this.canStyleSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _ToolButton(icon: OnionIcons.checkboxTool(), label: 'Чек', onTap: onCheckbox),
          _ToolButton(
            icon: const Text('Ж', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            label: 'Жирный',
            onTap: onBold,
            enabled: canStyleSelection,
          ),
          _ToolButton(
            icon: OnionIcons.fontTool(),
            label: 'Курсив',
            onTap: onItalic,
            enabled: canStyleSelection,
          ),
          _ToolButton(
            icon: OnionIcons.highlighterTool(),
            label: 'Маркер',
            onTap: onHighlight,
            enabled: canStyleSelection,
          ),
          _ToolButton(
            icon: OnionIcons.colorFillTool(),
            label: 'Заливка',
            onTap: onColorFill,
            enabled: canStyleSelection,
          ),
          _ToolButton(
            icon: OnionIcons.textColorTool(),
            label: 'Цвет текста',
            onTap: onTextColor,
            enabled: canStyleSelection,
          ),
          _ToolButton(icon: OnionIcons.imageTool(), label: 'Фото', onTap: onImage),
          _ToolButton(icon: OnionIcons.backgroundTool(), label: 'Фон', onTap: onBackground),
          _ToolButton(
            icon: const Icon(Icons.horizontal_rule_rounded, size: 20, color: AppColors.ink),
            label: 'Линия',
            onTap: onDivider,
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _ToolButton({required this.icon, required this.label, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.chip),
            onTap: enabled ? onTap : null,
            child: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purpleSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadii.chip),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(height: 2),
                  Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Всплывающая палитра цветов для заливки выделенного текста.
Future<Color?> showColorFillPicker(BuildContext context) {
  const colors = [
    Color(0xFFFFE066),
    Color(0xFFFFB3C1),
    Color(0xFFB3E5FC),
    Color(0xFFC8F7C5),
    Color(0xFFE0C3FC),
    Color(0xFFFFD8A8),
  ];
  return showModalBottomSheet<Color>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: colors
            .map((c) => GestureDetector(
                  onTap: () => Navigator.pop(ctx, c),
                  child: CircleAvatar(radius: 26, backgroundColor: c),
                ))
            .toList(),
      ),
    ),
  );
}

/// Палитра для цвета САМОГО текста (не фона). Возвращает hex-строку вида
/// "#RRGGBB", либо строку "auto" (сбросить на автоцвет по фону заметки).
Future<String?> showTextColorPicker(BuildContext context) {
  const colors = <String, Color>{
    '#1C1B22': Color(0xFF1C1B22), // чёрный/чернильный
    '#FFFFFF': Colors.white,
    '#7C5CFF': AppColors.purple,
    '#E0526B': Color(0xFFE0526B),
    '#2E9E5B': Color(0xFF2E9E5B),
    '#2E7FD6': Color(0xFF2E7FD6),
    '#E08A2E': Color(0xFFE08A2E),
  };
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Цвет текста', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ...colors.entries.map((e) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, e.key),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: e.value,
                      child: e.key == '#FFFFFF'
                          ? const CircleAvatar(
                              radius: 21,
                              backgroundColor: Colors.transparent,
                              child: Icon(Icons.circle_outlined, color: AppColors.divider, size: 20),
                            )
                          : null,
                    ),
                  )),
              GestureDetector(
                onTap: () => Navigator.pop(ctx, 'auto'),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.purpleSoft,
                  child: Icon(Icons.refresh_rounded, color: AppColors.purple, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
