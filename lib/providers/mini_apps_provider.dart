import 'package:flutter/foundation.dart';
import '../models/mini_app.dart';
import '../services/storage_service.dart';

class MiniAppsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final List<MiniApp> _apps = [];
  bool _loaded = false;

  List<MiniApp> get apps => List.unmodifiable(_apps);
  bool get loaded => _loaded;

  Future<void> load() async {
    final loaded = await _storage.loadMiniApps();
    _apps
      ..clear()
      ..addAll(loaded);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _storage.saveMiniApps(_apps);

  Future<void> add(MiniApp app) async {
    _apps.add(app);
    await _persist();
    notifyListeners();
  }

  Future<void> rename(String id, String title) async {
    final app = _apps.firstWhere((a) => a.id == id);
    app.title = title;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(MiniApp app) async {
    _apps.removeWhere((a) => a.id == app.id);
    await _storage.deleteMiniAppHtml(app.htmlPath);
    await _persist();
    notifyListeners();
  }
}
