import 'package:flutter/material.dart';

import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_typography.dart';
import 'package:habit_tracker/core/theme/semantic_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.brand,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brandContainer,
      onPrimaryContainer: AppColors.onLight,
      secondary: Color(0xFF44664F),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFC7ECCE),
      onSecondaryContainer: AppColors.onLight,
      tertiary: Color(0xFF5B5D32),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE1E4AF),
      onTertiaryContainer: AppColors.onLight,
      error: AppColors.negative,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: AppColors.surface,
      onSurface: AppColors.onLight,
      onSurfaceVariant: Color(0xFF404943),
      outline: AppColors.outline,
      outlineVariant: Color(0xFFBFC9C1),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2A322D),
      onInverseSurface: AppColors.onDark,
      inversePrimary: Color(0xFFAED9BE),
      surfaceContainerHighest: AppColors.surfaceVariant,
    );

    final base = ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      extensions: const <ThemeExtension<dynamic>>[
        HabitSemanticColors(
          positive: AppColors.positive,
          negative: AppColors.negative,
          warning: AppColors.warning,
        ),
      ],
    );
  }
}
