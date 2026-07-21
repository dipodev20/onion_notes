import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/roads_provider.dart';
import '../providers/theme_provider.dart';
import '../services/layout_service.dart';
import '../services/note_codec.dart';
import '../theme/app_theme.dart';
import '../widgets/onion_icons.dart';
import '../widgets/theme_toggle.dart';

const _aiPrompt = '''
Ты помогаешь писать заметки для приложения ONION. Если нужна ОДНА заметка —
ответь кодом в формате ONION-NOTE-V1. Если нужно НЕСКОЛЬКО связанных
заметок сразу — ответь кодом в формате ONION-BUNDLE-V1 (см. ниже). Больше
ничего не пиши — ни до, ни после кода.

--- ОДНА ЗАМЕТКА: ONION-NOTE-V1 ---
ФОРМАТ (построчно):
#ONION-NOTE-V1
TITLE: <заголовок заметки, одна строка>
BG: <один из: plainWhite, lavenderDrift, sunsetGlow, mintBreeze, nightIndigo,
     sakura, wavesJapan, paperWashi, rainy, snowy, starryNight, foggy,
     matrixHacker>
FONT: <один из: Poppins, Comfortaa, Quicksand, PlayfairDisplay, Caveat,
       SpaceMono>
CREATED: <ISO-дата, например 2026-07-14T12:00:00.000>
---
<строки блоков — см. ниже>

БЛОКИ (каждый на отдельной строке):
[TEXT] <текст абзаца>
[CHECK| ] <текст задачи>        — невыполненная задача
[CHECK|x] <текст задачи>        — выполненная задача
[IMG|1.0|center]                — картинку сюда вставит сам пользователь,
                                   просто оставь строку пустой после ] и
                                   пробела; ширина: 0.35 / 0.55 / 1.0,
                                   выравнивание: left / center / right
[DIVIDER]                       — тонкая линия-разделитель

РАЗМЕТКА ВНУТРИ ТЕКСТА БЛОКА:
**жирный текст**
__наклонный текст (курсив)__
~~текст с маркером-подсветкой~~
((#RRGGBB|текст с заливкой фона этим цветом))
[[#RRGGBB|текст этим цветом]]

ВАЖНО: эти простые маркеры НЕЛЬЗЯ вкладывать друг в друга — например
~~((#RRGGBB|текст))~~ не сработает, лишние ~~ останутся видны как текст.
Если нужно НЕСКОЛЬКО стилей сразу на одном фрагменте — единый маркер:
{{флаги|текст}}, флаги через ";" без пробелов:
  b — жирный, i — курсив, h — маркер-подсветка,
  f:#RRGGBB — заливка фона, c:#RRGGBB — цвет текста.
Пример: {{b;h|Важно}} — жирный и маркер одновременно.
Пример: {{f:#FF6B6B;b|Критично}} — жирный на красной заливке.

Также внутри текста можно писать [[Название другой заметки]] — это
вики-ссылка, приложение само проложит "дорогу" к заметке с таким
названием, если она есть.

--- НЕСКОЛЬКО ЗАМЕТОК СРАЗУ: ONION-BUNDLE-V1 ---
Если пользователь просит написать план/цепочку из нескольких заметок и
соединить их — не пытайся сам придумывать координаты на экране (ты их не
видишь, приложение расставит карточки само). Просто перечисли заметки и
их связи по названиям:

#ONION-BUNDLE-V1
#ONION-NOTE-V1
TITLE: Первая заметка
...
---
[TEXT] ...
#ONION-NOTE-V1
TITLE: Вторая заметка
...
---
[TEXT] ...
ROADS:
Первая заметка -> Вторая заметка | необязательная подпись связи
Вторая заметка -> Первая заметка

Пиши тепло, по делу, используй жирный для ключевых слов, маркер — для
самого важного, чек-листы — для конкретных шагов. Не выдумывай лишние
блоки, не пиши ничего кроме кода.

Задача пользователя: <ОПИШИ ЗДЕСЬ, ЧТО НУЖНО НАПИСАТЬ>
''';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final palette = AppPalette.of(themeProvider.isDark);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: OnionIcons.arrowBack(color: palette.ink),
                  ),
                  Text('Настройки',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: palette.ink)),
                ],
              ),
              const SizedBox(height: 12),
          ThemeSettingRow(
            isDark: themeProvider.isDark,
            onToggle: () => context.read<ThemeProvider>().toggle(),
            palette: palette,
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: OnionIcons.pasteCodeTool(color: AppColors.purple),
            title: 'Вставить заметку из кода',
            subtitle: 'Вставьте скопированный ONION-код с другого телефона — одну заметку или сразу пачку',
            palette: palette,
            onTap: () => _pasteFromCode(context),
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: OnionIcons.appsGrid(color: AppColors.purple),
            title: 'Экспортировать все заметки',
            subtitle: 'Скопировать бэкап всех заметок и связей одним кодом',
            palette: palette,
            onTap: () => _exportAll(context),
          ),
          const SizedBox(height: 12),
          _AiPromptCard(palette: palette),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: OnionIcons.offlineTool(color: AppColors.purple),
            title: 'Работает полностью офлайн',
            subtitle: 'Все заметки хранятся только на этом устройстве',
            palette: palette,
          ),
          const SizedBox(height: 12),
          _SettingsCard(
            icon: OnionIcons.infoTool(color: AppColors.purple),
            title: 'ONION',
            subtitle: 'Версия 1.0.0',
            palette: palette,
          ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pasteFromCode(BuildContext context) async {
    final data = await Clipboard.getData('text/plain');
    final text = (data?.text ?? '').trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Буфер обмена пуст')));
      return;
    }

    if (NoteCodec.looksLikeBundle(text)) {
      await _importBundle(context, text);
      return;
    }

    final note = NoteCodec.decode(text);
    if (note == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('В буфере обмена нет кода ONION')));
      return;
    }
    context.read<NotesProvider>().addExistingNote(note);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Заметка добавлена')));
  }

  Future<void> _importBundle(BuildContext context, String text) async {
    final parsed = NoteCodec.decodeBundle(text);
    if (parsed.notes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('В буфере обмена нет кода ONION')));
      return;
    }
    final notesProvider = context.read<NotesProvider>();
    final roadsProvider = context.read<RoadsProvider>();

    // Раскладываем новые карточки по кругу, чтобы они не легли друг на
    // друга — ИИ не видит экран и не должен пытаться угадывать координаты.
    final positions = LayoutService.circlePositions(parsed.notes.length);
    final titleToId = <String, String>{};
    for (var i = 0; i < parsed.notes.length; i++) {
      final note = parsed.notes[i];
      if (i < positions.length) {
        note.x = positions[i].$1;
        note.y = positions[i].$2;
      }
      notesProvider.addExistingNote(note);
      titleToId[note.title.trim().toLowerCase()] = note.id;
    }

    var linked = 0;
    for (final r in parsed.roads) {
      final fromId = titleToId[r.$1.trim().toLowerCase()] ??
          _findExistingByTitle(notesProvider, r.$1);
      final toId = titleToId[r.$2.trim().toLowerCase()] ??
          _findExistingByTitle(notesProvider, r.$2);
      if (fromId != null && toId != null && fromId != toId) {
        roadsProvider.connect(fromId, toId, label: r.$3);
        linked++;
      }
    }

    // [[Название]] прямо в тексте заметок тоже считаем связью — раньше
    // это работало только при живом наборе текста в редакторе, а не при
    // вставке готового кода от ИИ.
    final wikiPattern = RegExp(r'\[\[([^\[\]]+)\]\]');
    for (final note in parsed.notes) {
      for (final block in note.blocks) {
        if (block.type != BlockType.text && block.type != BlockType.checkbox) continue;
        for (final m in wikiPattern.allMatches(block.plainText)) {
          final title = m.group(1)?.trim();
          if (title == null || title.isEmpty) continue;
          final targetId = titleToId[title.toLowerCase()] ?? _findExistingByTitle(notesProvider, title);
          if (targetId != null && targetId != note.id) {
            roadsProvider.connect(note.id, targetId, label: 'вики-ссылка');
            linked++;
          }
        }
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Добавлено заметок: ${parsed.notes.length}, связей: $linked')));
    }
  }

  String? _findExistingByTitle(NotesProvider provider, String title) {
    final t = title.trim().toLowerCase();
    for (final n in provider.notes) {
      if (n.title.trim().toLowerCase() == t) return n.id;
    }
    return null;
  }

  Future<void> _exportAll(BuildContext context) async {
    final notesProvider = context.read<NotesProvider>();
    final roadsProvider = context.read<RoadsProvider>();
    if (notesProvider.notes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Пока нет ни одной заметки')));
      return;
    }
    final byId = {for (final n in notesProvider.notes) n.id: n};
    final roads = <(String, String, String)>[];
    for (final e in roadsProvider.edges) {
      final from = byId[e.fromNoteId];
      final to = byId[e.toNoteId];
      if (from != null && to != null) {
        roads.add((from.title, to.title, e.label));
      }
    }
    final code = NoteCodec.encodeBundle(notesProvider.notes, roads: roads);
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Скопирован бэкап: ${notesProvider.notes.length} заметок')));
    }
  }
}

