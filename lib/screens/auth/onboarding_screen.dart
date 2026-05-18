import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../utils/calorie_calculator.dart';
import '../home/dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  int _age = 20;
  String _gender = 'male';
  double _height = 170;
  double _weight = 70;
  String _activityLevel = 'moderate';
  String _goal = 'maintain';

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final bmr = CalorieCalculator.calculateBMR(
        weightKg: _weight, heightCm: _height, age: _age, gender: _gender,
      );
      final tdee = CalorieCalculator.calculateTDEE(bmr, _activityLevel);
      final dailyTarget = CalorieCalculator.getDailyTarget(tdee, _goal);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'age': _age, 'gender': _gender, 'height': _height,
        'weight': _weight, 'activityLevel': _activityLevel,
        'goal': _goal, 'dailyCalorieTarget': dailyTarget,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _saveProfile();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _previousPage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: List.generate(3, (index) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: index <= _currentPage
                                  ? AppTheme.primary
                                  : AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_currentPage + 1}/3',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildBasicInfoPage(),
                  _buildActivityPage(),
                  _buildGoalPage(),
                ],
              ),
            ),

            // Next Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.buttonShadow,
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                    _currentPage < 2 ? 'Continue' : 'Complete Setup ✨',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About You', style: Theme.of(context).textTheme.headlineMedium)
              .animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 4),
          const Text('Tell us about yourself', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),

          // Gender
          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGenderCard('male', Icons.male, 'Male')),
              const SizedBox(width: 12),
              Expanded(child: _buildGenderCard('female', Icons.female, 'Female')),
            ],
          ),

          const SizedBox(height: 28),

          // Age
          _buildSliderCard('Age', '$_age years', Icons.cake_rounded, Colors.pink,
            Slider(
              value: _age.toDouble(), min: 13, max: 80, divisions: 67,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _age = v.toInt()),
            ),
          ),

          const SizedBox(height: 16),

          // Height
          _buildSliderCard('Height', '${_height.toInt()} cm', Icons.height_rounded, Colors.blue,
            Slider(
              value: _height, min: 120, max: 220, divisions: 100,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _height = v),
            ),
          ),

          const SizedBox(height: 16),

          // Weight
          _buildSliderCard('Weight', '${_weight.toInt()} kg', Icons.monitor_weight_rounded, Colors.green,
            Slider(
              value: _weight, min: 30, max: 200, divisions: 170,
              activeColor: AppTheme.primary,
              onChanged: (v) => setState(() => _weight = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    final activities = [
      {'key': 'sedentary', 'title': 'Sedentary', 'desc': 'Little or no exercise', 'icon': '🪑'},
      {'key': 'light', 'title': 'Light', 'desc': '1-2 days/week', 'icon': '🚶'},
      {'key': 'moderate', 'title': 'Moderate', 'desc': '3-5 days/week', 'icon': '🏃'},
      {'key': 'active', 'title': 'Active', 'desc': '6-7 days/week', 'icon': '💪'},
      {'key': 'very_active', 'title': 'Very Active', 'desc': 'Athlete level', 'icon': '🏆'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Level', style: Theme.of(context).textTheme.headlineMedium)
              .animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 4),
          const Text('How active are you?', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ...activities.asMap().entries.map((entry) {
            final index = entry.key;
            final activity = entry.value;
            final isSelected = _activityLevel == activity['key'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _activityLevel = activity['key']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? AppTheme.cardShadow : [],
                  ),
                  child: Row(
                    children: [
                      Text(activity['icon']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity['title']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              activity['desc']!,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
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
                            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                            width: 2,
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
            ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.2);
          }),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    final goals = [
      {'key': 'lose_weight', 'title': 'Lose Weight', 'desc': 'Burn fat & get lean', 'icon': '🔥', 'color': Colors.orange},
      {'key': 'gain_muscle', 'title': 'Gain Muscle', 'desc': 'Build strength & size', 'icon': '💪', 'color': Colors.blue},
      {'key': 'maintain', 'title': 'Stay Fit', 'desc': 'Maintain current shape', 'icon': '⚖️', 'color': Colors.green},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Goal', style: Theme.of(context).textTheme.headlineMedium)
              .animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 4),
          const Text('What do you want to achieve?', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ...goals.asMap().entries.map((entry) {
            final index = entry.key;
            final goal = entry.value;
            final isSelected = _goal == goal['key'];
            final color = goal['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => setState(() => _goal = goal['key'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                    )
                        : null,
                    color: isSelected ? null : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 6))]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Text(goal['icon'] as String, style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal['title'] as String,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? color : AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              goal['desc'] as String,
                              style: const TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? color : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : const SizedBox(width: 16, height: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 200 * index)).slideY(begin: 0.3);
          }),
        ],
      ),
    );
  }

  Widget _buildGenderCard(String value, IconData icon, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard(String label, String value, IconData icon, Color color, Widget slider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}