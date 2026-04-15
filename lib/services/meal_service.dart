import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal.dart';
import 'package:intl/intl.dart';

class MealService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Add meal
  Future<void> addMeal(Meal meal) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .add(meal.toMap());
  }

  // Get today's meals
  Stream<List<Meal>> getTodaysMeals() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Meal.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Delete meal
  Future<void> deleteMeal(String mealId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .doc(mealId)
        .delete();
  }

  // Get today's total calories
  Future<int> getTodaysTotalCalories() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('meals')
        .where('date', isEqualTo: today)
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      final meal = Meal.fromMap(doc.data(), doc.id);
      total += meal.totalCalories;
    }
    return total;
  }
}