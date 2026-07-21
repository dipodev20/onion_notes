import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/mini_app.dart';
import '../providers/mini_apps_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/onion_icons.dart';
import 'mini_app_runner_screen.dart';

const _uuid = Uuid();

/// Раздел "Мини-приложения": пользователь вставляет код своего HTML
/// (текстом — так надёжнее, чем через системный проводник, который на
/// разных Android-сборках ведёт себя по-разному), выбирает ему квадратную
/// иконку — и дальше открывает как обычное офлайн-приложение прямо внутри
/// ONION.
class MiniAppsScreen extends StatelessWidget {
  const MiniAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final palette = AppPalette.of(isDark);

    return Consumer<MiniAppsProvider>(
      builder: (context, provider, _) {
        if (!provider.loaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.purple));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Мини-приложения',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: palette.ink)),
                  ),
                  GestureDetector(
                    onTap: () => _addApp(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: OnionIcons.plus(size: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: provider.apps.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/mascot_coffee.png', width: 160),
                            const SizedBox(height: 12),
                            Text(
                              'Пока нет своих приложений — вставьте код HTML\nи выберите ему иконку',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: provider.apps.length,
                      itemBuilder: (context, i) => _AppIcon(app: provider.apps[i], palette: palette),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addApp(BuildContext context) async {
    final provider = context.read<MiniAppsProvider>();

    final entry = await _askHtmlAndTitle(context);
    if (entry == null) return;
    final (html, title) = entry;
    if (html.trim().isEmpty || title.trim().isEmpty) return;

    if (!context.mounted) return;
    final iconPicker = ImagePicker();
    final iconFile = await iconPicker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (iconFile == null) return;
    final iconBytes = await iconFile.readAsBytes();

    final id = _uuid.v4();
    final htmlPath = await StorageService().storeMiniAppHtml(id, utf8.encode(html));
    final app = MiniApp(
      id: id,
      title: title.trim(),
      htmlPath: htmlPath,
      iconBase64: base64Encode(iconBytes),
    );
    await provider.add(app);
  }

  /// Показывает форму: название приложения + большое поле для вставки
  /// HTML-кода (с кнопкой "Вставить из буфера" для удобства). Возвращает
  /// (html, title) или null, если отменили.
  Future<(String, String)?> _askHtmlAndTitle(BuildContext context) {
    final titleCtrl = TextEditingController();
    final htmlCtrl = TextEditingController();
    return showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Новое мини-приложение', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Название приложения'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('HTML-код', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) htmlCtrl.text = data!.text!;
                  },
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: const Text('Вставить из буфера'),
                ),
              ],
            ),
            TextField(
              controller: htmlCtrl,
              maxLines: 8,
              minLines: 4,
              style: const TextStyle(fontFamily: 'SpaceMono', fontSize: 11.5),
              decoration: const InputDecoration(hintText: '<html>...</html>'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (htmlCtrl.text.trim().isEmpty || titleCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx, (htmlCtrl.text, titleCtrl.text));
                },
                child: const Text('Далее — выбрать иконку'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final MiniApp app;
  final AppPalette palette;
  const _AppIcon({required this.app, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MiniAppRunnerScreen(app: app)),
      ),
      onLongPress: () => _showOptions(context),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: app.iconBase64.isEmpty
                  ? Container(color: palette.purpleSoft)
                  : Image.memory(base64Decode(app.iconBase64), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            app.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: palette.ink),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: OnionIcons.trash(),
              title: const Text('Удалить приложение'),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<MiniAppsProvider>().remove(app);
              },
            ),
          ],
        ),
      ),
    );
  }
}
