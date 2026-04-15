import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('Meals 🍽️'),
      ),
      body: StreamBuilder<List<Meal>>(
        stream: mealService.getTodaysMeals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final meals = snapshot.data ?? [];

          if (meals.isEmpty) {
            return _buildEmptyState(context);
          }

          // Calculate totals
          int totalCalories = 0;
          double totalProtein = 0;
          double totalCarbs = 0;
          double totalFat = 0;

          for (var meal in meals) {
            totalCalories = totalCalories + meal.totalCalories;
            totalProtein += meal.totalProtein;
            totalCarbs += meal.totalCarbs;
            totalFat += meal.totalFat;
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Today's Nutrition",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalCalories kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacro('Protein', '${totalProtein.toInt()}g',
                            Colors.blue.shade200),
                        _buildMacro('Carbs', '${totalCarbs.toInt()}g',
                            Colors.orange.shade200),
                        _buildMacro('Fat', '${totalFat.toInt()}g',
                            Colors.red.shade200),
                      ],
                    ),
                  ],
                ),
              ),

              // Meals List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    return _buildMealCard(context, meals[index], mealService);
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
          // AI Scan Button
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ScanMealScreen()),
              );
            },
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Manual Add Button
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddMealScreen()),
              );
            },
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
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
          Icon(Icons.restaurant_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No meals logged today',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap buttons below to add meals',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ScanMealScreen()),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('📸 Scan with AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacro(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMealCard(
      BuildContext context, Meal meal, MealService mealService) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Meal Type Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getMealTypeColor(meal.mealType).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getMealTypeIcon(meal.mealType),
                color: _getMealTypeColor(meal.mealType),
                size: 28,
              ),
            ),

            const SizedBox(width: 12),

            // Meal Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.mealType[0].toUpperCase() +
                        meal.mealType.substring(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meal.foodItems.map((f) => f.name).join(', '),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(meal.timestamp.toDate()),
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),

            // Calories
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${meal.totalCalories}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text('kcal',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),

            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Meal?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await mealService.deleteMeal(meal.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}