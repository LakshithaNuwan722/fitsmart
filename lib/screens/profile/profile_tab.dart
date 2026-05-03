import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/progress_service.dart';
import '../../utils/calorie_calculator.dart';
import '../../config/theme.dart';
import '../subscription/paywall_screen.dart';
import 'export_screen.dart';
import 'package:intl/intl.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _progressService = ProgressService();
  bool _isEditing = false;

  // Edit controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.background,
                elevation: 0,
                toolbarHeight: 70,
                title: Text(
                  _isEditing ? 'Edit Profile' : 'Profile',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _isEditing = !_isEditing);
                      },
                    ),
                  ),
                ],
              ),

              // Body
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (!_isEditing)
                      _buildProfileView(data)
                    else
                      _buildEditView(data, uid),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Replace the weight stat card with StreamBuilder:

  Widget _buildProfileView(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              (data['name'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data['name'] ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            data['email'] ?? '',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 24),

          // Stats Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: '🎯 Goal',
                  value: _getGoalName(data['goal'] ?? 'maintain'),
                  icon: Icons.flag_rounded,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: '🔥 Daily Target',
                  value: '${data['dailyCalorieTarget'] ?? 2000} kcal',
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: '📏 Height',
                  value: '${(data['height'] ?? 170).toInt()} cm',
                  icon: Icons.height_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final weight = (userData?['weight'] ?? data['weight'] ?? 70).toDouble();

                    return _buildStatCard(
                      label: '⚖️ Weight',
                      value: '${weight.toStringAsFixed(1)} kg',
                      icon: Icons.monitor_weight_rounded,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: '🎂 Age',
                  value: '${data['age'] ?? 20} years',
                  icon: Icons.cake_rounded,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: '🏃 Activity',
                  value: _getActivityName(data['activityLevel'] ?? 'moderate'),
                  icon: Icons.directions_run_rounded,
                  color: Colors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Log Weight Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showLogWeightDialog(),
              icon: const Icon(Icons.monitor_weight_rounded),
              label: const Text('Log Today\'s Weight'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Export Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export Reports ⭐'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Upgrade Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaywallScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.star_rounded),
              label: const Text('Upgrade to Premium ⭐'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    Color? background,
    LinearGradient? gradient,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: background ?? AppTheme.surface,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gradient == null ? color.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: gradient == null ? color : Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textColor ?? AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditView(Map<String, dynamic> data, String uid) {
    if (_nameController.text.isEmpty && data['name'] != null) {
      _nameController.text = data['name'] ?? '';
      _ageController.text = '${data['age'] ?? 20}';
      _heightController.text = '${(data['height'] ?? 170).toInt()}';
      _weightController.text = '${(data['weight'] ?? 70).toInt()}';
      _gender = data['gender'] ?? 'male';
      _activityLevel = data['activityLevel'] ?? 'moderate';
      _goal = data['goal'] ?? 'maintain';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Name', _nameController, Icons.person_rounded),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Age', _ageController, Icons.cake_rounded,
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                'Gender',
                _gender,
                ['male', 'female'],
                (v) => setState(() => _gender = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Height (cm)', _heightController, Icons.height_rounded,
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField('Weight (kg)', _weightController, Icons.monitor_weight_rounded,
                  keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'Goal',
          _goal,
          ['lose_weight', 'gain_muscle', 'maintain'],
          (v) => setState(() => _goal = v!),
          displayMap: {
            'lose_weight': '🔥 Lose Weight',
            'gain_muscle': '💪 Gain Muscle',
            'maintain': '⚖️ Maintain',
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          'Activity Level',
          _activityLevel,
          ['sedentary', 'light', 'moderate', 'active', 'very_active'],
          (v) => setState(() => _activityLevel = v!),
          displayMap: {
            'sedentary': 'Sedentary',
            'light': 'Light',
            'moderate': 'Moderate',
            'active': 'Active',
            'very_active': 'Very Active',
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => _saveProfile(uid),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppTheme.primary.withOpacity(0.4),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown(
      String label, String value, List<String> items, Function(String?) onChanged,
      {Map<String, String>? displayMap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              displayMap?[item] ?? item[0].toUpperCase() + item.substring(1),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _saveProfile(String uid) async {
    try {
      final weight = double.tryParse(_weightController.text) ?? 70;
      final height = double.tryParse(_heightController.text) ?? 170;
      final age = int.tryParse(_ageController.text) ?? 20;

      final bmr = CalorieCalculator.calculateBMR(
        weightKg: weight,
        heightCm: height,
        age: age,
        gender: _gender,
      );
      final tdee = CalorieCalculator.calculateTDEE(bmr, _activityLevel);
      final dailyTarget = CalorieCalculator.getDailyTarget(tdee, _goal);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'age': age,
        'gender': _gender,
        'height': height,
        'weight': weight,
        'activityLevel': _activityLevel,
        'goal': _goal,
        'dailyCalorieTarget': dailyTarget,
      });

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated!'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showLogWeightDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('⚖️', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Log Weight'),
          ],
        ),
        content: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'e.g. 72.5',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () async {
                final weight = double.tryParse(controller.text);
                if (weight == null || weight <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid weight'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Save weight
                await _saveWeight(weight);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ New separate save weight method
  Future<void> _saveWeight(double weight) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // ✅ Save to BOTH places
      // 1. Save to user profile (shows in stats card)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'weight': weight});

      // 2. Save to dailyLogs (shows in progress chart)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dailyLogs')
          .doc(today)
          .set({
        'date': today,
        'weight': weight,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Weight logged: ${weight.toStringAsFixed(1)} kg ✅'),
              ],
            ),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      print('✅ Weight saved: ${weight}kg to profile and dailyLogs/$today');
    } catch (e) {
      print('❌ Error saving weight: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save weight: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getGoalName(String goal) {
    switch (goal) {
      case 'lose_weight': return 'Lose Weight';
      case 'gain_muscle': return 'Gain Muscle';
      case 'maintain': return 'Maintain';
      default: return goal;
    }
  }

  String _getActivityName(String level) {
    switch (level) {
      case 'sedentary': return 'Sedentary';
      case 'light': return 'Light';
      case 'moderate': return 'Moderate';
      case 'active': return 'Active';
      case 'very_active': return 'Very Active';
      default: return level;
    }
  }
}

class ProgressService {
  Future<void> logWeight(double weight) async {}

  Future<Object?> getTodaysLog() async {}

  Future<void> updateWaterIntake(double waterIntake) async {}
}