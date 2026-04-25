import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/workout_ai_service.dart';
import '../../services/workout_service.dart';
import '../../services/subscription_service.dart';
import '../../models/workout.dart';
import '../../models/exercise.dart';
import '../subscription/paywall_screen.dart';
import 'active_workout_screen.dart';

class GenerateWorkoutScreen extends StatefulWidget {
  const GenerateWorkoutScreen({super.key});

  @override
  State<GenerateWorkoutScreen> createState() => _GenerateWorkoutScreenState();
}

class _GenerateWorkoutScreenState extends State<GenerateWorkoutScreen> {
  String _focusArea = 'full_body';
  int _duration = 30;
  String _equipment = 'none';
  Map<String, dynamic>? _generatedWorkout;
  bool _isGenerating = false;
  bool _isSaving = false;

  final _aiService = WorkoutAIService();
  final _workoutService = WorkoutService();
  final _subscriptionService = SubscriptionService();

  final _focusAreas = [
    {'key': 'full_body', 'label': 'Full Body', 'icon': '🏋️', 'color': AppTheme.primary},
    {'key': 'upper_body', 'label': 'Upper Body', 'icon': '💪', 'color': Colors.blue},
    {'key': 'lower_body', 'label': 'Lower Body', 'icon': '🦵', 'color': Colors.green},
    {'key': 'core', 'label': 'Core', 'icon': '🎯', 'color': Colors.orange},
    {'key': 'cardio', 'label': 'Cardio', 'icon': '🏃', 'color': AppTheme.accent},
  ];

  final _equipmentOptions = [
    {'key': 'none', 'label': 'No Equipment', 'icon': '🤸', 'desc': 'Bodyweight only'},
    {'key': 'dumbbells', 'label': 'Dumbbells', 'icon': '🏋️', 'desc': 'Basic weights'},
    {'key': 'full_gym', 'label': 'Full Gym', 'icon': '🏢', 'desc': 'All equipment'},
  ];

  // ─── Generate Workout ────────────────────────────────────────────
  Future<void> _generateWorkout() async {
    final subscription = await _subscriptionService.getSubscription();

    if (!subscription.canGenerateWorkout) {
      if (mounted) {
        _showUpgradeDialog();
      }
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedWorkout = null;
    });

