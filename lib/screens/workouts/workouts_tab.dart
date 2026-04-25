import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/workout_service.dart';
import '../../models/workout.dart';
import 'generate_workout_screen.dart';

class WorkoutsTab extends StatelessWidget {
  const WorkoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutService = WorkoutService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Workouts'),
        backgroundColor: AppTheme.background,
      ),
      body: StreamBuilder<List<Workout>>(
        stream: workoutService.getTodaysWorkouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final workouts = snapshot.data ?? [];

          if (workouts.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            itemBuilder: (context, index) {
              return _buildWorkoutCard(context, workouts[index], workoutService)
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 100 * index))
                  .slideY(begin: 0.2);
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => const GenerateWorkoutScreen())),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('AI Generate', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text('No workouts today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Let AI create a personalized workout!',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const GenerateWorkoutScreen())),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate AI Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout, WorkoutService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: workout.isAIGenerated ? AppTheme.primaryGradient : AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  workout.isAIGenerated ? Icons.auto_awesome_rounded : Icons.fitness_center_rounded,
                  color: Colors.white, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text('${workout.duration} min',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(width: 12),
                        Icon(Icons.local_fire_department_rounded, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 4),
                        Text('${workout.caloriesBurned} cal',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (workout.completed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('✅ Done',
                      style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Delete Workout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) await service.deleteWorkout(workout.id);
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, color: AppTheme.textSecondary.withOpacity(0.4), size: 18),
                ),
              ),
            ],
          ),
          if (workout.isAIGenerated) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('🤖 AI Generated',
                  style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
            ),
          ],
        ],
      ),
    );
  }
}