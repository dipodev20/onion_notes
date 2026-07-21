import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

class RoadsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final List<RoadEdge> _edges = [];
  bool _loaded = false;

  List<RoadEdge> get edges => List.unmodifiable(_edges);
  bool get loaded => _loaded;

  Future<void> load() async {
    final loaded = await _storage.loadRoads();
    _edges
      ..clear()
      ..addAll(loaded);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveRoads(_edges);

  void connect(String fromId, String toId, {String label = ''}) {
    if (fromId == toId) return;
    final exists = _edges.any((e) =>
        (e.fromNoteId == fromId && e.toNoteId == toId) ||
        (e.fromNoteId == toId && e.toNoteId == fromId));
    if (exists) return;
    _edges.add(RoadEdge(fromNoteId: fromId, toNoteId: toId, label: label));
    _persist();
    notifyListeners();
  }

  void disconnect(String edgeId) {
    _edges.removeWhere((e) => e.id == edgeId);
    _persist();
    notifyListeners();
  }

  void toggleCompleted(String edgeId) {
    final e = _edges.firstWhere((e) => e.id == edgeId);
    e.completed = !e.completed;
    _persist();
    notifyListeners();
  }

  void updateLabel(String edgeId, String label) {
    final e = _edges.firstWhere((e) => e.id == edgeId);
    e.label = label;
    _persist();
    notifyListeners();
  }

  void removeAllForNote(String noteId) {
    _edges.removeWhere((e) => e.fromNoteId == noteId || e.toNoteId == noteId);
    _persist();
    notifyListeners();
  }

  List<RoadEdge> edgesFor(String noteId) =>
      _edges.where((e) => e.fromNoteId == noteId || e.toNoteId == noteId).toList();

  /// Следующий незавершённый "квест" от заметки — используется, чтобы
  /// анимированно перейти к следующей задаче в цепочке.
  RoadEdge? nextQuest(String noteId) {
    final list = edgesFor(noteId).where((e) => !e.completed);
    return list.isEmpty ? null : list.first;
  }
}
