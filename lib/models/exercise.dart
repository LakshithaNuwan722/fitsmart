class Exercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final int restSeconds;
  final String? notes;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
    required this.restSeconds,
    this.notes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    // Safe int converter
    int safeInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Safe double converter
    double safeDouble(dynamic value, double defaultValue) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Exercise(
      name: json['name']?.toString() ?? 'Unknown',
      sets: safeInt(json['sets'], 3),
      reps: safeInt(json['reps'], 10),
      weight: safeDouble(
        json['suggested_weight_kg'] ?? json['weight'],
        0.0,
      ),
      restSeconds: safeInt(
        json['rest_seconds'] ?? json['restSeconds'],
        60,
      ),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'restSeconds': restSeconds,
      'notes': notes,
    };
  }
}