import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/mini_app.dart';

/// Хранит все данные приложения локально в JSON-файлах внутри
/// песочницы приложения. Никакого интернета не требуется.
class StorageService {
  Future<Directory> _dir() async => getApplicationDocumentsDirectory();

  Future<File> _notesFile() async {
    final d = await _dir();
    return File('${d.path}/onion_notes.json');
  }

  Future<File> _roadsFile() async {
    final d = await _dir();
    return File('${d.path}/onion_roads.json');
  }

  Future<File> _settingsFile() async {
    final d = await _dir();
    return File('${d.path}/onion_settings.json');
  }

  Future<File> _miniAppsFile() async {
    final d = await _dir();
    return File('${d.path}/onion_miniapps.json');
  }

  Future<Directory> _miniAppsDir() async {
    final d = await _dir();
    final dir = Directory('${d.path}/miniapps');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<bool> loadDarkMode() async {
    final f = await _settingsFile();
    if (!await f.exists()) return false;
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return false;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['isDark'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveDarkMode(bool isDark) async {
    final f = await _settingsFile();
    await f.writeAsString(jsonEncode({'isDark': isDark}));
  }

  Future<List<Note>> loadNotes() async {
    final f = await _notesFile();
    if (!await f.exists()) return [];
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => Note.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<File> _historyFile() async {
    final d = await _dir();
    return File('${d.path}/onion_history.json');
  }

  Future<void> saveNotes(List<Note> notes) async {
    final f = await _notesFile();
    final raw = jsonEncode(notes.map((n) => n.toJson()).toList());
    await f.writeAsString(raw);
  }

  /// История undo/redo — снимки заметок в формате JSON-строк, как их и
  /// хранит NotesProvider в памяти. Каптится по количеству в самом
  /// провайдере, здесь только сохраняем/читаем как есть.
  Future<({Map<String, List<String>> undo, Map<String, List<String>> redo})> loadHistory() async {
    final f = await _historyFile();
    if (!await f.exists()) return (undo: <String, List<String>>{}, redo: <String, List<String>>{});
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return (undo: <String, List<String>>{}, redo: <String, List<String>>{});
      final map = jsonDecode(raw) as Map<String, dynamic>;
      Map<String, List<String>> parse(String key) {
        final section = map[key] as Map<String, dynamic>? ?? {};
        return section.map((k, v) => MapEntry(k, (v as List).cast<String>()));
      }
      return (undo: parse('undo'), redo: parse('redo'));
    } catch (_) {
      return (undo: <String, List<String>>{}, redo: <String, List<String>>{});
    }
  }

  Future<void> saveHistory(Map<String, List<String>> undo, Map<String, List<String>> redo) async {
    final f = await _historyFile();
    await f.writeAsString(jsonEncode({'undo': undo, 'redo': redo}));
  }

  Future<List<RoadEdge>> loadRoads() async {
    final f = await _roadsFile();
    if (!await f.exists()) return [];
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => RoadEdge.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRoads(List<RoadEdge> roads) async {
    final f = await _roadsFile();
    final raw = jsonEncode(roads.map((r) => r.toJson()).toList());
    await f.writeAsString(raw);
  }

  // ---------------- Мини-приложения ----------------

  Future<List<MiniApp>> loadMiniApps() async {
    final f = await _miniAppsFile();
    if (!await f.exists()) return [];
    try {
      final raw = await f.readAsString();
      if (raw.trim().isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list.map((e) => MiniApp.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMiniApps(List<MiniApp> apps) async {
    final f = await _miniAppsFile();
    final raw = jsonEncode(apps.map((a) => a.toJson()).toList());
    await f.writeAsString(raw);
  }

  /// Сохраняет HTML-байты на диск и возвращает относительный путь
  /// ("miniapps/<id>.html"), который кладётся в MiniApp.htmlPath.
  Future<String> storeMiniAppHtml(String id, Uint8List bytes) async {
    final dir = await _miniAppsDir();
    final file = File('${dir.path}/$id.html');
    await file.writeAsBytes(bytes, flush: true);
    return 'miniapps/$id.html';
  }

  Future<File> miniAppHtmlFile(String relativePath) async {
    final d = await _dir();
    return File('${d.path}/$relativePath');
  }

  Future<void> deleteMiniAppHtml(String relativePath) async {
    final f = await miniAppHtmlFile(relativePath);
    if (await f.exists()) await f.delete();
  }
}
