import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/mini_app.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Открывает мини-приложение пользователя на весь экран, как отдельное
/// офлайн-приложение — без своего тулбара/адресной строки. Выход —
/// обычной системной кнопкой/жестом "назад", ничего специального не нужно:
/// это просто обычный экран в стеке навигации.
///
/// HTML отдаётся через локальный HTTP-сервер (127.0.0.1, свой фиксированный
/// порт на каждое приложение — см. MiniApp.port), а не строкой и не через
/// file://. Так у приложения появляется настоящий стабильный адрес
/// (origin), и всё, что оно сохраняет через localStorage/IndexedDB, само
/// переживает закрытие и повторное открытие — сервер поднимается заново
/// на тот же порт, WebView видит тот же origin, браузерное хранилище
/// подключается к тем же данным.
class MiniAppRunnerScreen extends StatefulWidget {
  final MiniApp app;
  const MiniAppRunnerScreen({super.key, required this.app});

  @override
  State<MiniAppRunnerScreen> createState() => _MiniAppRunnerScreenState();
}

class _MiniAppRunnerScreenState extends State<MiniAppRunnerScreen> {
  WebViewController? _controller;
  HttpServer? _server;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final file = await StorageService().miniAppHtmlFile(widget.app.htmlPath);
      if (!await file.exists()) {
        setState(() {
          _error = 'Файл мини-приложения не найден';
          _loading = false;
        });
        return;
      }
      final html = await file.readAsBytes();
      final started = await _startServer(widget.app.port, html);
      _server = started.server;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse('http://127.0.0.1:${started.port}/'));
      setState(() => _controller = controller);
    } catch (e) {
      setState(() {
        _error = 'Не удалось открыть мини-приложение';
        _loading = false;
      });
    }
  }

  /// Локальный сервер на фиксированном порту — отдаёт один и тот же HTML
  /// на любой путь. Если порт вдруг занят (например, предыдущая сессия
  /// не успела закрыться), пробуем ещё несколько портов рядом, чтобы
  /// приложение не отказывалось открываться — просто в этот раз данные
  /// внутри HTML могут начаться с нуля, так как адрес изменился.
  Future<({HttpServer server, int port})> _startServer(
    int preferredPort,
    List<int> htmlBytes,
  ) async {
    for (var attempt = 0; attempt < 6; attempt++) {
      final port = preferredPort + attempt;
      try {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port, shared: true);
        server.listen((request) {
          request.response.headers.contentType = ContentType.html;
          request.response.add(htmlBytes);
          request.response.close();
        });
        return (server: server, port: port);
      } on SocketException {
        continue;
      }
    }
    throw Exception('Не удалось поднять локальный сервер мини-приложения');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            if (_controller != null)
              WebViewWidget(
                controller: _controller!,
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
              ),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, style: const TextStyle(color: AppColors.inkSoft)),
                ),
              ),
            if (_loading && _error == null)
              const Center(child: CircularProgressIndicator(color: AppColors.purple)),
          ],
        ),
      ),
    );
  }
}
