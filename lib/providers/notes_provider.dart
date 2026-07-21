import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/layout_service.dart';
import '../services/storage_service.dart';

class NotesProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final List<Note> _notes = [];
  bool _loaded = false;

  // История для undo/redo, ключ — id заметки, значение — стек JSON-снимков.
  final Map<String, List<String>> _undoStacks = {};
  final Map<String, List<String>> _redoStacks = {};

  List<Note> get notes => List.unmodifiable(_notes);
  bool get loaded => _loaded;

  Future<void> load() async {
    final loaded = await _storage.loadNotes();
    _notes
      ..clear()
      ..addAll(loaded);
    final history = await _storage.loadHistory();
    _undoStacks
      ..clear()
      ..addAll(history.undo);
    _redoStacks
      ..clear()
      ..addAll(history.redo);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveNotes(_notes);
  Future<void> _persistHistory() => _storage.saveHistory(_undoStacks, _redoStacks);

  /// Каждая новая заметка ставится на холсте "Дорог" в новое место —
  /// раньше все новые заметки получали одни и те же координаты по
  /// умолчанию и полностью накладывались друг на друга, из-за чего
  /// экран "Дороги" выглядел пустым даже при нескольких заметках.
  /// "Золотой угол" — стандартный приём, чтобы точки расходились по
  /// спирали без наложений сколько бы их ни добавлялось.
  Note createNote() {
    final index = _notes.length;
    const goldenAngle = 2.399963;
    final angle = index * goldenAngle;
    final radius = 46.0 * math.sqrt(index + 1);
    final x = (kWorldSize / 2 + radius * math.cos(angle) - kCardWidth / 2)
        .clamp(0.0, kWorldSize - kCardWidth);
    final y = (kWorldSize / 2 + radius * math.sin(angle) - kCardHeight / 2)
        .clamp(0.0, kWorldSize - kCardHeight);
    final note = Note(x: x, y: y);
    _notes.insert(0, note);
    _persist();
    notifyListeners();
    return note;
  }

  void addExistingNote(Note note) {
    _notes.insert(0, note);
    _persist();
    notifyListeners();
  }

  Note? byId(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    _undoStacks.remove(id);
    _redoStacks.remove(id);
    _persist();
    _persistHistory();
    notifyListeners();
  }

  void updateNote(Note updated) {
    final idx = _notes.indexWhere((n) => n.id == updated.id);
    if (idx == -1) return;
    updated.updatedAt = DateTime.now();
    _notes[idx] = updated;
    _persist();
    notifyListeners();
  }

  /// Для случаев, когда сразу много заметок меняются в цикле (например,
  /// авто-расстановка на "Дорогах") — сохраняет и уведомляет один раз в
  /// конце, а не по разу на каждую заметку в процессе цикла.
  void saveAll() {
    _persist();
    notifyListeners();
  }

  /// Сохраняет снимок текущего состояния заметки в стек истории —
  /// используется стрелками назад/вперёд в редакторе. Кап ниже, чем можно
  /// было бы ожидать (15, а не 50), потому что каждый снимок — это ПОЛНЫЙ
  /// JSON заметки, включая вставленные фото как base64: без этого лимита
  /// история заметки с фотографиями быстро разрослась бы на диске.
  void pushHistory(Note note) {
    final snap = jsonEncode(note.toJson());
    final stack = _undoStacks.putIfAbsent(note.id, () => []);
    if (stack.isNotEmpty && stack.last == snap) return;
    stack.add(snap);
    if (stack.length > 15) stack.removeAt(0);
    _redoStacks[note.id]?.clear();
    _persistHistory();
  }

  Note? undo(Note current) {
    final stack = _undoStacks[current.id];
    if (stack == null || stack.length < 2) return null;
    final redo = _redoStacks.putIfAbsent(current.id, () => []);
    redo.add(stack.removeLast());
    final prevJson = stack.last;
    _persistHistory();
    return Note.fromJson(jsonDecode(prevJson));
  }

  Note? redo(Note current) {
    final redo = _redoStacks[current.id];
    if (redo == null || redo.isEmpty) return null;
    final json = redo.removeLast();
    final stack = _undoStacks.putIfAbsent(current.id, () => []);
    stack.add(json);
    _persistHistory();
    return Note.fromJson(jsonDecode(json));
  }

  bool canUndo(String noteId) => (_undoStacks[noteId]?.length ?? 0) > 1;
  bool canRedo(String noteId) => (_redoStacks[noteId]?.isNotEmpty ?? false);

  List<Note> search(String query, {DateTime? onDate}) {
    Iterable<Note> result = _notes;
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.blocks.any((b) => b.plainText.toLowerCase().contains(q)));
    }
    if (onDate != null) {
      result = result.where((n) =>
          n.createdAt.year == onDate.year &&
          n.createdAt.month == onDate.month &&
          n.createdAt.day == onDate.day);
    }
    return result.toList();
  }
}
