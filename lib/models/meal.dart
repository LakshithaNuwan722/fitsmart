import 'package:cloud_firestore/cloud_firestore.dart';
import 'food_item.dart';

class Meal {
  final String id;
  final String date;
  final String mealType;
  final String? imageUrl;
  final List<FoodItem> foodItems;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final Timestamp timestamp;

  Meal({
    required this.id,
    required this.date,
    required this.mealType,
    this.imageUrl,
    required this.foodItems,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.timestamp,
  });

  factory Meal.fromMap(Map<String, dynamic> map, String id) {
    return Meal(
      id: id,
      date: map['date'] ?? '',
      mealType: map['mealType'] ?? 'snack',
      imageUrl: map['imageUrl'],
      foodItems: (map['foodItems'] as List<dynamic>?)
          ?.map((f) => FoodItem.fromJson(Map<String, dynamic>.from(f)))
          .toList() ??
          [],
      totalCalories: (map['totalCalories'] ?? 0).toInt(),
      totalProtein: (map['totalProtein'] ?? 0).toDouble(),
      totalCarbs: (map['totalCarbs'] ?? 0).toDouble(),
      totalFat: (map['totalFat'] ?? 0).toDouble(),
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'mealType': mealType,
      'imageUrl': imageUrl,
      'foodItems': foodItems.map((f) => f.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'timestamp': timestamp,
    };
  }
}