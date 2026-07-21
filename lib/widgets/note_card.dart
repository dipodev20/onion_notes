import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import 'animated_background.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NoteCard({super.key, required this.note, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final preview = note.blocks
        .map((b) => b.plainText)
        .where((t) => t.trim().isNotEmpty)
        .join(' ');
    final isDark = BackgroundStyles.isDark(note.backgroundId);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AnimatedNoteBackground(
            styleId: note.backgroundId,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title.isEmpty ? 'Без названия' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: note.resolvedFontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      preview.isEmpty ? 'Пустая заметка' : preview,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: note.resolvedFontFamily,
                        fontSize: 13.5,
                        height: 1.35,
                        color: isDark
                            ? Colors.white.withOpacity(0.85)
                            : AppColors.ink.withOpacity(0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d MMM, HH:mm', 'ru').format(note.updatedAt),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white70 : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
