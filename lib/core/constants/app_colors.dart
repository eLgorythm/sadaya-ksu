import 'package:flutter/material.dart';

/// Palet warna resmi aplikasi Sadaya.
///
/// Sumber: dokumen analisis bagian UI/UX (hijau tua = utama, emas = aksen,
/// krem = background). Dipisah ke satu file agar tema konsisten di seluruh
/// modul dan perubahan warna cukup dilakukan di satu tempat.
class AppColors {
  AppColors._();

  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color accentGold = Color(0xFFD4A017);
  static const Color backgroundCream = Color(0xFFFAF7F0);
  static const Color negativeRed = Color(0xFFD32F2F);
  static const Color positiveGreen = Color(0xFF2E7D32);
  static const Color textGray = Color(0xFF9E9E9E);

  // Palet redesign brand (dokumen redesign_ui_ux): hijau natural
  static const Color brand50 = Color(0xFFF0FDF4);
  static const Color brand100 = Color(0xFFDCFCE7);
  static const Color brand500 = Color(0xFF22C55E);
  static const Color brand600 = Color(0xFF16A34A);
  static const Color brand700 = Color(0xFF15803D);
  static const Color brand800 = Color(0xFF166534);
  static const Color brand900 = Color(0xFF14532D);
  static const Color brandDark = Color(0xFF0F391F);
}
