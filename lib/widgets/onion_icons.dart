import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

/// Все иконки приложения — настоящие SVG (переданы как строки в
/// flutter_svg), а не растровые PNG и не Material-иконки.
class OnionIcons {
  static Widget pencilOnSquare({double size = 26}) => SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 19.2 5.9 15.6C6 15.15 6.22 14.74 6.55 14.41L15.6 5.36C16.2 4.76 17.17 4.76 17.77 5.36L18.87 6.46C19.47 7.06 19.47 8.03 18.87 8.63L9.82 17.68C9.49 18.01 9.08 18.23 8.63 18.34L5 19.2Z"
    fill="white" fill-opacity="0.16" stroke="white" stroke-width="1.5" stroke-linejoin="round"/>
  <path d="M14.3 6.66 17.57 9.93" stroke="white" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M6.55 14.41 9.82 17.68" stroke="white" stroke-width="1.3" stroke-linecap="round" opacity="0.7"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget checkMark({double size = 16, Color color = Colors.white}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 12.5 10 17.5 19 6.5" stroke="${_hex(color)}" stroke-width="2.6"
    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget arrowBack({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M15 5 8 12l7 7" stroke="${_hex(color)}" stroke-width="2"
    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget arrowForward({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9 5l7 7-7 7" stroke="${_hex(color)}" stroke-width="2"
    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget exitArrow({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M11 19l-7-7 7-7" stroke="${_hex(color)}" stroke-width="2"
    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <path d="M4 12h16" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget magicWand({double size = 22, Color color = const Color(0xFF7C5CFF)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 20 15 9" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
  <path d="M17 3v3M17 9v3M13 6h3M20 6h1" stroke="${_hex(color)}" stroke-width="1.6" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget search({double size = 20, Color color = const Color(0xFF8A8798)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="11" cy="11" r="6.5" stroke="${_hex(color)}" stroke-width="2"/>
  <path d="M20 20 15.8 15.8" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget calendar({double size = 20, Color color = const Color(0xFF8A8798)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="5.5" width="16" height="15" rx="4" stroke="${_hex(color)}" stroke-width="2"/>
  <path d="M4 10h16M8 3v4M16 3v4" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget checkboxTool({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="4" width="16" height="16" rx="6" stroke="${_hex(color)}" stroke-width="2"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget fontTool({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7 19 11.5 6h1L17 19" stroke="${_hex(color)}" stroke-width="2"
    stroke-linecap="round" stroke-linejoin="round" fill="none"/>
  <path d="M8.4 15h7.2" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget highlighterTool({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="m7 15 6.5-9.5 4 3L11 18l-5 1 1-4Z" stroke="${_hex(color)}" stroke-width="1.8"
    stroke-linejoin="round" fill="none"/>
  <path d="M4 21h9" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget colorFillTool({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 12 13 5l6 6-7 7-6-6Z" stroke="${_hex(color)}" stroke-width="1.8" stroke-linejoin="round" fill="none"/>
  <path d="M3 19c1-1.4 2.6-1.4 3.6 0 1 1.4 2.6 1.4 3.6 0" stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget imageTool({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3.5" y="5" width="17" height="14" rx="4" stroke="${_hex(color)}" stroke-width="2"/>
  <circle cx="9" cy="10" r="1.6" stroke="${_hex(color)}" stroke-width="1.6"/>
  <path d="m5 17 5-4.5 3.5 3L18 11l1.5 2.5" stroke="${_hex(color)}" stroke-width="1.8" stroke-linejoin="round" fill="none"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget backgroundTool({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="8" stroke="${_hex(color)}" stroke-width="2"/>
  <path d="M12 4v16M4 12h16" stroke="${_hex(color)}" stroke-width="1.4" stroke-linecap="round" opacity="0.5"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget road({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="6" cy="6" r="2.4" stroke="${_hex(color)}" stroke-width="1.8"/>
  <circle cx="18" cy="18" r="2.4" stroke="${_hex(color)}" stroke-width="1.8"/>
  <path d="M8 8 16 16" stroke="${_hex(color)}" stroke-width="1.8" stroke-dasharray="3 3"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget home({double size = 22, Color color = const Color(0xFF8A8798)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 11 12 4l8 7" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M6 10v9h12v-9" stroke="${_hex(color)}" stroke-width="2" stroke-linejoin="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget settings({double size = 22, Color color = const Color(0xFF8A8798)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 8.4a3.6 3.6 0 1 0 0 7.2 3.6 3.6 0 0 0 0-7.2Z" stroke="${_hex(color)}" stroke-width="1.8"/>
  <path d="M12 2.6v2.1M12 19.3v2.1M21.4 12h-2.1M4.7 12H2.6M18.36 5.64l-1.49 1.49M7.13 16.87l-1.49 1.49M18.36 18.36l-1.49-1.49M7.13 7.13 5.64 5.64"
    stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M12 5.7a.9.9 0 0 1-.9-.9v-.7a.9.9 0 0 1 1.8 0v.7a.9.9 0 0 1-.9.9ZM12 19.9a.9.9 0 0 1-.9-.9v-.7a.9.9 0 0 1 1.8 0v.7a.9.9 0 0 1-.9.9Z"
    fill="${_hex(color)}"/>
</svg>
''',
        width: size,
        height: size,
      );

  /// Солнце — используется в переключателе светлой/тёмной темы.
  static Widget sun({double size = 20, Color color = const Color(0xFFFFB020)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="4.4" fill="${_hex(color)}"/>
  <path d="M12 2.6v2.4M12 19v2.4M21.4 12H19M5 12H2.6M18.5 5.5l-1.7 1.7M7.2 16.8l-1.7 1.7M18.5 18.5l-1.7-1.7M7.2 7.2 5.5 5.5"
    stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  /// Луна — вторая половина переключателя темы.
  static Widget moon({double size = 20, Color color = const Color(0xFFC9CDFF)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M20 14.2A8.5 8.5 0 1 1 9.8 4a6.8 6.8 0 0 0 10.2 10.2Z" fill="${_hex(color)}"/>
</svg>
''',
        width: size,
        height: size,
      );

  /// Буква "A" с цветной подложкой — инструмент "Цвет текста".
  static Widget textColorTool({double size = 22, Color color = const Color(0xFF1C1B22), Color accent = const Color(0xFF7C5CFF)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7 16.5 11 6h2l4 10.5" stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M8.4 12.6h7.2" stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round"/>
  <rect x="5" y="18.4" width="14" height="3.2" rx="1.6" fill="${_hex(accent)}"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget alignLeft({double size = 18, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3" y="5" width="14" height="4" rx="1.4" fill="${_hex(color)}"/>
  <rect x="3" y="11" width="18" height="4" rx="1.4" fill="${_hex(color)}" opacity="0.35"/>
  <rect x="3" y="17" width="10" height="2.4" rx="1.2" fill="${_hex(color)}" opacity="0.35"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget alignCenterImg({double size = 18, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="5" y="5" width="14" height="4" rx="1.4" fill="${_hex(color)}"/>
  <rect x="3" y="11" width="18" height="4" rx="1.4" fill="${_hex(color)}" opacity="0.35"/>
  <rect x="7" y="17" width="10" height="2.4" rx="1.2" fill="${_hex(color)}" opacity="0.35"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget alignRight({double size = 18, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="7" y="5" width="14" height="4" rx="1.4" fill="${_hex(color)}"/>
  <rect x="3" y="11" width="18" height="4" rx="1.4" fill="${_hex(color)}" opacity="0.35"/>
  <rect x="11" y="17" width="10" height="2.4" rx="1.2" fill="${_hex(color)}" opacity="0.35"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget sizeDot({double size = 18, Color color = const Color(0xFF1C1B22), double fill = 0.5}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="${_hex(color)}" stroke-width="1.6"/>
  <circle cx="12" cy="12" r="${(9 * fill).toStringAsFixed(1)}" fill="${_hex(color)}"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget pasteCodeTool({double size = 20, Color color = const Color(0xFF7C5CFF)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="6" y="4" width="12" height="17" rx="2.4" stroke="${_hex(color)}" stroke-width="1.7"/>
  <path d="M9.4 4a1.4 1.4 0 0 1 1.4-1.4h2.4A1.4 1.4 0 0 1 14.6 4" stroke="${_hex(color)}" stroke-width="1.7"/>
  <path d="M9 12.4 11 14.4 15.3 9.6" stroke="${_hex(color)}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget offlineTool({double size = 20, Color color = const Color(0xFF7C5CFF)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6.6 9.4a8.2 8.2 0 0 1 10.8 0" stroke="${_hex(color)}" stroke-width="1.7" stroke-linecap="round"/>
  <path d="M9.3 12.6a4.4 4.4 0 0 1 5.4 0" stroke="${_hex(color)}" stroke-width="1.7" stroke-linecap="round"/>
  <circle cx="12" cy="16.3" r="1.3" fill="${_hex(color)}"/>
  <path d="M3.5 5.5 20.5 18.5" stroke="${_hex(color)}" stroke-width="1.7" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget infoTool({double size = 20, Color color = const Color(0xFF7C5CFF)}) => SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="8.4" stroke="${_hex(color)}" stroke-width="1.7"/>
  <circle cx="12" cy="8.4" r="1" fill="${_hex(color)}"/>
  <path d="M12 11.4v5.4" stroke="${_hex(color)}" stroke-width="1.7" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget aiPromptTool({double size = 20, Color color = const Color(0xFF7C5CFF)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 3.6 13.4 8.2 18 9.6 13.4 11 12 15.6 10.6 11 6 9.6 10.6 8.2 12 3.6Z"
    fill="${_hex(color)}"/>
  <path d="M18.4 14.4 19.1 16.6 21.3 17.3 19.1 18 18.4 20.2 17.7 18 15.5 17.3 17.7 16.6 18.4 14.4Z"
    fill="${_hex(color)}" opacity="0.7"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget plus({double size = 20, Color color = const Color(0xFF1C1B22)}) => SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 5v14M5 12h14" stroke="${_hex(color)}" stroke-width="2" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  static Widget trash({double size = 20, Color color = const Color(0xFFE0526B)}) => SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4.5 7h15" stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M9 7V5.2c0-.66.54-1.2 1.2-1.2h3.6c.66 0 1.2.54 1.2 1.2V7" stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M6.5 7 7.3 19c.05.9.8 1.6 1.7 1.6h6c.9 0 1.65-.7 1.7-1.6L17.5 7" stroke="${_hex(color)}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M10.2 10.5v6.3M13.8 10.5v6.3" stroke="${_hex(color)}" stroke-width="1.6" stroke-linecap="round"/>
</svg>
''',
        width: size,
        height: size,
      );

  /// Раздел "Мини-приложения" в нижнем меню — квадратики-иконки.
  static Widget appsGrid({double size = 22, Color color = const Color(0xFF8A8798)}) => SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="3.5" y="3.5" width="7" height="7" rx="2.2" stroke="${_hex(color)}" stroke-width="1.7"/>
  <rect x="13.5" y="3.5" width="7" height="7" rx="2.2" stroke="${_hex(color)}" stroke-width="1.7"/>
  <rect x="3.5" y="13.5" width="7" height="7" rx="2.2" stroke="${_hex(color)}" stroke-width="1.7"/>
  <rect x="13.5" y="13.5" width="7" height="7" rx="2.2" stroke="${_hex(color)}" stroke-width="1.7"/>
</svg>
''',
        width: size,
        height: size,
      );

  /// Гайка-восьмиугольник для кнопки настроек в правом верхнем углу
  /// (перенесена из нижнего меню).
  static Widget settingsNut({double size = 22, Color color = const Color(0xFF1C1B22)}) =>
      SvgPicture.string(
        '''
<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M9 3.6h6l4.4 4.4v6l-4.4 4.4H9l-4.4-4.4v-6L9 3.6Z"
    stroke="${_hex(color)}" stroke-width="1.7" stroke-linejoin="round"/>
  <circle cx="12" cy="12" r="3.1" stroke="${_hex(color)}" stroke-width="1.7"/>
</svg>
''',
        width: size,
        height: size,
      );

  static String _hex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}
