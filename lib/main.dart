import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/mini_apps_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/roads_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  runApp(const OnionApp());
}

class OnionApp extends StatelessWidget {
  const OnionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotesProvider()..load()),
        ChangeNotifierProvider(create: (_) => RoadsProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => MiniAppsProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'ONION',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('ru'),
            supportedLocales: const [Locale('ru'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
