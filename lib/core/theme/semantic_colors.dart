import 'package:flutter/material.dart';

@immutable
class HabitSemanticColors extends ThemeExtension<HabitSemanticColors> {
  const HabitSemanticColors({
    required this.positive,
    required this.negative,
    required this.warning,
  });

  final Color positive;
  final Color negative;
  final Color warning;

  @override
  HabitSemanticColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
  }) {
    return HabitSemanticColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
    );
  }

  @override
  HabitSemanticColors lerp(
    covariant ThemeExtension<HabitSemanticColors>? other,
    double t,
  ) {
    if (other is! HabitSemanticColors) {
      return this;
    }

    return HabitSemanticColors(
      positive: Color.lerp(positive, other.positive, t) ?? positive,
      negative: Color.lerp(negative, other.negative, t) ?? negative,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
    );
  }
}

extension SemanticColorsLookup on BuildContext {
  HabitSemanticColors get semanticColors {
    return Theme.of(this).extension<HabitSemanticColors>()!;
  }
}
