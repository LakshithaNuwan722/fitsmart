import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLog {
  final String date;
  final int caloriesConsumed;
  final int caloriesBurned;
  final double waterIntake;
  final double? weight;
  final int workoutsCompleted;

  DailyLog({
    required this.date,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.waterIntake,
    this.weight,
    required this.workoutsCompleted,
  });

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      date: map['date'] ?? '',
      caloriesConsumed: (map['caloriesConsumed'] ?? 0).toInt(),
      caloriesBurned: (map['caloriesBurned'] ?? 0).toInt(),
      waterIntake: (map['waterIntake'] ?? 0).toDouble(),
      weight: map['weight']?.toDouble(),
      workoutsCompleted: (map['workoutsCompleted'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'caloriesConsumed': caloriesConsumed,
      'caloriesBurned': caloriesBurned,
      'waterIntake': waterIntake,
      'weight': weight,
      'workoutsCompleted': workoutsCompleted,
    };
  }
}