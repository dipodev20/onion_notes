import '../models/note.dart';

/// Утилиты для работы с List<TextRun> как с единым редактируемым текстом,
/// сохраняя разметку (жирный/курсив/маркер/заливка) на месте при правках
/// и позволяя применять стиль к произвольному диапазону выделения.
class RichTextSync {
  static String plainText(List<TextRun> runs) => runs.map((r) => r.text).join();

  /// Разбивает список runs на (before, after) ровно по индексу [index]
  /// в объединённом тексте, не теряя стилей.
  static (List<TextRun>, List<TextRun>) splitAt(List<TextRun> runs, int index) {
    final before = <TextRun>[];
    final after = <TextRun>[];
    int pos = 0;
    for (final r in runs) {
      final len = r.text.length;
      if (pos + len <= index) {
        before.add(r.copy());
      } else if (pos >= index) {
        after.add(r.copy());
      } else {
        final cut = index - pos;
        final left = r.copy()..text = r.text.substring(0, cut);
        final right = r.copy()..text = r.text.substring(cut);
        if (left.text.isNotEmpty) before.add(left);
        if (right.text.isNotEmpty) after.add(right);
      }
      pos += len;
    }
    return (before, after);
  }

  /// Применяет правку: заменяет весь текущий текст на [newText],
  /// пытаясь сохранить стили неизменившихся частей, а новый (вставленный)
  /// кусок наследует стиль соседнего символа.
  static List<TextRun> applyEdit(List<TextRun> runs, String newText) {
    final oldText = plainText(runs);
    if (oldText == newText) return runs;

    int prefix = 0;
    final maxPrefix = oldText.length < newText.length ? oldText.length : newText.length;
    while (prefix < maxPrefix && oldText[prefix] == newText[prefix]) {
      prefix++;
    }
    int oldEnd = oldText.length;
    int newEnd = newText.length;
    while (oldEnd > prefix && newEnd > prefix && oldText[oldEnd - 1] == newText[newEnd - 1]) {
      oldEnd--;
      newEnd--;
    }

    final (before, _) = splitAt(runs, prefix);
    final (_, after) = splitAt(runs, oldEnd);
    final inserted = newText.substring(prefix, newEnd);

    final result = <TextRun>[...before];
    if (inserted.isNotEmpty) {
      final styleSource = before.isNotEmpty ? before.last : (after.isNotEmpty ? after.first : TextRun(text: ''));
      result.add(TextRun(
        text: inserted,
        bold: styleSource.bold,
        italic: styleSource.italic,
        highlight: styleSource.highlight,
        fillColor: styleSource.fillColor,
        textColor: styleSource.textColor,
      ));
    }
    result.addAll(after);
    return _merge(result);
  }

  /// Применяет функцию [transform] ко всем символам в диапазоне [start,end).
  static List<TextRun> applyStyle(
    List<TextRun> runs,
    int start,
    int end,
    TextRun Function(TextRun) transform,
  ) {
    if (start == end) return runs;
    final (before, rest) = splitAt(runs, start);
    final (middle, after) = splitAt(rest, end - start);
    final styledMiddle = middle.map(transform).toList();
    return _merge([...before, ...styledMiddle, ...after]);
  }

  static List<TextRun> _merge(List<TextRun> runs) {
    final result = <TextRun>[];
    for (final r in runs) {
      if (r.text.isEmpty) continue;
      if (result.isNotEmpty &&
          result.last.bold == r.bold &&
          result.last.italic == r.italic &&
          result.last.highlight == r.highlight &&
          result.last.fillColor == r.fillColor &&
          result.last.textColor == r.textColor) {
        result.last.text += r.text;
      } else {
        result.add(r.copy());
      }
    }
    if (result.isEmpty) result.add(TextRun(text: ''));
    return result;
  }
}
