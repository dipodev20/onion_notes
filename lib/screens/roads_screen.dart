import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/roads_provider.dart';
import '../services/layout_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/onion_icons.dart';
import 'editor_screen.dart';

/// Пространство, где можно соединять заметки "нитками"-дорогами и
/// проходить их как квест: выполнил задачу — с анимацией переходишь
/// к следующей связанной заметке.
class RoadsScreen extends StatefulWidget {
  const RoadsScreen({super.key});

  @override
  State<RoadsScreen> createState() => _RoadsScreenState();
}

class _RoadsScreenState extends State<RoadsScreen> {
  String? _linkingFromId;
  final TransformationController _transform = TransformationController();
  Size _viewportSize = Size.zero;
  int _lastFitCount = -1;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  /// Подгоняет масштаб и сдвиг холста так, чтобы были видны ВСЕ заметки
  /// разом, без ручного панорамирования. Раньше по умолчанию был виден
  /// только левый верхний угол огромного 1600x1600 холста, и карточки
  /// вдалеке было физически не найти без случайного тыка.
  void _fitToContent(List<Note> notesList) {
    if (notesList.isEmpty || _viewportSize.isEmpty) return;
    const cardW = kCardWidth;
    const cardH = kCardHeight;
    var minX = notesList.first.x;
    var maxX = notesList.first.x + cardW;
    var minY = notesList.first.y;
    var maxY = notesList.first.y + cardH;
    for (final n in notesList) {
      minX = math.min(minX, n.x);
      maxX = math.max(maxX, n.x + cardW);
      minY = math.min(minY, n.y);
      maxY = math.max(maxY, n.y + cardH);
    }
    const pad = 90.0;
    minX -= pad;
    minY -= pad;
    maxX += pad;
    maxY += pad;
    final contentW = maxX - minX;
    final contentH = maxY - minY;
    if (contentW <= 0 || contentH <= 0) return;
    var scale = math.min(_viewportSize.width / contentW, _viewportSize.height / contentH);
    scale = scale.clamp(0.2, 2.5);
    final dx = -minX * scale + (_viewportSize.width - contentW * scale) / 2;
    final dy = -minY * scale + (_viewportSize.height - contentH * scale) / 2;
    if (!scale.isFinite || !dx.isFinite || !dy.isFinite) return;
    setState(() {
      _transform.value = Matrix4.identity()
        ..translate(dx, dy)
        ..scale(scale);
    });
  }

