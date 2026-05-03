import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/progress_service.dart';
import '../../services/subscription_service.dart';
import '../../models/daily_log.dart';
import '../../models/subscription.dart';
import '../subscription/paywall_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  final _progressService = ProgressService();
  final _subscriptionService = SubscriptionService();
  List<DailyLog> _weeklyLogs = [];
  List<Map<String, dynamic>> _weightHistory = [];
  UserSubscription? _subscription;
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final logs = await _progressService.getWeeklyLogsFromMeals();
      final weights = await _progressService.getWeightHistory();
      final subscription = await _subscriptionService.getSubscription();

      setState(() {
        _weeklyLogs = logs;
        _weightHistory = weights;
        _subscription = subscription;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Progress Analytics'),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nutrition'),
                  if (_subscription?.isPremium == false) ...[
                    const SizedBox(width: 4),
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Body'),
                  if (_subscription?.isPremium == false) ...[
                    const SizedBox(width: 4),
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildNutritionTab(),
          _buildBodyTab(),
        ],
      ),
    );
  }

  // ─── OVERVIEW TAB (Free) ─────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Weekly Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg Calories',
                  '${_getAverageCalories()}',
                  'kcal/day',
                  Icons.local_fire_department_rounded,
                  AppTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Workouts',
                  '${_getTotalWorkouts()}',
                  'this week',
                  Icons.fitness_center_rounded,
                  AppTheme.primary,
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Avg Water',
                  '${_getAverageWater().toStringAsFixed(1)}',
                  'liters/day',
                  Icons.water_drop_rounded,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Active Days',
                  '${_getActiveDays()}',
                  'out of 7',
                  Icons.calendar_today_rounded,
                  AppTheme.secondary,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),

          // Weekly Calories Chart
          _buildSectionHeader('Weekly Calories', Icons.bar_chart_rounded, AppTheme.primary),
          const SizedBox(height: 12),
          _buildCalorieChart()
              .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

          const SizedBox(height: 24),

          // Premium Banner
          if (_subscription?.isPremium == false)
            _buildPremiumBanner().animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  // ─── NUTRITION TAB (Premium) ─────────────────────────────────────
  Widget _buildNutritionTab() {
    if (_subscription?.isPremium == false) {
      return _buildLockedContent(
        'Nutrition Analytics',
        'Get detailed breakdown of your macros, calorie trends, and meal patterns',
        [
          '📊 Daily macro breakdown (Protein/Carbs/Fat)',
          '🔥 Calorie trend analysis',
          '🍽️ Best and worst calorie days',
          '📈 Nutrition goal progress',
          '⚠️ Deficit/Surplus tracking',
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Macro Breakdown
          _buildSectionHeader('Macro Breakdown', Icons.pie_chart_rounded, Colors.orange),
          const SizedBox(height: 12),
          _buildMacroChart().animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 24),

          // Calorie Analysis
          _buildSectionHeader('Calorie Analysis', Icons.analytics_rounded, AppTheme.accent),
          const SizedBox(height: 12),
          _buildCalorieAnalysis().animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Daily Breakdown
          _buildSectionHeader('Daily Breakdown', Icons.list_alt_rounded, AppTheme.primary),
          const SizedBox(height: 12),
          ..._weeklyLogs.reversed.map((log) =>
              _buildDayRow(log).animate().fadeIn(delay: 100.ms)),
        ],
      ),
    );
  }

  // ─── BODY TAB (Premium) ──────────────────────────────────────────
  Widget _buildBodyTab() {
    if (_subscription?.isPremium == false) {
      return _buildLockedContent(
        'Body Analytics',
        'Track your physical progress with detailed body metrics and insights',
        [
          '⚖️ Weight progress chart (30 days)',
          '📉 BMI tracking & history',
          '💪 Body composition trends',
          '🎯 Goal achievement tracking',
          '🏆 Personal records & milestones',
        ],
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Weight Progress
          _buildSectionHeader('Weight Progress', Icons.monitor_weight_rounded, Colors.green),
          const SizedBox(height: 12),
          _weightHistory.isEmpty
              ? _buildNoDataCard('No weight data yet.\nLog your weight daily in Profile tab.')
              : _buildWeightChart().animate().fadeIn().slideY(begin: 0.2),

          const SizedBox(height: 24),

          // BMI Card
          _buildSectionHeader('BMI Analysis', Icons.accessibility_rounded, Colors.blue),
          const SizedBox(height: 12),
          _buildBMICard().animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Goal Progress
          _buildSectionHeader('Goal Progress', Icons.flag_rounded, AppTheme.primary),
          const SizedBox(height: 12),
          _buildGoalProgress().animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // Milestones
          _buildSectionHeader('Milestones 🏆', Icons.emoji_events_rounded, Colors.amber),
          const SizedBox(height: 12),
          _buildMilestones().animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  // ─── CHARTS ─────────────────────────────────────────────────────

  Widget _buildCalorieChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxCalories(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppTheme.primary,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toInt()} kcal',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < _weeklyLogs.length) {
                    final date = DateTime.parse(_weeklyLogs[index].date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('E').format(date),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          barGroups: _weeklyLogs.asMap().entries.map((entry) {
            final calories = entry.value.caloriesConsumed;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: calories.toDouble(),
                  gradient: calories > 0
                      ? LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppTheme.primary.withOpacity(0.6), AppTheme.primary],
                  )
                      : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade200]),
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < _weightHistory.length && index % 5 == 0) {
                    final date = DateTime.parse(_weightHistory[index]['date']);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('d/M').format(date),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _weightHistory.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value['weight']);
              }).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChart() {
    double totalProtein = 0, totalCarbs = 0, totalFat = 0;
    for (var log in _weeklyLogs) {
      totalProtein += 35;
      totalCarbs += 60;
      totalFat += 15;
    }
    final total = totalProtein + totalCarbs + totalFat;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: totalProtein,
                        color: Colors.blue,
                        title: '${(totalProtein / total * 100).toInt()}%',
                        radius: 60,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      PieChartSectionData(
                        value: totalCarbs,
                        color: Colors.orange,
                        title: '${(totalCarbs / total * 100).toInt()}%',
                        radius: 60,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      PieChartSectionData(
                        value: totalFat,
                        color: AppTheme.accent,
                        title: '${(totalFat / total * 100).toInt()}%',
                        radius: 60,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                    sectionsSpace: 4,
                    centerSpaceRadius: 30,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildMacroLegend('Protein', '${totalProtein.toInt()}g', Colors.blue),
                    const SizedBox(height: 12),
                    _buildMacroLegend('Carbs', '${totalCarbs.toInt()}g', Colors.orange),
                    const SizedBox(height: 12),
                    _buildMacroLegend('Fat', '${totalFat.toInt()}g', AppTheme.accent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ──────────────────────────────────────────────

  Widget _buildLockedContent(String title, String description, List<String> features) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 24),

          const Text('Premium Features Include:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          ...features.map((feature) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Text(feature.substring(0, 2), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(feature.substring(3), style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2)),

          const SizedBox(height: 24),

          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const PaywallScreen())),
              icon: const Icon(Icons.star_rounded),
              label: const Text('Upgrade to Premium', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const PaywallScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.buttonShadow,
        ),
        child: Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unlock Advanced Analytics',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Macros, body metrics, AI insights & more',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Upgrade', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieAnalysis() {
    if (_weeklyLogs.isEmpty) return _buildNoDataCard('No data available');

    final calories = _weeklyLogs.map((l) => l.caloriesConsumed).toList();
    final maxCal = calories.reduce((a, b) => a > b ? a : b);
    final minCal = calories.reduce((a, b) => a < b ? a : b);
    final avgCal = calories.fold<int>(0, (sum, c) => sum + c) ~/ calories.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildAnalysisCard('Best Day', '$maxCal kcal', Icons.trending_up_rounded, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildAnalysisCard('Lowest Day', '$minCal kcal', Icons.trending_down_rounded, Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        _buildAnalysisCard('Weekly Average', '$avgCal kcal/day', Icons.analytics_rounded, AppTheme.primary),
      ],
    );
  }

  Widget _buildBMICard() {
    final weight = _weightHistory.isNotEmpty ? _weightHistory.last['weight'] as double : 70.0;
    final height = 1.70;
    final bmi = weight / (height * height);

    String category;
    Color color;
    String emoji;

    if (bmi < 18.5) {
      category = 'Underweight'; color = Colors.blue; emoji = '📉';
    } else if (bmi < 25) {
      category = 'Normal Weight'; color = Colors.green; emoji = '✅';
    } else if (bmi < 30) {
      category = 'Overweight'; color = Colors.orange; emoji = '⚠️';
    } else {
      category = 'Obese'; color = Colors.red; emoji = '🚨';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    Text('BMI: ${bmi.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${bmi.toStringAsFixed(1)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // BMI Scale
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (bmi / 40).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Underweight', style: TextStyle(fontSize: 10, color: Colors.blue)),
              Text('Normal', style: TextStyle(fontSize: 10, color: Colors.green)),
              Text('Overweight', style: TextStyle(fontSize: 10, color: Colors.orange)),
              Text('Obese', style: TextStyle(fontSize: 10, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgress() {
    final avgCalories = _getAverageCalories();
    final workouts = _getTotalWorkouts();
    final water = _getAverageWater();

    return Column(
      children: [
        _buildProgressBar('Calorie Goal', avgCalories, 2000, AppTheme.accent),
        const SizedBox(height: 12),
        _buildProgressBar('Workout Goal', workouts, 5, AppTheme.primary),
        const SizedBox(height: 12),
        _buildProgressBar('Hydration Goal', water.toInt(), 3, Colors.blue),
      ],
    );
  }

  Widget _buildProgressBar(String label, num current, num target, Color color) {
    final percent = (current / target).clamp(0.0, 1.0);
    final isAchieved = current >= target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              if (isAchieved) const Text('✅ Achieved!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600))
              else Text('$current / $target', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent.toDouble(),
              minHeight: 8,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(isAchieved ? Colors.green : color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones() {
    final workouts = _getTotalWorkouts();
    final activeDays = _getActiveDays();

    final milestones = [
      {
        'icon': '🏃',
        'title': 'First Workout',
        'desc': 'Complete your first workout',
        'achieved': workouts >= 1,
      },
      {
        'icon': '💪',
        'title': '3 Workouts',
        'desc': 'Complete 3 workouts this week',
        'achieved': workouts >= 3,
      },
      {
        'icon': '🔥',
        'title': '5-Day Streak',
        'desc': 'Be active for 5 days',
        'achieved': activeDays >= 5,
      },
      {
        'icon': '💧',
        'title': 'Hydration Hero',
        'desc': 'Drink 3L water daily',
        'achieved': _getAverageWater() >= 3,
      },
      {
        'icon': '🎯',
        'title': 'Calorie Master',
        'desc': 'Hit calorie goal 5 days',
        'achieved': false,
      },
    ];

    return Column(
      children: milestones.map((m) {
        final achieved = m['achieved'] as bool;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: achieved ? Colors.amber.withOpacity(0.08) : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: achieved ? Colors.amber.withOpacity(0.3) : Colors.grey.shade200,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Text(m['icon'] as String, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(m['desc'] as String, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              achieved
                  ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
              )
                  : Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(Icons.lock_rounded, color: Colors.grey.shade400, size: 16),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayRow(DailyLog log) {
    final date = DateTime.parse(log.date);
    final isToday = log.date == DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday ? AppTheme.primary.withOpacity(0.05) : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade200,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(DateFormat('d').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(DateFormat('E').format(date),
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDayMetric('🔥', '${log.caloriesConsumed}', 'kcal'),
                _buildDayMetric('💧', '${log.waterIntake.toStringAsFixed(1)}', 'L'),
                _buildDayMetric('💪', '${log.workoutsCompleted}', 'workout'),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Today', style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildDayMetric(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildNoDataCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
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
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text(unit, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMacroLegend(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAnalysisCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Calculation Methods ─────────────────────────────────────────
  double _getMaxCalories() {
    if (_weeklyLogs.isEmpty) return 2500;
    final values = _weeklyLogs.map((l) => l.caloriesConsumed).toList();
    if (values.every((v) => v == 0)) return 2500;
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max + 500).toDouble();
  }

  int _getAverageCalories() {
    if (_weeklyLogs.isEmpty) return 0;
    final activeLogs = _weeklyLogs.where((l) => l.caloriesConsumed > 0).toList();
    if (activeLogs.isEmpty) return 0;
    final total = activeLogs.fold<int>(0, (sum, log) => sum + log.caloriesConsumed);
    return total ~/ activeLogs.length;
  }

  int _getTotalWorkouts() {
    if (_weeklyLogs.isEmpty) return 0;
    return _weeklyLogs.fold<int>(0, (sum, log) => sum + log.workoutsCompleted);
  }

  double _getAverageWater() {
    if (_weeklyLogs.isEmpty) return 0;
    final activeLogs = _weeklyLogs.where((l) => l.waterIntake > 0).toList();
    if (activeLogs.isEmpty) return 0;
    final total = activeLogs.fold<double>(0, (sum, log) => sum + log.waterIntake);
    return total / activeLogs.length;
  }

  int _getActiveDays() {
    return _weeklyLogs
        .where((log) => log.caloriesConsumed > 0 || log.workoutsCompleted > 0)
        .length;
  }
}