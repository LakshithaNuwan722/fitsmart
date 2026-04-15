import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/food_recognition_service.dart';
import '../../services/meal_service.dart';
import '../../models/food_item.dart';
import '../../models/meal.dart';

class ScanMealScreen extends StatefulWidget {
  const ScanMealScreen({super.key});

  @override
  State<ScanMealScreen> createState() => _ScanMealScreenState();
}

class _ScanMealScreenState extends State<ScanMealScreen> {
  File? _image;
  List<FoodItem>? _recognizedFoods;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String _selectedMealType = 'lunch';

  final _foodService = FoodRecognitionService();
  final _mealService = MealService();

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _recognizedFoods = null;
      });
      await _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final foods = await _foodService.recognizeFood(_image!);
      setState(() => _recognizedFoods = foods);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _saveMeal() async {
    if (_recognizedFoods == null || _recognizedFoods!.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      // Calculate totals
      int totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var food in _recognizedFoods!) {
        totalCalories += food.calories;
        totalProtein += food.protein;
        totalCarbs += food.carbs;
        totalFat += food.fat;
      }

      // Save meal WITHOUT image (Storage not configured)
      final meal = Meal(
        id: '',
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        mealType: _selectedMealType,
        imageUrl: null,
        foodItems: _recognizedFoods!,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
        timestamp: Timestamp.now(),
      );

      await _mealService.addMeal(meal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meal saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 Scan Your Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: _image != null
                      ? DecorationImage(
                    image: FileImage(_image!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'Tap to capture or select food image',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🤖 AI will identify the food',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
                    : null,
              ),
            ),

            const SizedBox(height: 20),

            // Analyzing State
            if (_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🤖 AI is analyzing your food...',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Identifying items and calculating nutrition',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            // Results
            if (_recognizedFoods != null) ...[
              // Meal Type Selector
              const Text(
                'Meal Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['breakfast', 'lunch', 'dinner', 'snack']
                    .map((type) => ChoiceChip(
                  label: Text(
                    _getMealTypeEmoji(type) +
                        type[0].toUpperCase() +
                        type.substring(1),
                  ),
                  selected: _selectedMealType == type,
                  selectedColor: Colors.deepPurple.shade100,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMealType = type);
                    }
                  },
                ))
                    .toList(),
              ),

              const SizedBox(height: 20),

              // Detected Foods Header
              Row(
                children: [
                  const Text(
                    'Detected Foods',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _analyzeImage,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Re-scan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Food Items List
              ..._recognizedFoods!.map((food) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${food.calories} kcal',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${food.quantity} ${food.unit}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildMacroChip(
                              'Protein ${food.protein.toInt()}g',
                              Colors.blue),
                          const SizedBox(width: 8),
                          _buildMacroChip(
                              'Carbs ${food.carbs.toInt()}g',
                              Colors.orange),
                          const SizedBox(width: 8),
                          _buildMacroChip(
                              'Fat ${food.fat.toInt()}g',
                              Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 16),

              // Total Calories Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Calories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_recognizedFoods!.fold<int>(0, (sum, f) => sum + f.calories)} kcal',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMeal,
                  icon: _isSaving
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isSaving ? 'Saving...' : '✅ Save Meal',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color.withOpacity(0.8),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getMealTypeEmoji(String type) {
    switch (type) {
      case 'breakfast':
        return '🌅 ';
      case 'lunch':
        return '☀️ ';
      case 'dinner':
        return '🌙 ';
      case 'snack':
        return '🍪 ';
      default:
        return '🍽️ ';
    }
  }
}