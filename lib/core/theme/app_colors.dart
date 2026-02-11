import 'package:flutter/material.dart';

/// Static palette tokens used to compose [ThemeData] and semantic colors.
abstract final class AppColors {
  static const Color brand = Color(0xFF1C7C54);
  static const Color brandContainer = Color(0xFFC8F5DD);
  static const Color brandDark = Color(0xFFAED9BE);
  static const Color brandContainerDark = Color(0xFF005139);

  static const Color positive = Color(0xFF2E7D32);
  static const Color negative = Color(0xFFC62828);
  static const Color warning = Color(0xFFEF6C00);
  static const Color positiveDark = Color(0xFF2E7D32);
  static const Color negativeDark = Color(0xFFFF8A80);
  static const Color warningDark = Color(0xFFFFB74D);

  static const Color surfaceLight = Color(0xFFF7F7F5);
  static const Color surfaceVariantLight = Color(0xFFE8EAE6);
  static const Color outlineLight = Color(0xFF6F7973);
  static const Color outlineVariantLight = Color(0xFFBFC9C1);

  static const Color surfaceDark = Color(0xFF111513);
  static const Color surfaceVariantDark = Color(0xFF222926);
  static const Color outlineDark = Color(0xFF8A938D);
  static const Color outlineVariantDark = Color(0xFF404943);

  static const Color onLight = Color(0xFF161D18);
  static const Color onLightVariant = Color(0xFF404943);
  static const Color onDark = Color(0xFFF2F4F1);
  static const Color onDarkVariant = Color(0xFFC0C9C2);
}
