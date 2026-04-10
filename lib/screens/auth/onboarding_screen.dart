import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final _activities = {
    'sedentary': 'Sedentary (desk job)',
    'light': 'Light (1-2 days/week)',
    'moderate': 'Moderate (3-5 days/week)',
    'active': 'Active (6-7 days/week)',
    'very_active': 'Very Active (athlete)',
  };

  final _goals = {
    'lose_weight': '🔥 Lose Weight',
    'gain_muscle': '💪 Gain Muscle',
    'maintain': '⚖️ Maintain Weight',
  };

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final bmr = CalorieCalculator.calculateBMR(
        weightKg: _weight,
        heightCm: _height,
        age: _age,
        gender: _gender,
      );
      final tdee = CalorieCalculator.calculateTDEE(bmr, _activityLevel);
      final dailyTarget = CalorieCalculator.getDailyTarget(tdee, _goal);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'age': _age,
        'gender': _gender,
        'height': _height,
        'weight': _weight,
        'activityLevel': _activityLevel,
        'goal': _goal,
        'dailyCalorieTarget': dailyTarget,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(),
          ),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Colors.deepPurple
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildBasicInfoPage(),
                _buildActivityPage(),
                _buildGoalPage(),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _currentPage < 2 ? 'Next' : 'Complete Setup',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Basic Info',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tell us about yourself',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),

          const Text('Gender', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'male'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gender == 'male'
                          ? Colors.deepPurple.shade50
                          : Colors.grey[100],
                      border: Border.all(
                        color: _gender == 'male'
                            ? Colors.deepPurple
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.male, size: 40,
                            color: _gender == 'male'
                                ? Colors.deepPurple
                                : Colors.grey),
                        const SizedBox(height: 4),
                        const Text('Male'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gender = 'female'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gender == 'female'
                          ? Colors.deepPurple.shade50
                          : Colors.grey[100],
                      border: Border.all(
                        color: _gender == 'female'
                            ? Colors.deepPurple
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.female, size: 40,
                            color: _gender == 'female'
                                ? Colors.deepPurple
                                : Colors.grey),
                        const SizedBox(height: 4),
                        const Text('Female'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text('Age: $_age years',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _age.toDouble(),
            min: 13, max: 80,
            divisions: 67,
            label: '$_age',
            onChanged: (v) => setState(() => _age = v.toInt()),
          ),

          const SizedBox(height: 16),

          Text('Height: ${_height.toInt()} cm',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _height,
            min: 120, max: 220,
            divisions: 100,
            label: '${_height.toInt()} cm',
            onChanged: (v) => setState(() => _height = v),
          ),

          const SizedBox(height: 16),

          Text('Weight: ${_weight.toInt()} kg',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Slider(
            value: _weight,
            min: 30, max: 200,
            divisions: 170,
            label: '${_weight.toInt()} kg',
            onChanged: (v) => setState(() => _weight = v),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Activity Level',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('How active are you?',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ..._activities.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _activityLevel = entry.key),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _activityLevel == entry.key
                        ? Colors.deepPurple.shade50
                        : Colors.grey[100],
                    border: Border.all(
                      color: _activityLevel == entry.key
                          ? Colors.deepPurple
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _activityLevel == entry.key
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: _activityLevel == entry.key
                            ? Colors.deepPurple
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(entry.value,
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Goal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('What do you want to achieve?',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          ..._goals.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _goal = entry.key),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _goal == entry.key
                        ? Colors.deepPurple.shade50
                        : Colors.grey[100],
                    border: Border.all(
                      color: _goal == entry.key
                          ? Colors.deepPurple
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _goal == entry.key
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _goal == entry.key
                            ? Colors.deepPurple
                            : Colors.grey,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(entry.value,
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}