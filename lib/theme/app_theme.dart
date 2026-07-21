import 'package:flutter/material.dart';

/// Палитра и тема в духе "чистого Apple": много белого, мягкий фиолетовый
/// акцент, крупные скругления, лёгкие тени вместо жёстких границ.
class AppColors {
  static const purple = Color(0xFF7C5CFF);
  static const purpleDeep = Color(0xFF5B3DEB);
  static const purpleSoft = Color(0xFFEDE7FF);
  static const background = Color(0xFFFBFAFF);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1C1B22);
  static const inkSoft = Color(0xFF8A8798);
  static const highlighterYellow = Color(0x66FFE066);
  static const divider = Color(0xFFEFEDF6);
  static const danger = Color(0xFFE0526B);
}

class AppColorsDark {
  static const background = Color(0xFF14121C);
  static const surface = Color(0xFF1E1B29);
  static const ink = Color(0xFFF2F0F8);
  static const inkSoft = Color(0xFF9E9AB0);
  static const divider = Color(0xFF2C2838);
  static const purpleSoft = Color(0xFF362B5C);
}

/// Набор цветов "хрома" приложения, зависящий от текущей темы. Не путать с
/// анимированным фоном отдельной заметки — это отдельная история.
class AppPalette {
  final Color background;
  final Color surface;
  final Color ink;
  final Color inkSoft;
  final Color divider;
  final Color purpleSoft;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.divider,
    required this.purpleSoft,
  });

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    ink: AppColors.ink,
    inkSoft: AppColors.inkSoft,
    divider: AppColors.divider,
    purpleSoft: AppColors.purpleSoft,
  );

  static const dark = AppPalette(
    background: AppColorsDark.background,
    surface: AppColorsDark.surface,
    ink: AppColorsDark.ink,
    inkSoft: AppColorsDark.inkSoft,
    divider: AppColorsDark.divider,
    purpleSoft: AppColorsDark.purpleSoft,
  );

  static AppPalette of(bool isDark) => isDark ? dark : light;
}

class AppRadii {
  static const card = 28.0;
  static const button = 22.0;
  static const chip = 16.0;
  static const sheet = 32.0;
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
        primary: AppColors.purple,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.purpleSoft.withOpacity(0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.inkSoft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColors.inkSoft,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.dark,
        primary: AppColors.purple,
        surface: AppColorsDark.surface,
      ),
      scaffoldBackgroundColor: AppColorsDark.background,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsDark.background,
        foregroundColor: AppColorsDark.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColorsDark.ink,
        displayColor: AppColorsDark.ink,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.purpleSoft.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColorsDark.inkSoft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedItemColor: AppColors.purple,
        unselectedItemColor: AppColorsDark.inkSoft,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
