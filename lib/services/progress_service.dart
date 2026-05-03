import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Get or create today's log
  Future<DailyLog> getTodaysLog() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .get();

      if (doc.exists && doc.data() != null) {
        return DailyLog.fromMap(doc.data()!);
      }

      // Document doesn't exist, create it
      final newLog = DailyLog(
        date: today,
        caloriesConsumed: 0,
        caloriesBurned: 0,
        waterIntake: 0,
        workoutsCompleted: 0,
      );

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .set(newLog.toMap());

      return newLog;
    } catch (e) {
      print('Error getting today log: $e');
      // Return default log if anything fails
      return DailyLog(
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        caloriesConsumed: 0,
        caloriesBurned: 0,
        waterIntake: 0,
        workoutsCompleted: 0,
      );
    }
  }

  // Update water intake
  Future<void> updateWaterIntake(double liters) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .set({
        'date': today,
        'waterIntake': liters,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating water: $e');
    }
  }

  // Log weight
  Future<void> logWeight(double weight) async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .set({
        'date': today,
        'weight': weight,
      }, SetOptions(merge: true));

      // Also update user profile
      await _firestore.collection('users').doc(_userId).update({
        'weight': weight,
      });
    } catch (e) {
      print('Error logging weight: $e');
    }
  }

  // Get last 7 days logs
  Future<List<DailyLog>> getWeeklyLogs() async {
    try {
      final logs = <DailyLog>[];

      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        try {
          final doc = await _firestore
              .collection('users')
              .doc(_userId)
              .collection('dailyLogs')
              .doc(dateStr)
              .get();

          if (doc.exists && doc.data() != null) {
            logs.add(DailyLog.fromMap(doc.data()!));
          } else {
            logs.add(DailyLog(
              date: dateStr,
              caloriesConsumed: 0,
              caloriesBurned: 0,
              waterIntake: 0,
              workoutsCompleted: 0,
            ));
          }
        } catch (e) {
          logs.add(DailyLog(
            date: dateStr,
            caloriesConsumed: 0,
            caloriesBurned: 0,
            waterIntake: 0,
            workoutsCompleted: 0,
          ));
        }
      }

      return logs;
    } catch (e) {
      print('Error getting weekly logs: $e');
      return [];
    }
  }

  // Get weekly calorie data from MEALS collection
  Future<List<DailyLog>> getWeeklyLogsFromMeals() async {
    try {
      final logs = <DailyLog>[];

      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        // Get total calories from meals for this date
        int totalCalories = 0;
        try {
          final mealsSnapshot = await _firestore
              .collection('users')
              .doc(_userId)
              .collection('meals')
              .where('date', isEqualTo: dateStr)
              .get();

          for (var doc in mealsSnapshot.docs) {
            totalCalories += (doc.data()['totalCalories'] ?? 0) as int;
          }
        } catch (e) {
          print('Error getting meals for $dateStr: $e');
        }

        // Get daily log for water and weight
        DailyLog log;
        try {
          final doc = await _firestore
              .collection('users')
              .doc(_userId)
              .collection('dailyLogs')
              .doc(dateStr)
              .get();

          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            log = DailyLog(
              date: dateStr,
              caloriesConsumed: totalCalories,
              caloriesBurned: (data['caloriesBurned'] ?? 0).toInt(),
              waterIntake: (data['waterIntake'] ?? 0).toDouble(),
              weight: data['weight']?.toDouble(),
              workoutsCompleted: (data['workoutsCompleted'] ?? 0).toInt(),
            );
          } else {
            log = DailyLog(
              date: dateStr,
              caloriesConsumed: totalCalories,
              caloriesBurned: 0,
              waterIntake: 0,
              workoutsCompleted: 0,
            );
          }
        } catch (e) {
          log = DailyLog(
            date: dateStr,
            caloriesConsumed: totalCalories,
            caloriesBurned: 0,
            waterIntake: 0,
            workoutsCompleted: 0,
          );
        }

        logs.add(log);
      }

      return logs;
    } catch (e) {
      print('Error getting weekly logs: $e');
      return [];
    }
  }

  // Get last 30 days weight logs
  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    try {
      final weights = <Map<String, dynamic>>[];

      for (int i = 29; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);

        try {
          final doc = await _firestore
              .collection('users')
              .doc(_userId)
              .collection('dailyLogs')
              .doc(dateStr)
              .get();

          if (doc.exists &&
              doc.data() != null &&
              doc.data()!['weight'] != null) {
            weights.add({
              'date': dateStr,
              'weight': (doc.data()!['weight'] as num).toDouble(),
            });
          }
        } catch (e) {
          // Skip this date
        }
      }

      return weights;
    } catch (e) {
      print('Error getting weight history: $e');
      return [];
    }
  }
}