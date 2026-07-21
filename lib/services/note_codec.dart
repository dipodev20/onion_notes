import '../models/note.dart';

/// Кодирует/декодирует заметку (или сразу несколько) в компактный текстовый
/// формат "ONION-CODE".
///
/// Идея: пользователь может выделить и скопировать этот текст, отправить
/// на другой телефон (мессенджер, заметки, куда угодно), вставить в ONION
/// через "Вставить из кода" — и все чекбоксы, курсив, маркер, заливка и
/// картинки восстановятся один в один, потому что всё закодировано прямо
/// в самом тексте, а не хранится где-то на сервере.
///
/// Формат построчный, с простыми маркерами разметки внутри строки:
///   **жирный**       -> bold
///   __курсив__        -> italic (наклон)
///   ~~маркер~~        -> highlight (фломастер)
///   ((#RRGGBB|текст)) -> заливка фона текста
///   [[#RRGGBB|текст]] -> цвет самого текста
///
/// Эти простые маркеры НЕЛЬЗЯ вкладывать друг в друга (например
/// ~~((#hex|текст))~~ не сработает — лишние ~~ останутся видимым
/// текстом). Если нужно несколько стилей сразу на одном фрагменте —
/// единый маркер:
///   {{флаги|текст}}, флаги через ";": b (жирный), i (курсив),
///   h (маркер), f:#RRGGBB (заливка), c:#RRGGBB (цвет текста).
///   Пример: {{b;h|Важно}} — жирный + маркер одновременно.
///
/// Пачка из нескольких заметок ("бандл") — например, когда ИИ пишет сразу
/// несколько связанных заметок, или при полном бэкапе — оборачивается в
/// #ONION-BUNDLE-V1 ... несколько блоков #ONION-NOTE-V1 подряд ... и
/// необязательную секцию ROADS: со связями между ними по названиям.
class NoteCodec {
  static const _noteHeader = '#ONION-NOTE-V1';
  static const _bundleHeader = '#ONION-BUNDLE-V1';
  static const _roadsHeader = 'ROADS:';

  // ---------------- Одна заметка ----------------

  static String encode(Note note) => _encodeNoteBlock(note).trimRight();

  static String _encodeNoteBlock(Note note) {
    final b = StringBuffer();
    b.writeln(_noteHeader);
    b.writeln('TITLE: ${_escapeLine(note.title)}');
    b.writeln('BG: ${note.backgroundId}');
    b.writeln('FONT: ${note.fontFamily}');
    b.writeln('CREATED: ${note.createdAt.toIso8601String()}');
    b.writeln('---');
    for (final block in note.blocks) {
      switch (block.type) {
        case BlockType.text:
          b.writeln('[TEXT] ${_encodeRuns(block.runs)}');
          break;
        case BlockType.checkbox:
          final mark = block.done ? 'x' : ' ';
          b.writeln('[CHECK|$mark] ${_encodeRuns(block.runs)}');
          break;
        case BlockType.image:
          b.writeln(
              '[IMG|${block.imageWidth}|${block.imageAlign}|${block.imageAspect}] ${block.imageBase64 ?? ''}');
          break;
        case BlockType.divider:
          b.writeln('[DIVIDER]');
          break;
      }
    }
    return b.toString();
  }

  /// Возвращает null, если строка не похожа на одиночный ONION-код
  /// (для пачки нескольких заметок используйте [decodeBundle]).
  static Note? decode(String raw) {
    final text = raw.trim();
    if (!text.startsWith(_noteHeader)) return null;
    final lines = text.split('\n');
    final result = _parseNoteFrom(lines, 1);
    return result.note;
  }

  // ---------------- Пачка заметок + связи ----------------

  /// Собирает несколько заметок и связи между ними (по названиям) в один
  /// код. Используется как для полного бэкапа всех заметок, так и как
  /// формат, который умеет генерировать внешний ИИ.
  static String encodeBundle(List<Note> notes, {List<(String, String, String)> roads = const []}) {
    final b = StringBuffer();
    b.writeln(_bundleHeader);
    for (final note in notes) {
      b.write(_encodeNoteBlock(note));
    }
    if (roads.isNotEmpty) {
      b.writeln(_roadsHeader);
      for (final r in roads) {
        final label = r.$3.isEmpty ? '' : ' | ${_escapeLine(r.$3)}';
        b.writeln('${_escapeLine(r.$1)} -> ${_escapeLine(r.$2)}$label');
      }
    }
    return b.toString().trimRight();
  }

