import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';

class WorkoutService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Add workout + update daily log
  Future<void> addWorkout(Workout workout) async {
    // Save workout
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .add(workout.toMap());

    // Update daily log workouts count
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('dailyLogs')
        .doc(today)
        .set({
      'date': today,
      'workoutsCompleted': FieldValue.increment(1),
      'caloriesBurned': FieldValue.increment(workout.caloriesBurned),
    }, SetOptions(merge: true));
  }

  // Get today's workouts
  Stream<List<Workout>> getTodaysWorkouts() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Workout.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Get recent workouts (last 7 days)
  Future<List<Workout>> getRecentWorkouts() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final dateStr = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .where('date', isGreaterThanOrEqualTo: dateStr)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Workout.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Delete workout + update daily log
  Future<void> deleteWorkout(String workoutId) async {
    // Get workout first to know calories burned
    final doc = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .doc(workoutId)
        .get();

    if (doc.exists) {
      final workout = Workout.fromMap(doc.data()!, doc.id);
      final dateStr = workout.date;

      // Delete workout
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .doc(workoutId)
          .delete();

      // Update daily log
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(dateStr)
          .set({
        'workoutsCompleted': FieldValue.increment(-1),
        'caloriesBurned': FieldValue.increment(-workout.caloriesBurned),
      }, SetOptions(merge: true));
    }
  }

  // Mark workout complete + update daily log
  Future<void> completeWorkout(String workoutId) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .doc(workoutId)
        .update({'completed': true});
  }

  // Get workouts count for specific date
  Future<int> getWorkoutsCountForDate(String dateStr) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .where('date', isEqualTo: dateStr)
        .get();
    return snapshot.docs.length;
  }
}