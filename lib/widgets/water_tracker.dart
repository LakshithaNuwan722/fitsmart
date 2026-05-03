import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';

class WaterTracker extends StatefulWidget {
  const WaterTracker({super.key});

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  double _waterIntake = 0;
  final double _goal = 3.0;
  bool _isLoading = true;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get _userId => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  // Load directly from Firestore
  Future<void> _loadWater() async {
    try {
      setState(() => _isLoading = true);

      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(_today)
          .get();

      double water = 0;

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        water = (data['waterIntake'] ?? 0.0).toDouble();
        print('✅ Water loaded: ${water}L for $_today');
      } else {
        print('📝 No water log found for $_today - starting at 0');
        // Create today's document
        await _firestore
            .collection('users')
            .doc(_userId)
            .collection('dailyLogs')
            .doc(_today)
            .set({
          'date': _today,
          'waterIntake': 0.0,
          'caloriesConsumed': 0,
          'caloriesBurned': 0,
          'workoutsCompleted': 0,
        }, SetOptions(merge: true));
      }

      if (mounted) {
        setState(() {
          _waterIntake = water;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading water: $e');
      if (mounted) {
        setState(() {
          _waterIntake = 0;
          _isLoading = false;
        });
      }
    }
  }

  // Save directly to Firestore
  Future<void> _addWater(double amount) async {
    final newAmount = _waterIntake + amount;

    // Update UI immediately
    setState(() => _waterIntake = newAmount);

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('dailyLogs')
          .doc(_today)
          .set({
        'date': _today,
        'waterIntake': newAmount,
      }, SetOptions(merge: true));

      print('✅ Water saved: ${newAmount}L');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('💧', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  '${newAmount.toStringAsFixed(1)}L / ${_goal.toStringAsFixed(0)}L',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error saving water: $e');
      // Revert UI if save failed
      setState(() => _waterIntake = _waterIntake - amount);
    }
  }

  // Reset water (for testing)
  Future<void> _resetWater() async {
    setState(() => _waterIntake = 0);
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('dailyLogs')
        .doc(_today)
        .set({
      'waterIntake': 0.0,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2,
          ),
        ),
      );
    }

    final percent = (_waterIntake / _goal).clamp(0.0, 1.0);
    final glasses = (_waterIntake / 0.25).floor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Water Intake',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$glasses glasses today',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Refresh button
              GestureDetector(
                onTap: _loadWater,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_waterIntake.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    TextSpan(
                      text: '/${_goal.toStringAsFixed(0)}L',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: Colors.blue.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                _waterIntake >= _goal ? AppTheme.secondary : Colors.blue,
              ),
            ),
          ),

          // Goal achieved message
          if (_waterIntake >= _goal) ...[
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎉', style: TextStyle(fontSize: 16)),
                SizedBox(width: 4),
                Text(
                  'Daily goal achieved!',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Quick Add Buttons
          Row(
            children: [
              Expanded(child: _buildWaterBtn('🥤', '+250ml', 0.25)),
              const SizedBox(width: 8),
              Expanded(child: _buildWaterBtn('🫗', '+500ml', 0.5)),
              const SizedBox(width: 8),
              Expanded(child: _buildWaterBtn('🧴', '+1L', 1.0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterBtn(String emoji, String label, double amount) {
    return GestureDetector(
      onTap: () => _addWater(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}