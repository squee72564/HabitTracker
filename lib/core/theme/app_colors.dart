import 'package:flutter/material.dart';

/// Static palette tokens used to compose [ThemeData] and semantic colors.
abstract final class AppColors {
  static const Color brand = Color(0xFF1C7C54);
  static const Color brandContainer = Color(0xFFC8F5DD);

  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF6C00);

  static const Color surface = Color(0xFFF7F7F5);
  static const Color surfaceVariant = Color(0xFFE8EAE6);
  static const Color outline = Color(0xFF6F7973);

  static const Color onLight = Color(0xFF161D18);
  static const Color onDark = Color(0xFFF2F4F1);
}
