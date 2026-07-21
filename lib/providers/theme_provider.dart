import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Переключатель светлой/тёмной темы для "хрома" приложения (нижнее меню,
/// главный экран, дороги, настройки). Анимированный фон КОНКРЕТНОЙ заметки
/// в редакторе — отдельная история и от этой темы не зависит.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  bool _isDark = false;
  bool _loaded = false;

  bool get isDark => _isDark;
  bool get loaded => _loaded;

  Future<void> load() async {
    _isDark = await _storage.loadDarkMode();
    _loaded = true;
    notifyListeners();
  }

  void toggle() {
    _isDark = !_isDark;
    notifyListeners();
    _storage.saveDarkMode(_isDark);
  }
}
