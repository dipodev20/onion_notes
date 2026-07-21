import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/rich_text_sync.dart';

/// TextEditingController, который рисует каждый run своим стилем
/// (жирный / наклонённый курсив / фломастер / заливка / цвет текста)
/// прямо во время набора текста — это и есть "инструменты" редактора в деле.
class RichRunController extends TextEditingController {
  List<TextRun> runs;

  /// Базовый цвет текста (зависит от фона заметки — на тёмных фонах
  /// должен быть светлым). Мутируется извне при смене фона, а не создаётся
  /// заново, чтобы не терять контроллер и фокус поля.
  Color baseColor;

  /// Последнее НЕ потерянное выделение. TextField может сбрасывать
  /// `selection` в невалидное состояние, когда поле теряет фокус (например,
  /// когда открывается палитра цвета для "Заливки") — из-за этого кнопки
  /// тулбара переставали понимать, к какому диапазону текста применять
  /// стиль. Здесь мы всегда храним последний осмысленный диапазон.
  TextSelection lastSelection = const TextSelection.collapsed(offset: 0);

  RichRunController({required this.runs, this.baseColor = const Color(0xFF1C1B22)})
      : super(text: RichTextSync.plainText(runs));

  @override
  set value(TextEditingValue newValue) {
    if (newValue.selection.start >= 0 && newValue.selection.end >= 0) {
      lastSelection = newValue.selection;
    }
    super.value = newValue;
  }

  void setRuns(List<TextRun> newRuns) {
    runs = newRuns;
    final newText = RichTextSync.plainText(runs);
    final safeOffset = newText.length;
    value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: safeOffset),
    );
  }

  /// Обновляет базовый цвет (при смене фона заметки) и просит поле
  /// перерисоваться, не трогая текст/выделение/фокус.
  void updateBaseColor(Color color) {
    if (baseColor == color) return;
    baseColor = color;
    notifyListeners();
  }

  static Color _parseHex(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse(clean, radix: 16) + 0xFF000000);
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final spans = <TextSpan>[];
    for (final r in runs) {
      if (r.text.isEmpty) continue;
      spans.add(TextSpan(
        text: r.text,
        style: (style ?? const TextStyle()).copyWith(
          fontWeight: r.bold ? FontWeight.w700 : FontWeight.w400,
          fontStyle: r.italic ? FontStyle.italic : FontStyle.normal,
          color: r.textColor != null ? _parseHex(r.textColor!) : baseColor,
          backgroundColor: r.fillColor != null
              ? _parseHex(r.fillColor!)
              : (r.highlight ? const Color(0x66FFE066) : null),
          decoration: r.highlight ? TextDecoration.underline : TextDecoration.none,
          decorationColor: const Color(0xFFE6B800),
          decorationThickness: 2,
        ),
      ));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: '', style: (style ?? const TextStyle()).copyWith(color: baseColor)));
    }
    return TextSpan(children: spans, style: style);
  }
}
