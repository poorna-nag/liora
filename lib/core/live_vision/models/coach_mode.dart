/// Phase 8 — AI Lifestyle Coach. A focus the companion adopts while observing
/// live, so the same Live Vision pipeline can specialize into cooking, study,
/// fitness or shopping help without any new pipeline.
enum CoachMode { general, cooking, study, fitness, shopping }

extension CoachModeInfo on CoachMode {
  String get label {
    switch (this) {
      case CoachMode.general:
        return 'Explore';
      case CoachMode.cooking:
        return 'Cooking';
      case CoachMode.study:
        return 'Study';
      case CoachMode.fitness:
        return 'Fitness';
      case CoachMode.shopping:
        return 'Shopping';
    }
  }

  /// Extra directive appended to the Live Vision instruction for this mode.
  /// Empty for [general] so behavior is unchanged unless a mode is chosen.
  String get directive {
    switch (this) {
      case CoachMode.general:
        return '';
      case CoachMode.cooking:
        return 'COACH MODE: Cooking. Act like a friendly cook beside the user. '
            'Identify ingredients, tools and dishes in view; suggest what they '
            'could make, practical next steps, quantities, timings and safety '
            '(heat, knives). Keep it encouraging and concrete.';
      case CoachMode.study:
        return 'COACH MODE: Study. Act like a patient tutor. When notes, books '
            'or screens are visible, point out gaps, unclear points or mistakes, '
            'suggest what to revise next, and quiz gently. Be supportive.';
      case CoachMode.fitness:
        return 'COACH MODE: Fitness. Act like a careful trainer. Comment on '
            'posture, form and setup you can see, and give safe, simple cues. '
            'If you cannot clearly see the movement, ask them to reframe. Never '
            'give medical advice.';
      case CoachMode.shopping:
        return 'COACH MODE: Shopping. Act like a savvy friend. For products in '
            'view, comment on apparent value, quality cues, and possible '
            'alternatives or things to check (price, size, ingredients, labels). '
            'Be honest and practical.';
    }
  }
}
