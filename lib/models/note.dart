import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Тип блока внутри заметки.
enum BlockType { text, checkbox, image, divider }

/// Стиль форматирования куска текста внутри текстового блока.
class TextRun {
  String text;
  bool bold;
  bool italic; // "наклон вправо"
  bool highlight; // фломастер
  String? fillColor; // заливка выделенной зоны, hex "#RRGGBB" или null
  String? textColor; // цвет самого текста, hex "#RRGGBB" или null = авто

  TextRun({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.highlight = false,
    this.fillColor,
    this.textColor,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'bold': bold,
        'italic': italic,
        'highlight': highlight,
        'fillColor': fillColor,
        'textColor': textColor,
      };

  factory TextRun.fromJson(Map<String, dynamic> json) => TextRun(
        text: json['text'] ?? '',
        bold: json['bold'] ?? false,
        italic: json['italic'] ?? false,
        highlight: json['highlight'] ?? false,
        fillColor: json['fillColor'],
        textColor: json['textColor'],
      );

  TextRun copy() => TextRun(
        text: text,
        bold: bold,
        italic: italic,
        highlight: highlight,
        fillColor: fillColor,
        textColor: textColor,
      );
}

/// Один блок содержимого заметки (абзац, чекбокс, картинка, разделитель).
class NoteBlock {
  String id;
  BlockType type;
  List<TextRun> runs; // используется для text/checkbox
  bool done; // используется для checkbox
  String? imageBase64; // используется для image
  double imageWidth; // используется для image: 0.35/0.55/1.0 = доля ширины экрана
  String imageAlign; // 'left' | 'center' | 'right' — используется для image
  double imageAspect; // ширина/высота оригинала — чтобы не кадрировать фото

  NoteBlock({
    String? id,
    required this.type,
    List<TextRun>? runs,
    this.done = false,
    this.imageBase64,
    this.imageWidth = 1.0,
    this.imageAlign = 'center',
    this.imageAspect = 1.0,
  })  : id = id ?? _uuid.v4(),
        runs = runs ?? [];

  String get plainText => runs.map((r) => r.text).join();

  NoteBlock copy() => NoteBlock(
        id: id,
        type: type,
        runs: runs.map((r) => r.copy()).toList(),
        done: done,
        imageBase64: imageBase64,
        imageWidth: imageWidth,
        imageAlign: imageAlign,
        imageAspect: imageAspect,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'runs': runs.map((r) => r.toJson()).toList(),
        'done': done,
        'imageBase64': imageBase64,
        'imageWidth': imageWidth,
        'imageAlign': imageAlign,
        'imageAspect': imageAspect,
      };

  factory NoteBlock.fromJson(Map<String, dynamic> json) => NoteBlock(
        id: json['id'],
        type: BlockType.values.firstWhere((t) => t.name == json['type'],
            orElse: () => BlockType.text),
        runs: (json['runs'] as List? ?? [])
            .map((r) => TextRun.fromJson(r))
            .toList(),
        done: json['done'] ?? false,
        imageBase64: json['imageBase64'],
        imageWidth: (json['imageWidth'] ?? 1.0).toDouble(),
        imageAlign: json['imageAlign'] ?? 'center',
        imageAspect: (json['imageAspect'] ?? 1.0).toDouble(),
      );
}

/// Заметка целиком.
class Note {
  String id;
  String title;
  DateTime createdAt;
  DateTime updatedAt;
  List<NoteBlock> blocks;
  String backgroundId; // ключ анимированного фона
  String fontFamily;
  double x; // позиция карточки на экране "дорог"
  double y;

  Note({
    String? id,
    this.title = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<NoteBlock>? blocks,
    this.backgroundId = 'lavenderDrift',
    this.fontFamily = '',
    this.x = 80,
    this.y = 80,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        blocks = blocks ?? [NoteBlock(type: BlockType.text)];

  /// '' означает "системный шрифт" — TextStyle.fontFamily не принимает
  /// пустую строку, поэтому везде используем этот геттер вместо поля напрямую.
  String? get resolvedFontFamily => fontFamily.isEmpty ? null : fontFamily;

  static final _tagPattern = RegExp(r'#([\wа-яА-ЯёЁ]{2,})', unicode: true);

  /// Теги вида #тег, найденные прямо в заголовке и тексте заметки —
  /// отдельного поля не заводим, чтобы не плодить рассинхронизацию.
  List<String> get tags {
    final found = <String>{};
    for (final m in _tagPattern.allMatches(title)) {
      found.add(m.group(1)!.toLowerCase());
    }
    for (final b in blocks) {
      if (b.type == BlockType.text || b.type == BlockType.checkbox) {
        for (final m in _tagPattern.allMatches(b.plainText)) {
          found.add(m.group(1)!.toLowerCase());
        }
      }
    }
    return found.toList()..sort();
  }

  Note copy() => Note(
        id: id,
        title: title,
        createdAt: createdAt,
        updatedAt: updatedAt,
        blocks: blocks.map((b) => b.copy()).toList(),
        backgroundId: backgroundId,
        fontFamily: fontFamily,
        x: x,
        y: y,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'backgroundId': backgroundId,
        'fontFamily': fontFamily,
        'x': x,
        'y': y,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
        blocks: (json['blocks'] as List? ?? [])
            .map((b) => NoteBlock.fromJson(b))
            .toList(),
        backgroundId: json['backgroundId'] ?? 'lavenderDrift',
        fontFamily: json['fontFamily'] ?? '',
        x: (json['x'] ?? 80).toDouble(),
        y: (json['y'] ?? 80).toDouble(),
      );
}

/// Связь ("дорога") между двумя заметками на экране квестов.
class RoadEdge {
  String id;
  String fromNoteId;
  String toNoteId;
  String label;
  bool completed;

  RoadEdge({
    String? id,
    required this.fromNoteId,
    required this.toNoteId,
    this.label = '',
    this.completed = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromNoteId': fromNoteId,
        'toNoteId': toNoteId,
        'label': label,
        'completed': completed,
      };

  factory RoadEdge.fromJson(Map<String, dynamic> json) => RoadEdge(
        id: json['id'],
        fromNoteId: json['fromNoteId'],
        toNoteId: json['toNoteId'],
        label: json['label'] ?? '',
        completed: json['completed'] ?? false,
      );
}
