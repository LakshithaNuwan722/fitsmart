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
    return Exercise(
      name: json['name'] ?? 'Unknown',
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      weight: (json['suggested_weight_kg'] ?? json['weight'] ?? 0).toDouble(),
      restSeconds: json['rest_seconds'] ?? json['restSeconds'] ?? 60,
      notes: json['notes'],
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