  /// Раскладывает ВСЕ текущие заметки на холсте заново по кругу —
  /// пригодится, если карточки когда-то оказались слишком близко друг к
  /// другу или друг на друге (например, из-за старого бага с
  /// перетаскиванием) и одна закрывает собой другую.
  void _autoArrange(NotesProvider notes) {
    final positions = LayoutService.circlePositions(notes.notes.length);
    for (var i = 0; i < notes.notes.length; i++) {
      if (i < positions.length) {
        notes.notes[i].x = positions[i].$1;
        notes.notes[i].y = positions[i].$2;
      }
    }
    notes.saveAll();
    _fitToContent(notes.notes);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NotesProvider, RoadsProvider>(
      builder: (context, notes, roads, _) {
        if (!notes.loaded || !roads.loaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.purple));
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Дороги между заметками',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  if (_linkingFromId != null)
                    TextButton(
                      onPressed: () => setState(() => _linkingFromId = null),
                      child: const Text('Отменить связь'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _linkingFromId == null
                    ? 'Долгое нажатие на заметку — начать дорогу. Обычное нажатие — открыть.'
                    : 'Теперь нажмите на вторую заметку, чтобы проложить дорогу',
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ),
            Expanded(
              child: notes.notes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/mascot_reading.png', width: 160),
                            const SizedBox(height: 12),
                            const Text(
                              'Пока нечего соединять — создайте пару заметок\nна Главной',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                            ),
                          ],
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        _viewportSize = constraints.biggest;
                        if (_lastFitCount != notes.notes.length) {
                          _lastFitCount = notes.notes.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _fitToContent(notes.notes);
                          });
                        }
                        return Stack(
                          children: [
                            InteractiveViewer(
                              transformationController: _transform,
                              minScale: 0.2,
                              maxScale: 2.5,
                              boundaryMargin: const EdgeInsets.all(150),
                              child: SizedBox(
                                width: kWorldSize,
                                height: kWorldSize,
                                child: Stack(
                                  children: [
                                    CustomPaint(
                                      size: const Size(kWorldSize, kWorldSize),
                                      painter: _WorldBoundsPainter(),
                                    ),
                                    CustomPaint(
                                      size: const Size(kWorldSize, kWorldSize),
                                      painter: _RoadsPainter(notes: notes.notes, edges: roads.edges),
                                    ),
                                    ...notes.notes.map((n) => _buildNode(context, n, notes, roads)),
                                    ...roads.edges.map(
                                        (e) => _buildEdgeHotspot(context, e, notes.notes, roads)),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                          right: 16,
                          bottom: 16,
                          child: GestureDetector(
                            onTap: () => _fitToContent(notes.notes),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadii.button),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.purple.withValues(alpha: 0.15), blurRadius: 10),
                                ],
                              ),
                              child: const Icon(Icons.center_focus_strong_rounded,
                                  color: AppColors.purple, size: 22),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 68,
                          child: GestureDetector(
                            onTap: () => _autoArrange(notes),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppRadii.button),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.purple.withValues(alpha: 0.15), blurRadius: 10),
                                ],
                              ),
                              child: const Icon(Icons.auto_awesome_mosaic_rounded,
                                  color: AppColors.purple, size: 20),
                            ),
                          ),
                        ),
                      ],
                    );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNode(BuildContext context, Note note, NotesProvider notes, RoadsProvider roads) {
    try {
      return _buildNodeInner(context, note, notes, roads);
    } catch (e) {
      // Временная диагностика: если тут что-то падает, раньше карточка
      // просто пропадала без следа. Теперь видно, что именно не так.
      return Positioned(
        left: note.x,
        top: note.y,
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red, width: 2),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Text(
            'Ошибка карточки:\n$e',
            style: const TextStyle(fontSize: 9, color: Colors.red),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
  }

  Widget _buildNodeInner(BuildContext context, Note note, NotesProvider notes, RoadsProvider roads) {
    final isLinking = _linkingFromId == note.id;
    final isDark = BackgroundStyles.isDark(note.backgroundId);
    final fg = isDark ? Colors.white : AppColors.ink;
    return Positioned(
      left: note.x,
      top: note.y,
      child: GestureDetector(
        onTap: () {
          if (_linkingFromId != null && _linkingFromId != note.id) {
            roads.connect(_linkingFromId!, note.id);
            setState(() => _linkingFromId = null);
            return;
          }
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 380),
              pageBuilder: (_, anim, __) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: EditorScreen(noteId: note.id),
                ),
              ),
            ),
          );
        },
        onLongPress: () => setState(() => _linkingFromId = note.id),
        onPanUpdate: (d) {
          // d.delta приходит в экранных пикселях. Если холст сейчас
          // увеличен/уменьшен через InteractiveViewer, тот же жест должен
          // двигать карточку на МЕНЬШЕЕ/БОЛЬШЕЕ расстояние в координатах
          // холста — иначе при зуме карточка улетает намного дальше, чем
          // палец, и оказывается где-то далеко за пределами экрана, а
          // "нитка" к ней тянется в пустоту.
          final scale = _transform.value.getMaxScaleOnAxis();
          setState(() {
            note.x = (note.x + d.delta.dx / scale).clamp(0.0, kWorldSize - kCardWidth);
            note.y = (note.y + d.delta.dy / scale).clamp(0.0, kWorldSize - kCardHeight);
          });
        },
        onPanEnd: (_) => notes.updateNote(note),
        child: Container(
          width: 130,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: isLinking ? AppColors.purple : Colors.transparent, width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.purple.withValues(alpha: 0.12), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: AnimatedNoteBackground(
            styleId: note.backgroundId,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    note.title.isEmpty ? 'Без названия' : note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: fg),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      OnionIcons.road(size: 14, color: isDark ? Colors.white70 : AppColors.purple),
                      const SizedBox(width: 4),
                      Text('${roads.edgesFor(note.id).length}',
                          style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.7))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Небольшая зона на середине "дороги" между двумя заметками — тап
  /// открывает переименование/удаление связи, подпись (если задана)
  /// рисуется прямо тут же.
  Widget _buildEdgeHotspot(BuildContext context, RoadEdge e, List<Note> allNotes, RoadsProvider roads) {
    Note? from;
    Note? to;
    for (final n in allNotes) {
      if (n.id == e.fromNoteId) from = n;
      if (n.id == e.toNoteId) to = n;
    }
    if (from == null || to == null) return const SizedBox.shrink();

    final p1 = Offset(from.x + 65, from.y + 35);
    final p2 = Offset(to.x + 65, to.y + 35);
    final ctrl = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 30);
    // Точка на квадратичной кривой Безье при t=0.5.
    final mid = Offset(
      0.25 * p1.dx + 0.5 * ctrl.dx + 0.25 * p2.dx,
      0.25 * p1.dy + 0.5 * ctrl.dy + 0.25 * p2.dy,
    );

    return Positioned(
      left: mid.dx - 40,
      top: mid.dy - 14,
      child: GestureDetector(
        onTap: () => _editEdge(context, e, roads),
        child: Container(
          constraints: const BoxConstraints(minWidth: 28, maxWidth: 120),
          height: 28,
          padding: EdgeInsets.symmetric(horizontal: e.label.isEmpty ? 0 : 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: e.completed ? AppColors.purple : AppColors.purple.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: AppColors.purple.withValues(alpha: 0.10), blurRadius: 6)],
          ),
          child: e.label.isEmpty
              ? Icon(Icons.link_rounded, size: 14, color: AppColors.purple.withValues(alpha: 0.7))
              : Text(e.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.purple, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  void _editEdge(BuildContext context, RoadEdge e, RoadsProvider roads) {
    final ctrl = TextEditingController(text: e.label);
    showModalBottomSheet(
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
            const Text('Связь между заметками', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Подпись связи (необязательно)'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      roads.toggleCompleted(e.id);
                      Navigator.pop(ctx);
                    },
                    icon: Icon(e.completed ? Icons.radio_button_unchecked : Icons.check_circle_rounded, size: 18),
                    label: Text(e.completed ? 'Не пройдено' : 'Пройдено'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      e.label = ctrl.text.trim();
                      roads.updateLabel(e.id, e.label);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Сохранить'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  roads.disconnect(e.id);
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.link_off_rounded, color: AppColors.danger, size: 18),
                label: const Text('Удалить связь', style: TextStyle(color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Рисует границу "открытого мира" — лёгкая заливка и пунктирная рамка,
/// чтобы было видно, где заканчивается зона, за которую нельзя утащить
/// карточки.
class _WorldBoundsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fill = Paint()..color = AppColors.purple.withValues(alpha: 0.02);
    canvas.drawRect(rect, fill);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.purple.withValues(alpha: 0.18);
    const dash = 18.0;
    const gap = 12.0;
    // Верх и низ
    for (double x = 0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, 0), Offset(math.min(x + dash, size.width), 0), border);
      canvas.drawLine(Offset(x, size.height), Offset(math.min(x + dash, size.width), size.height), border);
    }
    // Левая и правая стороны
    for (double y = 0; y < size.height; y += dash + gap) {
      canvas.drawLine(Offset(0, y), Offset(0, math.min(y + dash, size.height)), border);
      canvas.drawLine(Offset(size.width, y), Offset(size.width, math.min(y + dash, size.height)), border);
    }
  }

  @override
  bool shouldRepaint(covariant _WorldBoundsPainter oldDelegate) => false;
}

class _RoadsPainter extends CustomPainter {
  final List<Note> notes;
  final List<RoadEdge> edges;

  _RoadsPainter({required this.notes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final n in notes) n.id: n};
    for (final e in edges) {
      final from = byId[e.fromNoteId];
      final to = byId[e.toNoteId];
      if (from == null || to == null) continue;
      final p1 = Offset(from.x + 65, from.y + 35);
      final p2 = Offset(to.x + 65, to.y + 35);
      final paint = Paint()
        ..color = (e.completed ? AppColors.purple : AppColors.purple.withOpacity(0.35))
        ..strokeWidth = e.completed ? 3 : 2
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(p1.dx, p1.dy);
      final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 30);
      path.quadraticBezierTo(mid.dx, mid.dy, p2.dx, p2.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoadsPainter oldDelegate) => true;
}
