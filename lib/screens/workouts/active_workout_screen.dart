import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../models/exercise.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutName;
  final List<Exercise> exercises;
  final List<String> warmup;
  final List<String> cooldown;

  const ActiveWorkoutScreen({
    super.key,
    required this.workoutName,
    required this.exercises,
    required this.warmup,
    required this.cooldown,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _seconds = 0;
  Timer? _timer;
  bool _isResting = false;
  int _restSeconds = 0;
  final List<bool> _completedExercises = [];

  @override
  void initState() {
    super.initState();
    _completedExercises.addAll(List.generate(widget.exercises.length, (_) => false));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        if (_isResting && _restSeconds > 0) {
          _restSeconds--;
          if (_restSeconds == 0) _isResting = false;
        }
      });
    });
  }

  void _completeSet() {
    final currentExercise = widget.exercises[_currentExerciseIndex];
    if (_currentSet < currentExercise.sets) {
      setState(() {
        _currentSet++;
        _isResting = true;
        _restSeconds = currentExercise.restSeconds;
      });
    } else {
      setState(() {
        _completedExercises[_currentExerciseIndex] = true;
        if (_currentExerciseIndex < widget.exercises.length - 1) {
          _currentExerciseIndex++;
          _currentSet = 1;
        } else {
          _timer?.cancel();
          _showCompletionDialog();
        }
      });
    }
  }

  void _showCompletionDialog() {
    final minutes = _seconds ~/ 60;
    final secs = _seconds % 60;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9A6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.celebration_rounded, size: 40, color: Colors.white),
              ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              const Text('Workout Complete! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('Great job! Keep up the momentum!',
                  style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompletionStat('⏱️', '${minutes}m ${secs}s', 'Duration'),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  _buildCompletionStat('💪', '${widget.exercises.length}', 'Exercises'),
                  Container(width: 1, height: 40, color: Colors.grey.shade200),
                  _buildCompletionStat('🔥', '${_getTotalSets()}', 'Total Sets'),
                ],
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done! 💪', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTotalSets() {
    return widget.exercises.fold<int>(0, (sum, e) => sum + e.sets);
  }

  Widget _buildCompletionStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ],
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentExercise = widget.exercises[_currentExerciseIndex];
    final progress = (_currentExerciseIndex + 1) / widget.exercises.length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showExitDialog(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.workoutName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        Text('Exercise ${_currentExerciseIndex + 1} of ${widget.exercises.length}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_formatTime(_seconds),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  minHeight: 6,
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Current Exercise Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: _isResting ? AppTheme.blueGradient : AppTheme.darkGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: (_isResting ? Colors.blue : const Color(0xFF1A1D3E)).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: _isResting
                          ? Column(
                        children: [
                          Text('😮‍💨', style: const TextStyle(fontSize: 40))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
                          const SizedBox(height: 12),
                          Text('REST', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), letterSpacing: 4)),
                          const SizedBox(height: 8),
                          Text('$_restSeconds',
                              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('seconds', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6))),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() {
                              _isResting = false;
                              _restSeconds = 0;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Skip Rest →',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ).animate().fadeIn()
                          : Column(
                        children: [
                          Text(currentExercise.name,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatCircle('SET', '$_currentSet/${currentExercise.sets}', AppTheme.secondary),
                              _buildStatCircle('REPS', '${currentExercise.reps}', Colors.amber),
                              if (currentExercise.weight > 0)
                                _buildStatCircle('KG', '${currentExercise.weight}', Colors.orange),
                            ],
                          ),
                          if (currentExercise.notes != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Text('💡', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(currentExercise.notes!,
                                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ).animate().fadeIn(),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

                    const SizedBox(height: 24),

                    // Complete Set Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: _isResting ? null : AppTheme.greenGradient,
                        color: _isResting ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: _isResting
                            ? []
                            : [BoxShadow(color: const Color(0xFF00D9A6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))],
                      ),
                      child: ElevatedButton(
                        onPressed: _isResting ? null : _completeSet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text(
                          _isResting ? 'Resting... ($_restSeconds s)' : '✅ Complete Set $_currentSet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _isResting ? Colors.grey[600] : Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Exercise List
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('All Exercises',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 12),

                    ...widget.exercises.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ex = entry.value;
                      final isCurrent = i == _currentExerciseIndex;
                      final isDone = _completedExercises[i];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppTheme.primary.withOpacity(0.08)
                              : isDone
                              ? AppTheme.secondary.withOpacity(0.06)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrent
                              ? Border.all(color: AppTheme.primary.withOpacity(0.3))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTheme.secondary
                                    : isCurrent
                                    ? AppTheme.primary
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: isDone
                                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                    : isCurrent
                                    ? const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white)
                                    : Text('${i + 1}',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(ex.name,
                                  style: TextStyle(
                                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                                    color: isDone ? AppTheme.secondary : AppTheme.textPrimary,
                                  )),
                            ),
                            Text('${ex.sets}×${ex.reps}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCircle(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Workout?'),
        content: const Text('Your progress will not be saved.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              _timer?.cancel();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
            child: const Text('End Workout'),
          ),
        ],
      ),
    );
  }
}