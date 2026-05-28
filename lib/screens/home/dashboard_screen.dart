import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/meal_service.dart';
import '../../widgets/water_tracker.dart';
import '../meals/meals_tab.dart';
import '../meals/scan_meal_screen.dart';
import '../meals/add_meal_screen.dart';
import '../workouts/workouts_tab.dart';
import '../workouts/generate_workout_screen.dart';
import '../profile/profile_tab.dart';
import '../profile/progress_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const MealsTab(),
          const WorkoutsTab(),
          const ProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 70,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.restaurant_rounded, color: AppTheme.primary),
              label: 'Meals',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.fitness_center_rounded, color: AppTheme.primary),
              label: 'Workouts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outlined, color: AppTheme.textSecondary),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final mealService = MealService();

    return Scaffold(
      backgroundColor: AppTheme.background,
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

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final name = userData?['name'] ?? 'User';
          final dailyTarget = userData?['dailyCalorieTarget'] ?? 2000;

          return FutureBuilder<int>(
            future: mealService.getTodaysTotalCalories(),
            builder: (context, calorieSnapshot) {
              final consumed = calorieSnapshot.data ?? 0;
              final percent = (consumed / dailyTarget).clamp(0.0, 1.0);

              return CustomScrollView(
                slivers: [
                  // App Bar
                  SliverAppBar(
                    floating: true,
                    backgroundColor: AppTheme.background,
                    elevation: 0,
                    toolbarHeight: 70,
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
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
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => FirebaseAuth.instance.signOut(),
                        ),
                      ),
                    ],
                  ),

                  // Body
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([

                        // Calorie Card
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
                              // Calorie Ring
                              CircularPercentIndicator(
                                radius: 60,
                                lineWidth: 10,
                                percent: percent.toDouble(),
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$consumed',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'kcal',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                progressColor: consumed > dailyTarget
                                    ? AppTheme.accent
                                    : AppTheme.secondary,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                circularStrokeCap: CircularStrokeCap.round,
                                animation: true,
                                animationDuration: 1200,
                              ),

                              const SizedBox(width: 24),

                              // Stats
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Today's Progress",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildMiniStat(
                                      'Target',
                                      '$dailyTarget kcal',
                                      Icons.flag_rounded,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildMiniStat(
                                      'Remaining',
                                      '${(dailyTarget - consumed).clamp(0, 99999)} kcal',
                                      Icons.local_fire_department_rounded,
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<int>(
                                      future: _getCaloriesBurned(),
                                      builder: (context, snapshot) {
                                        return _buildMiniStat(
                                          'Burned',
                                          '${snapshot.data ?? 0} kcal',
                                          Icons.fitness_center_rounded,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Progress Bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: percent.toDouble(),
                                        backgroundColor: Colors.white.withOpacity(0.1),
                                        valueColor: AlwaysStoppedAnimation(
                                          consumed > dailyTarget
                                              ? AppTheme.accent
                                              : AppTheme.secondary,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                        const SizedBox(height: 24),

                        // AI Features Section
                        Text(
                          'AI Features ✨',
                          style: Theme.of(context).textTheme.titleLarge,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildAICard(
                                title: 'Scan Meal',
                                subtitle: 'AI identifies food',
                                icon: Icons.camera_alt_rounded,
                                gradient: AppTheme.orangeGradient,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ScanMealScreen(),
                                    ),
                                  );
                                },
                              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildAICard(
                                title: 'AI Workout',
                                subtitle: 'Personalized plan',
                                icon: Icons.auto_awesome_rounded,
                                gradient: AppTheme.blueGradient,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GenerateWorkoutScreen(),
                                    ),
                                  );
                                },
                              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: Theme.of(context).textTheme.titleLarge,
                        ).animate().fadeIn(delay: 500.ms),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'Add Meal',
                                color: AppTheme.secondary,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddMealScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.fitness_center_rounded,
                                label: 'Log Workout',
                                color: AppTheme.primary,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GenerateWorkoutScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildQuickAction(
                                icon: Icons.bar_chart_rounded,
                                label: 'Progress',
                                color: AppTheme.accent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProgressScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                        const SizedBox(height: 24),

                        // Water Tracker
                        Text(
                          'Hydration 💧',
                          style: Theme.of(context).textTheme.titleLarge,
                        ).animate().fadeIn(delay: 700.ms),
                        const SizedBox(height: 12),
                        const WaterTracker()
                            .animate()
                            .fadeIn(delay: 800.ms)
                            .slideY(begin: 0.2),

                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── Helper Methods ─────────────────────────────────────────────
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAICard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Future<int> _getCaloriesBurned() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('workouts')
          .where('date', isEqualTo: today)
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['caloriesBurned'] ?? 0) as int;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }
}