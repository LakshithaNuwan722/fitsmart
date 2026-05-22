import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/progress_service.dart';
import '../../utils/calorie_calculator.dart';
import '../subscription/paywall_screen.dart';
import 'change_password_screen.dart';
import 'export_screen.dart';

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
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Icon(
                _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                size: 18,
                color: AppTheme.textPrimary,
              ),
            ),
            onPressed: () {
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          if (!_isEditing) {
            return _buildProfileView(data);
          } else {
            return _buildEditView(data, uid);
          }
        },
      ),
    );
  }

  // ─── Profile View ─────────────────────────────────────────────────
  Widget _buildProfileView(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Profile Header ────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.surface,
                    child: Text(
                      (data['name'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 24),

          // ── Stats Cards Row 1 ─────────────────────────────
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
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: 12),

          // ── Stats Cards Row 2 ─────────────────────────────
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
                    final userData =
                    snapshot.data?.data() as Map<String, dynamic>?;
                    final weight =
                    (userData?['weight'] ?? data['weight'] ?? 70)
                        .toDouble();
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
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 12),

          // ── Stats Cards Row 3 ─────────────────────────────
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
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),

          // ── Log Weight Button ─────────────────────────────
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.greenGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showLogWeightDialog(),
                icon: const Icon(Icons.monitor_weight_rounded),
                label: const Text(
                  'Log Today\'s Weight',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 24),

          // ── Security Section ──────────────────────────────
          const Text(
            'Security 🔐',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 12),

          _buildSettingsCard(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Update your account password',
            color: AppTheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ).animate().fadeIn(delay: 550.ms).slideX(begin: 0.2),

          const SizedBox(height: 8),

          _buildSettingsCard(
            icon: Icons.email_rounded,
            title: 'Reset via Email',
            subtitle: 'Send password reset link to your email',
            color: Colors.orange,
            onTap: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: user!.email!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reset link sent to ${user.email}',
                              ),
                            ),
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
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: AppTheme.accent,
                      ),
                    );
                  }
                }
              }
            },
          ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2),

          const SizedBox(height: 24),

          // ── More Options Section ──────────────────────────
          const Text(
            'More Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ).animate().fadeIn(delay: 650.ms),
          const SizedBox(height: 12),

          _buildSettingsCard(
            icon: Icons.download_rounded,
            title: 'Export Reports',
            subtitle: 'Download your fitness data (PDF/CSV)',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExportScreen(),
                ),
              );
            },
          ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.2),

          const SizedBox(height: 8),

          _buildSettingsCard(
            icon: Icons.star_rounded,
            title: 'Upgrade to Premium',
            subtitle: 'Unlock all AI features & analytics',
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaywallScreen(),
                ),
              );
            },
          ).animate().fadeIn(delay: 750.ms).slideX(begin: 0.2),

          const SizedBox(height: 24),

          // ── Logout Button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent.withOpacity(0.1),
                foregroundColor: AppTheme.accent,
                elevation: 0,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: 12),

          // App Version
          Center(
            child: Text(
              'FitSmart v1.0.0',
              style: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Edit View ────────────────────────────────────────────────────
  Widget _buildEditView(Map<String, dynamic> data, String uid) {
    _nameController.text = data['name'] ?? '';
    _ageController.text = '${data['age'] ?? 20}';
    _heightController.text = '${(data['height'] ?? 170).toInt()}';
    _weightController.text = '${(data['weight'] ?? 70).toInt()}';
    _gender = data['gender'] ?? 'male';
    _activityLevel = data['activityLevel'] ?? 'moderate';
    _goal = data['goal'] ?? 'maintain';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profile ✏️',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn().slideX(begin: -0.2),

          const SizedBox(height: 4),
          const Text(
            'Update your personal information',
            style: TextStyle(color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 24),

          // Name
          _buildEditField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Age & Gender
          Row(
            children: [
              Expanded(
                child: _buildEditField(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gender',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                      ],
                      onChanged: (v) => _gender = v!,
                    ),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Height & Weight
          Row(
            children: [
              Expanded(
                child: _buildEditField(
                  controller: _heightController,
                  label: 'Height (cm)',
                  icon: Icons.height_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditField(
                  controller: _weightController,
                  label: 'Weight (kg)',
                  icon: Icons.monitor_weight_rounded,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

          const SizedBox(height: 16),

          // Goal
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fitness Goal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _goal,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'lose_weight',
                    child: Text('🔥 Lose Weight'),
                  ),
                  DropdownMenuItem(
                    value: 'gain_muscle',
                    child: Text('💪 Gain Muscle'),
                  ),
                  DropdownMenuItem(
                    value: 'maintain',
                    child: Text('⚖️ Maintain Weight'),
                  ),
                ],
                onChanged: (v) => _goal = v!,
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 32),

          // Save Button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () => _saveProfile(uid),
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─── Save Profile ─────────────────────────────────────────────────
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
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
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profile updated! ✅'),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ─── Log Weight Dialog ────────────────────────────────────────────
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
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
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
                    SnackBar(
                      content: const Text('Enter a valid weight'),
                      backgroundColor: AppTheme.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
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

  // ─── Save Weight ──────────────────────────────────────────────────
  Future<void> _saveWeight(double weight) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Save to user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'weight': weight});

      // Save to daily logs
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    }
  }

  // ─── Logout Dialog ────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('👋', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ─── Helper Widgets ───────────────────────────────────────────────

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
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textSecondary.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppTheme.primary,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helper Methods ───────────────────────────────────────────────

  String _getGoalName(String goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'gain_muscle':
        return 'Gain Muscle';
      case 'maintain':
        return 'Maintain';
      default:
        return goal;
    }
  }

  String _getActivityName(String level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary';
      case 'light':
        return 'Light';
      case 'moderate':
        return 'Moderate';
      case 'active':
        return 'Active';
      case 'very_active':
        return 'Very Active';
      default:
        return level;
    }
  }
}