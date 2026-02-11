import 'package:flutter/material.dart';

import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/theme/app_typography.dart';
import 'package:habit_tracker/core/theme/semantic_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const ColorScheme colorScheme = ColorScheme(
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
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onLight,
      onSurfaceVariant: AppColors.onLightVariant,
      outline: AppColors.outlineLight,
      outlineVariant: AppColors.outlineVariantLight,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2A322D),
      onInverseSurface: AppColors.onDark,
      inversePrimary: Color(0xFFAED9BE),
      surfaceContainerHighest: AppColors.surfaceVariantLight,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      semanticColors: HabitSemanticColors.light,
    );
  }

  static ThemeData dark() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brandDark,
      onPrimary: Color(0xFF003825),
      primaryContainer: AppColors.brandContainerDark,
      onPrimaryContainer: AppColors.brandContainer,
      secondary: Color(0xFFA7D0B1),
      onSecondary: Color(0xFF123824),
      secondaryContainer: Color(0xFF2B4F39),
      onSecondaryContainer: Color(0xFFC7ECCE),
      tertiary: Color(0xFFC2C98B),
      onTertiary: Color(0xFF2D3208),
      tertiaryContainer: Color(0xFF43481D),
      onTertiaryContainer: Color(0xFFE1E4AF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onDark,
      onSurfaceVariant: AppColors.onDarkVariant,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.outlineVariantDark,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.surfaceLight,
      onInverseSurface: AppColors.onLight,
      inversePrimary: AppColors.brand,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      semanticColors: HabitSemanticColors.dark,
    );
  }

  static ThemeData _buildTheme({
    required final ColorScheme colorScheme,
    required final HabitSemanticColors semanticColors,
  }) {
    final ThemeData base = ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      cardTheme: CardThemeData(color: colorScheme.surfaceContainerHighest),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainerHighest,
        textStyle: base.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.secondaryContainer,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: base.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondaryContainer,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        disabledActionTextColor: colorScheme.onInverseSurface.withValues(
          alpha: 0.6,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[semanticColors],
    );
  }
}
