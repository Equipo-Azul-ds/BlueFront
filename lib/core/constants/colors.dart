import 'package:flutter/material.dart';

// Paleta azul del Equipo Azul
class AppColor {
  // Tonalidad principal (deep blue) — usar para AppBar, botones principales
  static const Color primary = Color(0xFF0D47A1);
  // Tonalidad secundaria (mid blue) — acentos y elementos interactivos
  static const Color secundary = Color(0xFF1976D2);
  // Color de acento más claro y vibrante
  static const Color accent = Color(0xFF29B6F6);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFEF5350);
  // Fondo suave para que los elementos azules destaquen
  static const Color background = Color(0xFFF4F7FB);
  // Tarjetas ligeramente azuladas
  static const Color card = Color(0xFFE3F2FD);
  // Color de texto/íconos sobre primary
  static const Color onPrimary = Colors.white;
}

// Crea un MaterialColor (swatch) a partir de un Color puro.
MaterialColor createMaterialColor(Color color) {
  final strengths = <double>[.05];
  final swatch = <int, Color>{};
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;

  for (var i = 1; i < 10; i++) {
    strengths.add(0.1 * i);
  }
  for (var strength in strengths) {
    final ds = 0.5 - strength;
    swatch[(strength * 1000).round()] = Color.fromRGBO(
      r + ((ds < 0 ? r : (255 - r)) * ds).round(),
      g + ((ds < 0 ? g : (255 - g)) * ds).round(),
      b + ((ds < 0 ? b : (255 - b)) * ds).round(),
      1,
    );
  }
  return MaterialColor(color.toARGB32(), swatch);
}