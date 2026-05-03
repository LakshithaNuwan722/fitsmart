import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/progress_service.dart';
import '../../utils/calorie_calculator.dart';
import '../../config/theme.dart';
import '../subscription/paywall_screen.dart';

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

  Widget _buildProfileView(Map<String, dynamic> data) {
    return Column(
      children: [
        // Profile Avatar Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.darkGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A1D3E).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                ),
                child: Center(
                  child: Text(
                    (data['name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['email'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

        const SizedBox(height: 24),

        // Settings / Stats Header
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Your Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ).animate().fadeIn(delay: 200.ms),
        ),
        const SizedBox(height: 12),

        // Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Goal',
                value: _getGoalName(data['goal'] ?? 'maintain'),
                icon: Icons.flag_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Daily Target',
                value: '${data['dailyCalorieTarget'] ?? 2000} kcal',
                icon: Icons.local_fire_department_rounded,
                color: AppTheme.accent,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Height',
                value: '${(data['height'] ?? 170).toInt()} cm',
                icon: Icons.height_rounded,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Weight',
                value: '${(data['weight'] ?? 70).toInt()} kg',
                icon: Icons.monitor_weight_rounded,
                color: const Color(0xFF56CCF2), // Blue
              ),
            ),
          ],
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Age',
                value: '${data['age'] ?? 20} yrs',
                icon: Icons.cake_rounded,
                color: const Color(0xFFFF9A56), // Orange
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                label: 'Activity',
                value: _getActivityName(data['activityLevel'] ?? 'moderate'),
                icon: Icons.directions_run_rounded,
                color: AppTheme.primaryDark,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

        const SizedBox(height: 32),

        // Actions
        _buildActionCard(
          icon: Icons.monitor_weight_rounded,
          label: 'Log Today\'s Weight',
          color: AppTheme.secondary,
          onTap: () => _showLogWeightDialog(),
        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),

        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.workspace_premium_rounded,
          label: 'Upgrade to Premium ⭐',
          color: const Color(0xFFFFB74D), // Amber
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
          ),
          textColor: Colors.white,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaywallScreen()),
            );
          },
        ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),

        const SizedBox(height: 12),

        _buildActionCard(
          icon: Icons.logout_rounded,
          label: 'Logout',
          color: AppTheme.accent,
          background: AppTheme.accent.withOpacity(0.1),
          onTap: () => FirebaseAuth.instance.signOut(),
        ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.1),
        
        const SizedBox(height: 24),
      ],
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
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Weight', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 72.5',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(controller.text);
              if (weight != null) {
                await _progressService.logWeight(weight);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Weight logged!'),
                      backgroundColor: AppTheme.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
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