  static bool looksLikeBundle(String raw) => raw.trim().startsWith(_bundleHeader);

  /// Разбирает пачку заметок. Возвращает список заметок и список связей
  /// как тройки (название А, название Б, подпись) — подключать их по id
  /// должен вызывающий код, после того как заметки уже добавлены в
  /// хранилище и получили свои настоящие id.
  static ({List<Note> notes, List<(String, String, String)> roads}) decodeBundle(String raw) {
    final text = raw.trim();
    final notes = <Note>[];
    final roads = <(String, String, String)>[];
    if (!text.startsWith(_bundleHeader)) return (notes: notes, roads: roads);

    final lines = text.split('\n');
    int i = 1;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line == _roadsHeader) {
        i++;
        break;
      }
      if (line != _noteHeader) {
        i++;
        continue;
      }
      final result = _parseNoteFrom(lines, i + 1);
      notes.add(result.note);
      i = result.nextIndex;
    }
    for (; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final arrow = line.indexOf('->');
      if (arrow == -1) continue;
      final left = line.substring(0, arrow).trim();
      var right = line.substring(arrow + 2).trim();
      var label = '';
      final pipe = right.indexOf('|');
      if (pipe != -1) {
        label = right.substring(pipe + 1).trim();
        right = right.substring(0, pipe).trim();
      }
      roads.add((left, right, label));
    }
    return (notes: notes, roads: roads);
  }

  /// Разбирает заголовок+блоки одной заметки начиная с [start] (сразу
  /// после строки "#ONION-NOTE-V1"), останавливаясь на следующем
  /// "#ONION-NOTE-V1", "ROADS:" или конце текста — так один и тот же
  /// парсер работает и для одиночного кода, и для заметки внутри пачки.
  static ({Note note, int nextIndex}) _parseNoteFrom(List<String> lines, int start) {
    String title = '';
    String bg = 'lavenderDrift';
    String font = '';
    DateTime created = DateTime.now();
    int i = start;
    for (; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim() == '---') {
        i++;
        break;
      }
      if (line.startsWith('TITLE: ')) title = line.substring(7);
      if (line.startsWith('BG: ')) bg = line.substring(4).trim();
      if (line.startsWith('FONT: ')) font = line.substring(6).trim();
      if (line.startsWith('CREATED: ')) {
        created = DateTime.tryParse(line.substring(9).trim()) ?? DateTime.now();
      }
    }

    final blocks = <NoteBlock>[];
    for (; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed == _noteHeader || trimmed == _roadsHeader) break;
      if (line.startsWith('[TEXT] ')) {
        blocks.add(NoteBlock(type: BlockType.text, runs: _decodeRuns(line.substring(7))));
      } else if (line.startsWith('[CHECK|')) {
        final close = line.indexOf(']');
        final mark = line.substring(7, close);
        final content = line.length > close + 2 ? line.substring(close + 2) : '';
        blocks.add(NoteBlock(
          type: BlockType.checkbox,
          done: mark.trim() == 'x',
          runs: _decodeRuns(content),
        ));
      } else if (line.startsWith('[IMG|')) {
        final close = line.indexOf(']');
        final header = line.substring(5, close).split('|');
        final width = double.tryParse(header[0]) ?? 1.0;
        final align = header.length > 1 ? header[1] : 'center';
        final aspect = header.length > 2 ? (double.tryParse(header[2]) ?? 1.0) : 1.0;
        final content = line.length > close + 2 ? line.substring(close + 2) : '';
        blocks.add(NoteBlock(
          type: BlockType.image,
          imageBase64: content,
          imageWidth: width,
          imageAlign: align,
          imageAspect: aspect,
        ));
      } else if (line.startsWith('[DIVIDER]')) {
        blocks.add(NoteBlock(type: BlockType.divider));
      }
    }
    if (blocks.isEmpty) blocks.add(NoteBlock(type: BlockType.text));

    final note = Note(
      title: title,
      backgroundId: bg,
      fontFamily: font,
      createdAt: created,
      blocks: blocks,
    );
    return (note: note, nextIndex: i);
  }

  // ---------------- Разметка внутри текста ----------------

  static String _encodeRuns(List<TextRun> runs) {
    final b = StringBuffer();
    for (final r in runs) {
      final t = r.text.replaceAll('\n', '\\n');
      final flags = <String>[];
      if (r.bold) flags.add('b');
      if (r.italic) flags.add('i');
      if (r.highlight) flags.add('h');
      if (r.fillColor != null) flags.add('f:${r.fillColor}');
      if (r.textColor != null) flags.add('c:${r.textColor}');

      if (flags.length > 1) {
        // Больше одного стиля сразу — единый маркер, простые ** __ ~~
        // (( )) [[ ]] нельзя вкладывать друг в друга.
        b.write('{{${flags.join(';')}|$t}}');
      } else if (flags.isEmpty) {
        b.write(t);
      } else {
        final f = flags.first;
        if (f == 'b') {
          b.write('**$t**');
        } else if (f == 'i') {
          b.write('__${t}__');
        } else if (f == 'h') {
          b.write('~~$t~~');
        } else if (f.startsWith('f:')) {
          b.write('((${f.substring(2)}|$t))');
        } else {
          b.write('[[${f.substring(2)}|$t]]');
        }
      }
    }
    return b.toString();
  }

  static List<TextRun> _decodeRuns(String s) {
    final runs = <TextRun>[];
    // Один проход, три варианта маркера — раньше {{}} не было, а (( ))
    // и [[ ]] разбирались отдельным проходом ДО простых **/__/~~, из-за
    // чего вложенные комбинации (например ~~((#hex|текст))~~) ломались:
    // внешние ~~ оставались отдельно и не находили пару.
    final pattern = RegExp(
      r'\{\{([^|{}]*)\|(.*?)\}\}'
      r'|\(\((#[0-9A-Fa-f]{6})\|(.*?)\)\)'
      r'|\[\[(#[0-9A-Fa-f]{6})\|(.*?)\]\]',
    );
    int pos = 0;
    for (final m in pattern.allMatches(s)) {
      if (m.start > pos) {
        runs.addAll(_decodeInline(s.substring(pos, m.start)));
      }
      if (m.group(1) != null) {
        // {{флаги|текст}}
        var bold = false, italic = false, highlight = false;
        String? fill, color;
        for (final flag in m.group(1)!.split(';')) {
          final f = flag.trim();
          if (f == 'b') {
            bold = true;
          } else if (f == 'i') {
            italic = true;
          } else if (f == 'h') {
            highlight = true;
          } else if (f.startsWith('f:')) {
            fill = f.substring(2);
          } else if (f.startsWith('c:')) {
            color = f.substring(2);
          }
        }
        runs.add(TextRun(
          text: m.group(2)!.replaceAll('\\n', '\n'),
          bold: bold,
          italic: italic,
          highlight: highlight,
          fillColor: fill,
          textColor: color,
        ));
      } else {
        final isFill = m.group(3) != null;
        final hex = isFill ? m.group(3)! : m.group(5)!;
        final content = isFill ? m.group(4)! : m.group(6)!;
        runs.add(TextRun(
          text: content.replaceAll('\\n', '\n'),
          fillColor: isFill ? hex : null,
          textColor: isFill ? null : hex,
        ));
      }
      pos = m.end;
    }
    if (pos < s.length) {
      runs.addAll(_decodeInline(s.substring(pos)));
    }
    if (runs.isEmpty) runs.add(TextRun(text: ''));
    return runs;
  }

  static List<TextRun> _decodeInline(String s) {
    final runs = <TextRun>[];
    final pattern = RegExp(r'(\*\*.*?\*\*|__.*?__|~~.*?~~)');
    int pos = 0;
    for (final m in pattern.allMatches(s)) {
      if (m.start > pos) {
        runs.add(TextRun(text: _unescape(s.substring(pos, m.start))));
      }
      final token = m.group(0)!;
      if (token.startsWith('**')) {
        runs.add(TextRun(text: _unescape(token.substring(2, token.length - 2)), bold: true));
      } else if (token.startsWith('__')) {
        runs.add(TextRun(text: _unescape(token.substring(2, token.length - 2)), italic: true));
      } else if (token.startsWith('~~')) {
        runs.add(TextRun(text: _unescape(token.substring(2, token.length - 2)), highlight: true));
      }
      pos = m.end;
    }
    if (pos < s.length) {
      runs.add(TextRun(text: _unescape(s.substring(pos))));
    }
    return runs;
  }

  static String _unescape(String s) => s.replaceAll('\\n', '\n');
  static String _escapeLine(String s) => s.replaceAll('\n', ' ');
}
