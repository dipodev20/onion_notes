import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show instantiateImageCodec;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/roads_provider.dart';
import '../services/note_codec.dart';
import '../services/rich_text_sync.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/formatting_toolbar.dart';
import '../widgets/onion_icons.dart';
import '../widgets/rich_run_controller.dart';

const _fontChoices = ['Poppins', 'Comfortaa', 'Quicksand', 'PlayfairDisplay', 'Caveat', 'SpaceMono'];
const _titleMaxLength = 60;

/// null означает "не переопределять шрифт" — используется вместо ''
/// в TextStyle, потому что пустая строка в качестве fontFamily невалидна.
String? _resolveFont(String f) => f.isEmpty ? null : f;

class EditorScreen extends StatefulWidget {
  final String noteId;
  const EditorScreen({super.key, required this.noteId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late Note _note;
  late TextEditingController _titleController;
  final Map<String, RichRunController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  String? _focusedBlockId;
  String? _selectedImageBlockId;
  Timer? _historyDebounce;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotesProvider>();
    _note = provider.byId(widget.noteId)!.copy();
    _titleController = TextEditingController(text: _note.title);
    provider.pushHistory(_note);
  }

  @override
  void dispose() {
    _historyDebounce?.cancel();
    _titleController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  Color get _baseTextColor =>
      BackgroundStyles.isDark(_note.backgroundId) ? Colors.white : AppColors.ink;

  RichRunController _controllerFor(NoteBlock block) {
    final existing = _controllers[block.id];
    if (existing != null) return existing;
    final ctrl = RichRunController(runs: block.runs, baseColor: _baseTextColor);
    ctrl.addListener(() => _onControllerChanged(block, ctrl));
    _controllers[block.id] = ctrl;
    return ctrl;
  }

  FocusNode _focusFor(String blockId) {
    return _focusNodes.putIfAbsent(blockId, () {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          setState(() {
            _focusedBlockId = blockId;
            _selectedImageBlockId = null;
          });
        }
      });
      return node;
    });
  }

  /// Вызывается на КАЖДОЕ изменение контроллера (текст ИЛИ выделение).
  /// Раньше здесь пересчитанные runs клались только в block.runs, а не в
  /// controller.runs — из-за этого поле рисовало устаревшую разметку и
  /// новый набранный текст не появлялся. Теперь синхронизируем оба места.
  void _onBlockTextChanged(NoteBlock block, RichRunController controller) {
    final oldPlain = RichTextSync.plainText(block.runs);
    if (oldPlain == controller.text) return; // изменилось только выделение
    final newRuns = RichTextSync.applyEdit(block.runs, controller.text);
    block.runs = newRuns;
    controller.runs = newRuns;
    _scanWikiLinks(controller.text);
    _saveSoon();
  }

  static final _wikiLinkPattern = RegExp(r'\[\[([^\[\]]+)\]\]');

  /// Ищет [[Название заметки]] в тексте блока и, если находится заметка с
  /// таким названием, автоматически прокладывает "дорогу" к ней — это и
  /// есть вики-ссылки: не нужно вручную идти в раздел "Дороги".
  void _scanWikiLinks(String text) {
    final matches = _wikiLinkPattern.allMatches(text);
    if (matches.isEmpty) return;
    final notesProvider = context.read<NotesProvider>();
    final roadsProvider = context.read<RoadsProvider>();
    for (final m in matches) {
      final title = m.group(1)?.trim();
      if (title == null || title.isEmpty) continue;
      Note? target;
      for (final n in notesProvider.notes) {
        if (n.id != _note.id && n.title.trim().toLowerCase() == title.toLowerCase()) {
          target = n;
          break;
        }
      }
      if (target != null) {
        roadsProvider.connect(_note.id, target.id, label: 'вики-ссылка');
      }
    }
  }

  /// Обёртка над [_onBlockTextChanged], которая ДОПОЛНИТЕЛЬНО обновляет
  /// экран при простом изменении выделения (без набора текста). Раньше
  /// такие события вообще ничего не перерисовывали — из-за этого кнопки
  /// тулбара (жирный/курсив/маркер/…) могли выглядеть неактивными даже
  /// при реально выделенном тексте, пока не случался какой-то другой
  /// ре-рендер экрана.
  void _onControllerChanged(NoteBlock block, RichRunController controller) {
    _onBlockTextChanged(block, controller);
    if (mounted) setState(() {});
  }

  void _saveSoon({bool checkpoint = false}) {
    _note.title = _titleController.text;
    context.read<NotesProvider>().updateNote(_note);
    if (checkpoint) {
      context.read<NotesProvider>().pushHistory(_note);
    } else {
      _historyDebounce?.cancel();
      _historyDebounce = Timer(const Duration(milliseconds: 900), () {
        context.read<NotesProvider>().pushHistory(_note);
      });
    }
  }

  NoteBlock? get _focusedBlock {
    if (_focusedBlockId == null) return null;
    try {
      return _note.blocks.firstWhere((b) => b.id == _focusedBlockId);
    } catch (_) {
      return null;
    }
  }

  /// Режет runs текстового блока на две части по символьному смещению —
  /// нужно, чтобы вставить блок (чек/линию/фото) ровно там, где стоит
  /// курсор, а не после всего блока целиком.
  List<TextRun> _sliceRuns(List<TextRun> runs, int start, int end) {
    final result = <TextRun>[];
    int pos = 0;
    for (final r in runs) {
      final rStart = pos;
      final rEnd = pos + r.text.length;
      pos = rEnd;
      final sliceStart = start.clamp(rStart, rEnd);
      final sliceEnd = end.clamp(rStart, rEnd);
      if (sliceEnd > sliceStart) {
        final newRun = r.copy();
        newRun.text = r.text.substring(sliceStart - rStart, sliceEnd - rStart);
        result.add(newRun);
      }
    }
    if (result.isEmpty) result.add(TextRun(text: ''));
    return result;
  }

  void _insertBlock(NoteBlock block) {
    final focused = _focusedBlock;

    // Если курсор стоит внутри текста (не в начале и не в конце), режем
    // этот текстовый блок пополам и вставляем новый блок ровно между
    // половинками — раньше он просто вставлялся ПОСЛЕ ВСЕГО блока, что
    // на практике означало "в самый низ", если заметка написана одним
    // длинным абзацем.
    if (focused != null &&
        (focused.type == BlockType.text || focused.type == BlockType.checkbox)) {
      final controller = _controllers[focused.id];
      if (controller != null) {
        final fullText = controller.text;
        final sel = controller.selection;
        final cursor = (sel.isValid ? sel.baseOffset : fullText.length)
            .clamp(0, fullText.length);
        if (cursor > 0 && cursor < fullText.length) {
          final beforeRuns = _sliceRuns(focused.runs, 0, cursor);
          final afterRuns = _sliceRuns(focused.runs, cursor, fullText.length);
          final idx = _note.blocks.indexOf(focused);
          setState(() {
            focused.runs = beforeRuns;
            final afterBlock = NoteBlock(type: focused.type, runs: afterRuns);
            _note.blocks.insert(idx + 1, block);
            _note.blocks.insert(idx + 2, afterBlock);
          });
          // Старые контроллеры для "before"-блока устарели — пересоздаём
          // их лениво при следующей отрисовке, а не пытаемся обновить на
          // месте (риск рассинхронизации с diff-логикой ввода текста).
          _controllers.remove(focused.id)?.dispose();
          _focusNodes.remove(focused.id)?.dispose();
          _saveSoon(checkpoint: true);
          return;
        }
      }
    }

    final idx = _focusedBlockId == null
        ? _note.blocks.length
        : _note.blocks.indexWhere((b) => b.id == _focusedBlockId) + 1;
    setState(() {
      _note.blocks.insert(idx, block);
    });
    _saveSoon(checkpoint: true);
  }

  /// Применяет стиль к последнему известному выделению текущего блока.
  /// Использует [RichRunController.lastSelection], которое переживает
  /// потерю фокуса (в отличие от live `controller.selection`) — это и
  /// чинит "кривые" инструменты, ломавшиеся при открытии палитры цвета.
  void _applyStyleToSelection(TextRun Function(TextRun) transform) {
    final block = _focusedBlock;
    if (block == null || block.type == BlockType.image) return;
    final controller = _controllers[block.id];
    if (controller == null) return;
    final sel = controller.lastSelection;
    if (!sel.isValid || sel.isCollapsed) return;
    final newRuns = RichTextSync.applyStyle(block.runs, sel.start, sel.end, transform);
    setState(() {
      block.runs = newRuns;
      controller.runs = newRuns;
    });
    _saveSoon(checkpoint: true);
  }

  bool get _hasActiveSelection {
    final block = _focusedBlock;
    if (block == null || block.type == BlockType.image) return false;
    final controller = _controllers[block.id];
    if (controller == null) return false;
    return controller.lastSelection.isValid && !controller.lastSelection.isCollapsed;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    final aspect = await _decodeAspectRatio(bytes);
    _insertBlock(NoteBlock(
      type: BlockType.image,
      imageBase64: b64,
      imageWidth: 1.0,
      imageAlign: 'center',
      imageAspect: aspect,
    ));
  }

  /// Реальное соотношение сторон фото — чтобы вставленную картинку не
  /// кадрировало под фиксированную высоту, а показывало целиком.
  Future<double> _decodeAspectRatio(Uint8List bytes) async {
    try {
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      if (w <= 0 || h <= 0) return 1.0;
      return w / h;
    } catch (_) {
      return 1.0;
    }
  }

  void _undo() {
    final prev = context.read<NotesProvider>().undo(_note);
    if (prev == null) return;
    _loadSnapshot(prev);
  }

  void _redo() {
    final next = context.read<NotesProvider>().redo(_note);
    if (next == null) return;
    _loadSnapshot(next);
  }

  void _loadSnapshot(Note snapshot) {
    setState(() {
      _note = snapshot;
      _titleController.text = _note.title;
      for (final c in _controllers.values) {
        c.dispose();
      }
      for (final f in _focusNodes.values) {
        f.dispose();
      }
      _controllers.clear();
      _focusNodes.clear();
      _focusedBlockId = null;
      _selectedImageBlockId = null;
    });
    context.read<NotesProvider>().updateNote(_note);
  }

  Future<void> _openWandMenu() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Шрифт заметки', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _fontChoices.map((f) {
                  final selected = _note.fontFamily == f;
                  return ChoiceChip(
                    label: Text(f, style: TextStyle(fontFamily: _resolveFont(f))),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _note.fontFamily = f);
                      _saveSoon(checkpoint: true);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: AppColors.purple),
                title: const Text('Скопировать код заметки'),
                subtitle: const Text('Вставьте на другом телефоне, чтобы перенести заметку'),
                onTap: () {
                  final code = NoteCodec.encode(_note);
                  Clipboard.setData(ClipboardData(text: code));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Код скопирован')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBackgroundPicker() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: BackgroundStyles.ids.map((id) {
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, id),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: AnimatedNoteBackground(styleId: id, child: const SizedBox.expand()),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 70,
                      child: Text(
                        BackgroundStyles.label(id),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (chosen != null) {
      setState(() => _note.backgroundId = chosen);
      final newBase = _baseTextColor;
      for (final c in _controllers.values) {
        c.updateBaseColor(newBase);
      }
      _saveSoon(checkpoint: true);
    }
  }

  Future<void> _pickTextColor() async {
    final chosen = await showTextColorPicker(context);
    if (chosen == null) return;
    if (chosen == 'auto') {
      _applyStyleToSelection((r) => r.copy()..textColor = null);
    } else {
      _applyStyleToSelection((r) => r.copy()..textColor = chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = context.watch<NotesProvider>().canUndo(_note.id);
    final canRedo = context.watch<NotesProvider>().canRedo(_note.id);

    return Scaffold(
      body: AnimatedNoteBackground(
        styleId: _note.backgroundId,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(canUndo, canRedo),
              Expanded(child: _buildBody()),
              FormattingToolbar(
                canStyleSelection: _hasActiveSelection,
                onCheckbox: () => _insertBlock(NoteBlock(type: BlockType.checkbox)),
                onBold: () => _applyStyleToSelection((r) => r.copy()..bold = !r.bold),
                onItalic: () => _applyStyleToSelection((r) => r.copy()..italic = !r.italic),
                onHighlight: () => _applyStyleToSelection((r) => r.copy()..highlight = !r.highlight),
                onColorFill: () async {
                  final color = await showColorFillPicker(context);
                  if (color == null) return;
                  final hex = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                  _applyStyleToSelection((r) => r.copy()..fillColor = hex);
                },
                onTextColor: _pickTextColor,
                onImage: _pickImage,
                onBackground: _openBackgroundPicker,
                onDivider: () => _insertBlock(NoteBlock(type: BlockType.divider)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool canUndo, bool canRedo) {
    final fg = _baseTextColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _saveSoon(checkpoint: true);
              Navigator.pop(context);
            },
            icon: OnionIcons.exitArrow(color: fg),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  onChanged: (_) => _saveSoon(),
                  maxLength: _titleMaxLength,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  style: TextStyle(
                    fontFamily: _resolveFont(_note.fontFamily),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Заголовок',
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
                Text(
                  DateFormat('d MMMM yyyy, HH:mm', 'ru').format(_note.createdAt),
                  style: TextStyle(fontSize: 11.5, color: fg.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          IconButton(onPressed: _openWandMenu, icon: OnionIcons.magicWand(color: fg)),
          IconButton(
            onPressed: canUndo ? _undo : null,
            icon: OnionIcons.arrowBack(color: canUndo ? fg : fg.withValues(alpha: 0.25)),
          ),
          IconButton(
            onPressed: canRedo ? _redo : null,
            icon: OnionIcons.arrowForward(color: canRedo ? fg : fg.withValues(alpha: 0.25)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final fg = _baseTextColor;
    final rendered = <Widget>[];
    int i = 0;
    while (i < _note.blocks.length) {
      final block = _note.blocks[i];
      final canPairWithNext = block.type == BlockType.image &&
          block.imageAlign != 'center' &&
          block.imageWidth < 0.99 &&
          i + 1 < _note.blocks.length &&
          _note.blocks[i + 1].type == BlockType.text;

      if (canPairWithNext) {
        final textBlock = _note.blocks[i + 1];
        rendered.add(_buildImageTextRow(block, textBlock, fg));
        i += 2;
      } else {
        rendered.add(_buildBlock(block, fg));
        i += 1;
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      itemCount: rendered.length + 1,
      itemBuilder: (context, i) {
        if (i == rendered.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _buildRelatedNotes(fg),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: rendered[i],
        );
      },
    );
  }

  /// Заметки, связанные с текущей через "Дороги" (в том числе созданные
  /// автоматически по [[вики-ссылкам]] в тексте) — аналог обратных ссылок.
  Widget _buildRelatedNotes(Color fg) {
    final roads = context.watch<RoadsProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final edges = roads.edgesFor(_note.id);
    if (edges.isEmpty) return const SizedBox.shrink();

    final related = <Note>[];
    for (final e in edges) {
      final otherId = e.fromNoteId == _note.id ? e.toNoteId : e.fromNoteId;
      final other = notesProvider.byId(otherId);
      if (other != null) related.add(other);
    }
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OnionIcons.road(size: 14, color: fg.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text('Связанные заметки',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: related.map((n) {
            return GestureDetector(
              onTap: () {
                _saveSoon(checkpoint: true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => EditorScreen(noteId: n.id)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
                child: Text(
                  n.title.isEmpty ? 'Без названия' : n.title,
                  style: TextStyle(fontSize: 12, color: fg),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageTextRow(NoteBlock imageBlock, NoteBlock textBlock, Color fg) {
    final isSelected = _selectedImageBlockId == imageBlock.id;
    final imageWidget = _ImageBlockWidget(
      block: imageBlock,
      selected: isSelected,
      showControlsInline: false,
      onTap: () => setState(() =>
          _selectedImageBlockId = _selectedImageBlockId == imageBlock.id ? null : imageBlock.id),
      onDelete: () {
        setState(() => _note.blocks.remove(imageBlock));
        _saveSoon(checkpoint: true);
      },
      onSizeChanged: (w) {
        setState(() => imageBlock.imageWidth = w);
        _saveSoon(checkpoint: true);
      },
      onAlignChanged: (a) {
        setState(() => imageBlock.imageAlign = a);
        _saveSoon(checkpoint: true);
      },
      onDone: () => setState(() => _selectedImageBlockId = null),
    );
    final textWidget = _buildTextField(textBlock, fg);
    final children = imageBlock.imageAlign == 'left'
        ? [SizedBox(width: 110, child: imageWidget), const SizedBox(width: 12), Expanded(child: textWidget)]
        : [Expanded(child: textWidget), const SizedBox(width: 12), SizedBox(width: 110, child: imageWidget)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        if (isSelected) ...[
          const SizedBox(height: 8),
          _ImageControls(
            block: imageBlock,
            onSizeChanged: (w) {
              setState(() => imageBlock.imageWidth = w);
              _saveSoon(checkpoint: true);
            },
            onAlignChanged: (a) {
              setState(() => imageBlock.imageAlign = a);
              _saveSoon(checkpoint: true);
            },
            onDone: () => setState(() => _selectedImageBlockId = null),
          ),
        ],
      ],
    );
  }

  Widget _buildBlock(NoteBlock block, Color fg) {
    switch (block.type) {
      case BlockType.divider:
        return Container(height: 1, color: fg.withValues(alpha: 0.15));
      case BlockType.image:
        return _ImageBlockWidget(
          block: block,
          selected: _selectedImageBlockId == block.id,
          onTap: () => setState(
              () => _selectedImageBlockId = _selectedImageBlockId == block.id ? null : block.id),
          onDelete: () {
            setState(() => _note.blocks.remove(block));
            _saveSoon(checkpoint: true);
          },
          onSizeChanged: (w) {
            setState(() => block.imageWidth = w);
            _saveSoon(checkpoint: true);
          },
          onAlignChanged: (a) {
            setState(() => block.imageAlign = a);
            _saveSoon(checkpoint: true);
          },
          onDone: () => setState(() => _selectedImageBlockId = null),
        );
      case BlockType.checkbox:
        return _CheckboxBlockWidget(
          block: block,
          controller: _controllerFor(block),
          focusNode: _focusFor(block.id),
          fontFamily: _resolveFont(_note.fontFamily),
          textColor: fg,
          onToggle: () {
            setState(() => block.done = !block.done);
            _saveSoon(checkpoint: true);
          },
          onDelete: () {
            setState(() => _note.blocks.remove(block));
            _saveSoon(checkpoint: true);
          },
        );
      case BlockType.text:
        return _buildTextField(block, fg);
    }
  }

  Widget _buildTextField(NoteBlock block, Color fg) {
    return TextField(
      controller: _controllerFor(block),
      focusNode: _focusFor(block.id),
      maxLines: null,
      style: TextStyle(fontFamily: _resolveFont(_note.fontFamily), fontSize: 15.5, height: 1.4, color: fg),
      decoration: const InputDecoration(
        border: InputBorder.none,
        filled: false,
        contentPadding: EdgeInsets.zero,
        hintText: 'Пишите здесь…',
      ),
    );
  }
}

class _CheckboxBlockWidget extends StatelessWidget {
  final NoteBlock block;
  final RichRunController controller;
  final FocusNode focusNode;
  final String? fontFamily;
  final Color textColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CheckboxBlockWidget({
    required this.block,
    required this.controller,
    required this.focusNode,
    required this.fontFamily,
    required this.textColor,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            margin: const EdgeInsets.only(top: 3, right: 10),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: block.done ? AppColors.purple : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: block.done ? AppColors.purple : textColor.withValues(alpha: 0.4), width: 1.6),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: block.done
                  ? KeyedSubtree(key: const ValueKey('on'), child: OnionIcons.checkMark(size: 15))
                  : const SizedBox.shrink(key: ValueKey('off')),
            ),
          ),
        ),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 15.5,
              height: 1.4,
              color: block.done ? textColor.withValues(alpha: 0.45) : textColor,
              decoration: block.done ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: textColor.withValues(alpha: 0.6),
              decorationThickness: 1.6,
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              style: const TextStyle(fontSize: 15.5, height: 1.4),
              decoration: const InputDecoration(
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: 'Задача…',
              ),
            ),
          ),
        ),
        IconButton(
          iconSize: 18,
          icon: Icon(Icons.close_rounded, color: textColor.withValues(alpha: 0.35)),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _ImageBlockWidget extends StatelessWidget {
  final NoteBlock block;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<String> onAlignChanged;
  final VoidCallback onDone;

  /// В узкой колонке (фото рядом с текстом) панель настроек не влезает —
  /// там её показывает родитель во всю ширину строки отдельно.
  final bool showControlsInline;

  const _ImageBlockWidget({
    required this.block,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.onSizeChanged,
    required this.onAlignChanged,
    required this.onDone,
    this.showControlsInline = true,
  });

  @override
  Widget build(BuildContext context) {
    if (block.imageBase64 == null || block.imageBase64!.isEmpty) {
      return const SizedBox.shrink();
    }
    // Высота подбирается по реальным пропорциям фото и ограничена только
    // сверху — раньше картинка всегда кадрировалась под фиксированную
    // высоту (BoxFit.cover), даже когда в этом не было необходимости.
    final maxHeight = block.imageWidth >= 0.99 ? 320.0 : 220.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final naturalHeight = block.imageAspect > 0 ? width / block.imageAspect : width;
                  final displayHeight =
                      naturalHeight > maxHeight ? maxHeight : naturalHeight;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.card),
                    child: SizedBox(
                      width: width,
                      height: displayHeight,
                      child: Image.memory(
                        base64Decode(block.imageBase64!),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              if (selected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: AppColors.purple, width: 2),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration:
                        BoxDecoration(color: Colors.black.withValues(alpha: 0.45), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          if (selected && showControlsInline) ...[
            const SizedBox(height: 8),
            _ImageControls(
              block: block,
              onSizeChanged: onSizeChanged,
              onAlignChanged: onAlignChanged,
              onDone: onDone,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImageControls extends StatelessWidget {
  final NoteBlock block;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<String> onAlignChanged;
  final VoidCallback onDone;

  const _ImageControls({
    required this.block,
    required this.onSizeChanged,
    required this.onAlignChanged,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.chip),
        boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.10), blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _sizeBtn(0.35, 0.28, 'S'),
          _sizeBtn(0.55, 0.46, 'M'),
          _sizeBtn(1.0, 0.75, 'L'),
          Container(
              width: 1,
              height: 20,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 6)),
          _alignBtn('left', OnionIcons.alignLeft(size: 16, color: _c('left'))),
          _alignBtn('center', OnionIcons.alignCenterImg(size: 16, color: _c('center'))),
          _alignBtn('right', OnionIcons.alignRight(size: 16, color: _c('right'))),
          Container(
              width: 1,
              height: 20,
              color: AppColors.divider,
              margin: const EdgeInsets.symmetric(horizontal: 6)),
          GestureDetector(
            onTap: onDone,
            child: const Icon(Icons.check_rounded, size: 18, color: AppColors.purple),
          ),
        ],
      ),
    );
  }

  Color _c(String align) => block.imageAlign == align ? AppColors.purple : AppColors.inkSoft;

  Widget _sizeBtn(double value, double fill, String label) {
    final active = (block.imageWidth - value).abs() < 0.01;
    return GestureDetector(
      onTap: () => onSizeChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: OnionIcons.sizeDot(
          size: 20,
          fill: fill,
          color: active ? AppColors.purple : AppColors.inkSoft,
        ),
      ),
    );
  }

  Widget _alignBtn(String align, Widget icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(onTap: () => onAlignChanged(align), child: icon),
    );
  }
}
