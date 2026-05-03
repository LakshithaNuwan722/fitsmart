class UserSubscription {
  final bool isPremium;
  final String plan;  // 'free', 'monthly', 'yearly'
  final DateTime? expiryDate;
  final int aiScansUsedToday;
  final int aiWorkoutsUsedToday;

  UserSubscription({
    required this.isPremium,
    required this.plan,
    this.expiryDate,
    required this.aiScansUsedToday,
    required this.aiWorkoutsUsedToday,
  });

  // Free tier limits
  static const int freeAIScansPerDay = 3;
  static const int freeAIWorkoutsPerDay = 2;

  bool get canScanMeal {
    if (isPremium) return true;
    return aiScansUsedToday < freeAIScansPerDay;
  }

  bool get canGenerateWorkout {
    if (isPremium) return true;
    return aiWorkoutsUsedToday < freeAIWorkoutsPerDay;
  }

  int get remainingScans {
    if (isPremium) return 999;
    return freeAIScansPerDay - aiScansUsedToday;
  }

  int get remainingWorkouts {
    if (isPremium) return 999;
    return freeAIWorkoutsPerDay - aiWorkoutsUsedToday;
  }
}