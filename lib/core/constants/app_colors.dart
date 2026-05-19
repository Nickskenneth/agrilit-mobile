import 'package:flutter/material.dart';

class AppColors {
  // Primary — hijau pertanian
  static const Color primary = Color(0xFF16A34A);
  static const Color primaryLight = Color(0xFFDCFCE7);
  static const Color primaryDark = Color(0xFF14532D);

  // Komoditas
  static const Color cabai = Color(0xFFEF4444); // merah
  static const Color kentang = Color(0xFFEAB308); // kuning
  static const Color jagung = Color(0xFFF97316); // oranye

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  static Color commodityColor(String commodity) {
    switch (commodity) {
      case 'cabai':
        return cabai;
      case 'kentang':
        return kentang;
      case 'jagung':
        return jagung;
      default:
        return primary;
    }
  }
}