class _AiPromptCard extends StatefulWidget {
  final AppPalette palette;
  const _AiPromptCard({required this.palette});

  @override
  State<_AiPromptCard> createState() => _AiPromptCardState();
}

class _AiPromptCardState extends State<_AiPromptCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: palette.purpleSoft, borderRadius: BorderRadius.circular(14)),
                    child: Center(child: OnionIcons.aiPromptTool(color: AppColors.purple)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Промт для ИИ',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: palette.ink)),
                        const SizedBox(height: 3),
                        Text('Пусть ваш ИИ сам напишет и красиво оформит заметку',
                            style: TextStyle(fontSize: 12, color: palette.inkSoft)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: palette.inkSoft),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 14),
                Text(
                  'Скопируйте промт ниже и отправьте своему ИИ вместе с описанием '
                  'того, что нужно написать. Он ответит готовым ONION-кодом — '
                  'вставьте его через "Вставить заметку из кода" выше, и заметка '
                  'появится уже оформленной: с жирным, курсивом, маркером, '
                  'чек-листами и цветами.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: palette.inkSoft),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: BorderRadius.circular(AppRadii.button),
                    border: Border.all(color: palette.divider),
                  ),
                  child: Text(
                    _aiPrompt.trim(),
                    style: TextStyle(fontSize: 11, fontFamily: 'SpaceMono', height: 1.5, color: palette.inkSoft),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _aiPrompt.trim()));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('Промт скопирован')));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Скопировать промт'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withValues(alpha: 0.06), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: palette.purpleSoft, borderRadius: BorderRadius.circular(14)),
                child: Center(child: icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: palette.ink)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: palette.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
