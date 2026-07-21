import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Пользовательское офлайн мини-приложение: локальный HTML-файл + своя
/// квадратная иконка. Открывается на весь экран как отдельное приложение.
class MiniApp {
  final String id;
  String title;
  String htmlPath; // относительный путь внутри documents: miniapps/<id>.html
  String iconBase64; // квадратная иконка, уже обрезанная
  DateTime createdAt;

  MiniApp({
    String? id,
    required this.title,
    required this.htmlPath,
    required this.iconBase64,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Фиксированный порт локального сервера для ЭТОГО приложения — всегда
  /// одинаковый (выводится из id), поэтому у приложения каждый раз один и
  /// тот же адрес (http://127.0.0.1:port), а значит localStorage и прочие
  /// данные внутри HTML сохраняются между открытиями. У разных
  /// мини-приложений порты разные, чтобы они не путали данные друг друга.
  int get port => 21000 + (id.hashCode.abs() % 9000);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'htmlPath': htmlPath,
        'iconBase64': iconBase64,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MiniApp.fromJson(Map<String, dynamic> json) => MiniApp(
        id: json['id'],
        title: json['title'] ?? 'Без названия',
        htmlPath: json['htmlPath'] ?? '',
        iconBase64: json['iconBase64'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
