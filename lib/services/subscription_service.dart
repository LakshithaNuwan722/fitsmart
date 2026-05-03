import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  // Check subscription status
  Future<UserSubscription> getSubscription() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();

      final data = userDoc.data() ?? {};
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Get today's usage
      final usageDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .get();

      final usageData = usageDoc.data() ?? {};

      // Check if premium
      bool isPremium = false;
      DateTime? expiryDate;

      if (data['subscriptionExpiry'] != null) {
        expiryDate = (data['subscriptionExpiry'] as Timestamp).toDate();
        isPremium = expiryDate.isAfter(DateTime.now());
      }

      return UserSubscription(
        isPremium: isPremium,
        plan: isPremium ? (data['subscriptionPlan'] ?? 'monthly') : 'free',
        expiryDate: expiryDate,
        aiScansUsedToday: (usageData['aiScansUsed'] ?? 0).toInt(),
        aiWorkoutsUsedToday: (usageData['aiWorkoutsUsed'] ?? 0).toInt(),
      );
    } catch (e) {
      return UserSubscription(
        isPremium: false,
        plan: 'free',
        aiScansUsedToday: 0,
        aiWorkoutsUsedToday: 0,
      );
    }
  }

  // Increment AI scan usage
  Future<void> recordAIScan() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .set({
        'date': today,
        'aiScansUsed': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error recording scan: $e');
    }
  }

  // Increment AI workout usage
  Future<void> recordAIWorkout() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(today)
          .set({
        'date': today,
        'aiWorkoutsUsed': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error recording workout: $e');
    }
  }

  // Activate subscription (after purchase verification)
  Future<void> activateSubscription(String plan) async {
    try {
      DateTime expiry;
      if (plan == 'monthly') {
        expiry = DateTime.now().add(const Duration(days: 30));
      } else {
        expiry = DateTime.now().add(const Duration(days: 365));
      }

      await _firestore.collection('users').doc(_userId).update({
        'subscriptionPlan': plan,
        'subscriptionExpiry': Timestamp.fromDate(expiry),
        'isPremium': true,
      });
    } catch (e) {
      print('Error activating subscription: $e');
    }
  }
  Future<bool> isPremiumUser() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .get();

      final data = userDoc.data() ?? {};

      // Check expiry date
      if (data['subscriptionExpiry'] != null) {
        final expiry = (data['subscriptionExpiry'] as Timestamp).toDate();
        return expiry.isAfter(DateTime.now());
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}