import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class Workout {
  final String id;
  final String date;
  final String type;
  final String name;
  final int duration;
  final int caloriesBurned;
  final bool isAIGenerated;
  final List<Exercise> exercises;
  final bool completed;
  final String? difficulty;
  final String? trainerTips;
  final List<String>? warmup;
  final List<String>? cooldown;
  final Timestamp timestamp;

  Workout({
    required this.id,
    required this.date,
    required this.type,
    required this.name,
    required this.duration,
    required this.caloriesBurned,
    required this.isAIGenerated,
    required this.exercises,
    required this.completed,
    this.difficulty,
    this.trainerTips,
    this.warmup,
    this.cooldown,
    required this.timestamp,
  });

  factory Workout.fromMap(Map<String, dynamic> map, String id) {
    // Safe int converter
    int safeInt(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    return Workout(
      id: id,
      date: map['date']?.toString() ?? '',
      type: map['type']?.toString() ?? 'strength',
      name: map['name']?.toString() ?? 'Workout',
      duration: safeInt(map['duration'], 30),
      caloriesBurned: safeInt(map['caloriesBurned'], 0),
      isAIGenerated: map['isAIGenerated'] ?? false,
      exercises: (map['exercises'] as List<dynamic>?)
          ?.map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
          .toList() ??
          [],
      completed: map['completed'] ?? false,
      difficulty: map['difficulty']?.toString(),
      trainerTips: map['trainerTips']?.toString(),
      warmup: (map['warmup'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      cooldown: (map['cooldown'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'type': type,
      'name': name,
      'duration': duration,
      'caloriesBurned': caloriesBurned,
      'isAIGenerated': isAIGenerated,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'completed': completed,
      'difficulty': difficulty,
      'trainerTips': trainerTips,
      'warmup': warmup,
      'cooldown': cooldown,
      'timestamp': timestamp,
    };
  }
}