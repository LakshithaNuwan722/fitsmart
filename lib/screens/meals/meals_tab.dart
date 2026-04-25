import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/meal_service.dart';
import '../../models/meal.dart';
import 'add_meal_screen.dart';
import 'scan_meal_screen.dart';
import 'package:intl/intl.dart';

class MealsTab extends StatelessWidget {
  const MealsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final mealService = MealService();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Meals'),
        backgroundColor: AppTheme.background,
      ),
      body: StreamBuilder<List<Meal>>(
        stream: mealService.getTodaysMeals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final meals = snapshot.data ?? [];

          if (meals.isEmpty) return _buildEmptyState(context);

          int totalCalories = 0;
          double totalProtein = 0, totalCarbs = 0, totalFat = 0;
          for (var meal in meals) {
            totalCalories = totalCalories + meal.totalCalories;
            totalProtein += meal.totalProtein;
            totalCarbs += meal.totalCarbs;
            totalFat += meal.totalFat;
          }

          return Column(
            children: [
              // Summary
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D9A6).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text("Today's Nutrition",
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('$totalCalories kcal',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacro('Protein', '${totalProtein.toInt()}g'),
                        _buildMacro('Carbs', '${totalCarbs.toInt()}g'),
                        _buildMacro('Fat', '${totalFat.toInt()}g'),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

              // List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    return _buildMealCard(context, meals[index], mealService)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 100 * index))
                        .slideX(begin: 0.2);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ScanMealScreen())),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddMealScreen())),
            backgroundColor: AppTheme.secondary,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
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
            child: const Icon(Icons.restaurant_outlined, size: 48, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text('No meals logged today',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Scan food or add manually',
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
                  MaterialPageRoute(builder: (context) => const ScanMealScreen())),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Scan with AI'),
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

  Widget _buildMacro(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, Meal meal, MealService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _getMealColor(meal.mealType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_getMealIcon(meal.mealType), color: _getMealColor(meal.mealType), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealType[0].toUpperCase() + meal.mealType.substring(1),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  meal.foodItems.map((f) => f.name).join(', '),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('h:mm a').format(meal.timestamp.toDate()),
                  style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${meal.totalCalories}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
              const Text('kcal', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Delete Meal?'),
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
              if (confirm == true) await service.deleteMeal(meal.id);
            },
            child: Icon(Icons.close_rounded, color: AppTheme.textSecondary.withOpacity(0.4), size: 18),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(String type) {
    switch (type) {
      case 'breakfast': return Icons.free_breakfast_rounded;
      case 'lunch': return Icons.lunch_dining_rounded;
      case 'dinner': return Icons.dinner_dining_rounded;
      case 'snack': return Icons.cookie_rounded;
      default: return Icons.restaurant_rounded;
    }
  }

  Color _getMealColor(String type) {
    switch (type) {
      case 'breakfast': return Colors.orange;
      case 'lunch': return AppTheme.secondary;
      case 'dinner': return AppTheme.primary;
      case 'snack': return Colors.purple;
      default: return Colors.grey;
    }
  }
}