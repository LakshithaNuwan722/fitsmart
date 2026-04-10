class CalorieCalculator {
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (gender == 'male') {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      return (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }
  }

  static double calculateTDEE(double bmr, String activityLevel) {
    final multipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };
    return bmr * (multipliers[activityLevel] ?? 1.55);
  }

  static int getDailyTarget(double tdee, String goal) {
    switch (goal) {
      case 'lose_weight':
        return (tdee - 500).round();
      case 'gain_muscle':
        return (tdee + 300).round();
      case 'maintain':
        return tdee.round();
      default:
        return tdee.round();
    }
  }
}