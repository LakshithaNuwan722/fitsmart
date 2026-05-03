import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/profile/profile_tab.dart';
import '../services/progress_service.dart' hide ProgressService;

class WaterTracker extends StatefulWidget {
  const WaterTracker({super.key});

  @override
  State<WaterTracker> createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  final _progressService = ProgressService();
  double _waterIntake = 0;
  final double _goal = 3.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWater();
  }

  Future<void> _loadWater() async {
    try {
      final log = await _progressService.getTodaysLog();
      if (mounted) {
        setState(() {
          _waterIntake = log!.waterIntake!;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWater(double amount) async {
    setState(() => _waterIntake += amount);
    await _progressService.updateWaterIntake(_waterIntake);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primary,
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
              Text(
                '${_waterIntake.toStringAsFixed(1)}L',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                ' / ${_goal.toStringAsFixed(0)}L',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
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

extension on Object? {
  double? get waterIntake => null;
}