    try {
      final userProfile = await _aiService.getUserProfile();
      final recentWorkouts = await _workoutService.getRecentWorkouts();
      final recentNames = recentWorkouts.map((w) => w.name).toList();

      final workout = await _aiService.generateWorkout(
        focusArea: _focusArea,
        durationMinutes: _duration,
        equipment: _equipment,
        userProfile: userProfile,
        recentWorkoutNames: recentNames,
      );

      setState(() => _generatedWorkout = workout);
      await _subscriptionService.recordAIWorkout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Generation failed: $e'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  // ─── Save and Start ──────────────────────────────────────────────
  Future<void> _saveAndStartWorkout() async {
    if (_generatedWorkout == null) return;
    setState(() => _isSaving = true);

    try {
      final exercises = (_generatedWorkout!['exercises'] as List)
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final warmup = (_generatedWorkout!['warmup'] as List?)
          ?.map((e) => e.toString())
          .toList();

      final cooldown = (_generatedWorkout!['cooldown'] as List?)
          ?.map((e) => e.toString())
          .toList();

      final workout = Workout(
        id: '',
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        type: _generatedWorkout!['type'] ?? 'strength',
        name: _generatedWorkout!['workout_name'] ?? 'AI Workout',
        duration: (_generatedWorkout!['estimated_duration'] ?? _duration).toInt(),
        caloriesBurned: (_generatedWorkout!['estimated_calories_burned'] ?? 200).toInt(),
        isAIGenerated: true,
        exercises: exercises,
        completed: false,
        difficulty: _generatedWorkout!['difficulty'],
        trainerTips: _generatedWorkout!['trainer_tips'],
        warmup: warmup,
        cooldown: cooldown,
        timestamp: Timestamp.now(),
      );

      await _workoutService.addWorkout(workout);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveWorkoutScreen(
              workoutName: workout.name,
              exercises: exercises,
              warmup: warmup ?? [],
              cooldown: cooldown ?? [],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.accent),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('⭐', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Limit Reached', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: const Text(
          'You\'ve used all free AI workouts today.\nUpgrade to Premium for unlimited generations!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const PaywallScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade ⭐'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('AI Workout'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription Banner
            FutureBuilder(
              future: _subscriptionService.getSubscription(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final sub = snapshot.data!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: sub.isPremium
                        ? Colors.amber.withOpacity(0.08)
                        : AppTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sub.isPremium
                          ? Colors.amber.withOpacity(0.3)
                          : AppTheme.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(sub.isPremium ? '⭐' : '🤖', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sub.isPremium
                              ? 'Premium - Unlimited Workouts'
                              : '${sub.remainingWorkouts} workout(s) remaining today',
                          style: TextStyle(
                            color: sub.isPremium ? Colors.amber[700] : AppTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!sub.isPremium)
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (context) => const PaywallScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Upgrade',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn();
              },
            ),

            // Focus Area
            const Text('Focus Area',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _focusAreas.length,
                itemBuilder: (context, index) {
                  final area = _focusAreas[index];
                  final isSelected = _focusArea == area['key'];
                  final color = area['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() => _focusArea = area['key'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 90,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.1) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))] : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(area['icon'] as String, style: const TextStyle(fontSize: 28)),
                          const SizedBox(height: 6),
                          Text(
                            area['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? color : AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),

            const SizedBox(height: 28),

            // Duration
            Container(
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer_rounded, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Duration',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$_duration min',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.primary.withOpacity(0.15),
                      thumbColor: AppTheme.primary,
                      overlayColor: AppTheme.primary.withOpacity(0.1),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _duration.toDouble(),
                      min: 15,
                      max: 60,
                      divisions: 3,
                      onChanged: (v) => setState(() => _duration = v.toInt()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['15', '30', '45', '60'].map((m) =>
                        Text('${m}m', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))).toList(),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 20),

            // Equipment
            const Text('Equipment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            ..._equipmentOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _equipment == option['key'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _equipment = option['key'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.06) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? AppTheme.cardShadow : [],
                    ),
                    child: Row(
                      children: [
                        Text(option['icon'] as String, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option['label'] as String,
                                  style: TextStyle(fontWeight: FontWeight.w600,
                                      color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
                              Text(option['desc'] as String,
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : Colors.grey.shade300, width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : const SizedBox(width: 14, height: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 300 + 100 * index)).slideX(begin: 0.2);
            }),

            const SizedBox(height: 28),

            // Generate Button
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateWorkout,
                icon: _isGenerating
                    ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Icon(Icons.auto_awesome_rounded, size: 22),
                label: Text(
                  _isGenerating ? 'Creating your workout...' : 'Generate Workout ✨',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

            const SizedBox(height: 24),

            // Generated Workout
            if (_generatedWorkout != null) ...[
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.darkGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A1D3E).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text('AI Generated',
                                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _generatedWorkout!['workout_name'] ?? 'Workout',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoPill(Icons.timer_rounded, '${_generatedWorkout!['estimated_duration']} min'),
                        const SizedBox(width: 10),
                        _buildInfoPill(Icons.local_fire_department_rounded, '${_generatedWorkout!['estimated_calories_burned']} cal'),
                        const SizedBox(width: 10),
                        _buildInfoPill(Icons.speed_rounded, '${_generatedWorkout!['difficulty']}'),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 20),

              // Warmup
              if (_generatedWorkout!['warmup'] != null) ...[
                _buildSectionCard(
                  title: '🔥 Warm-up',
                  color: Colors.orange,
                  items: (_generatedWorkout!['warmup'] as List).map((e) => e.toString()).toList(),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2),
                const SizedBox(height: 16),
              ],

              // Exercises
              const Text('💪 Exercises',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              ...(_generatedWorkout!['exercises'] as List).asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = Map<String, dynamic>.from(entry.value);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(exercise['name'] ?? '',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildTag('${exercise['sets']} sets', AppTheme.primary),
                          _buildTag('${exercise['reps']} reps', Colors.blue),
                          if ((exercise['suggested_weight_kg'] ?? 0) > 0)
                            _buildTag('${exercise['suggested_weight_kg']} kg', Colors.green),
                          _buildTag('${exercise['rest_seconds']}s rest', Colors.orange),
                        ],
                      ),
                      if (exercise['notes'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Text('💡', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(exercise['notes'],
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: 200 + 80 * index)).slideX(begin: 0.2);
              }),

              const SizedBox(height: 12),

              // Cooldown
              if (_generatedWorkout!['cooldown'] != null) ...[
                _buildSectionCard(
                  title: '❄️ Cool-down',
                  color: Colors.blue,
                  items: (_generatedWorkout!['cooldown'] as List).map((e) => e.toString()).toList(),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                const SizedBox(height: 16),
              ],

              // Trainer Tips
              if (_generatedWorkout!['trainer_tips'] != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Trainer Tips',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(_generatedWorkout!['trainer_tips'],
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isGenerating ? null : _generateWorkout,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Regenerate', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppTheme.greenGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00D9A6).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAndStartWorkout,
                        icon: _isSaving
                            ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(_isSaving ? 'Saving...' : 'Start Workout 🚀',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 600.ms),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────
  Widget _buildInfoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}