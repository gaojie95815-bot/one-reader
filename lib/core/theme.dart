import 'package:flutter/material.dart';

/// 一套简单的 Material 3 主题，练手时想换配色只改 seedColor 即可。
ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF2F6F4F),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
