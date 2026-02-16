import 'package:flutter/material.dart';

class Palette {
  // Colores principales
  static const Color primary   = Color(0xFF1DA1F2); // #1DA1F2 (azul)
  static const Color secondary = Color(0xFF1DF2CB); // #1DF2CB (aqua)

  // Card / superficies (suaves para que combine con el fondo)
  static const Color card    = Color(0xFFEAF6F7);   // muy claro, frío
  static const Color fieldBg = Color(0xFFFFFFFF);   // blanco

  // Botones
  static const Color button    = Color(0xFF1DCBF2); // #1DCBF2 (celeste)
  static const Color secButton = Color(0xFF1DF2A4); // #1DF2A4 (menta)

  // Fondo (body) degradado
  static const Color gradientStart = Color(0xFF1DA1F2); // azul
  static const Color gradientEnd   = Color(0xFF1DF268); // verde

  // De uso general
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink   = Color(0xFF16324A); // texto oscuro azulado (para legibilidad)

  // Colores para estadísticas y gráficos
  static const Color statsSuccess = Color(0xFF1DF268); // verde
  static const Color statsWarning = Color(0xFFF59E0B); // warning estándar
  static const Color statsDanger  = Color(0xFFDC2626); // danger estándar
  static const Color statsNeutral = Color(0xFF0F172A); // neutral oscuro
}
