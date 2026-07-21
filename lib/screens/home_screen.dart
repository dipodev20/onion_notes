import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/note_card.dart';
import '../widgets/onion_icons.dart';
import 'editor_screen.dart';
import 'mini_apps_screen.dart';
import 'roads_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  String _query = '';
  DateTime? _dateFilter;
  String? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final palette = AppPalette.of(isDark);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            _buildNotesTab(palette),
            const RoadsScreen(),
            const MiniAppsScreen(),
          ],
        ),
      ),
      floatingActionButton: _tab == 0 ? _buildPencilFab(context) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        backgroundColor: palette.surface,
        items: [
          BottomNavigationBarItem(
            icon: OnionIcons.home(color: palette.inkSoft),
            activeIcon: OnionIcons.home(color: AppColors.purple),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: OnionIcons.road(color: palette.inkSoft),
            activeIcon: OnionIcons.road(color: AppColors.purple),
            label: 'Дороги',
          ),
          BottomNavigationBarItem(
            icon: OnionIcons.appsGrid(color: palette.inkSoft),
            activeIcon: OnionIcons.appsGrid(color: AppColors.purple),
            label: 'Мини-апп',
          ),
        ],
      ),
    );
  }

  Widget _buildPencilFab(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final note = context.read<NotesProvider>().createNote();
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditorScreen(noteId: note.id)),
        );
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.purple.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(child: OnionIcons.pencilOnSquare(size: 26)),
      ),
    );
  }

  Widget _buildNotesTab(AppPalette palette) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (!provider.loaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.purple));
        }
        var results = provider.search(_query, onDate: _dateFilter);
        if (_tagFilter != null) {
          results = results.where((n) => n.tags.contains(_tagFilter)).toList();
        }
        final allTags = <String>{};
        for (final n in provider.notes) {
          allTags.addAll(n.tags);
        }
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset('assets/icon/app_icon.png', width: 34, height: 34),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('ONION',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: palette.ink)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: palette.purpleSoft,
                              borderRadius: BorderRadius.circular(AppRadii.button),
                            ),
                            child: Center(child: OnionIcons.settingsNut(size: 20, color: palette.ink)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildSearchRow(palette),
                    if (allTags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildTagRow(palette, allTags.toList()..sort()),
                    ],
                  ],
                ),
              ),
            ),
            if (results.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isEmpty && _dateFilter == null)
                          Image.asset('assets/images/mascot_sitting.png', width: 160),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty && _dateFilter == null
                              ? 'Заметок пока нет — нажмите карандаш, чтобы создать первую'
                              : 'Ничего не найдено',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: palette.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final note = results[i];
                      return NoteCard(
                        note: note,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditorScreen(noteId: note.id)),
                        ),
                        onLongPress: () => _confirmDelete(context, note),
                      );
                    },
                    childCount: results.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTagRow(AppPalette palette, List<String> tags) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final tag = tags[i];
          final selected = _tagFilter == tag;
          return GestureDetector(
            onTap: () => setState(() => _tagFilter = selected ? null : tag),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.purple : palette.purpleSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text('#$tag',
                  style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : palette.ink,
                      fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchRow(AppPalette palette) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Поиск по названию и тексту…',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: OnionIcons.search(color: palette.inkSoft),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dateFilter ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            setState(() => _dateFilter = picked);
          },
          onLongPress: () => setState(() => _dateFilter = null),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _dateFilter != null ? AppColors.purple : palette.purpleSoft,
              borderRadius: BorderRadius.circular(AppRadii.button),
            ),
            child: Center(
              child: OnionIcons.calendar(color: _dateFilter != null ? Colors.white : palette.inkSoft),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card)),
        title: const Text('Удалить заметку?'),
        content: Text(note.title.isEmpty ? 'Без названия' : note.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              context.read<NotesProvider>().deleteNote(note.id);
              Navigator.pop(ctx);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
