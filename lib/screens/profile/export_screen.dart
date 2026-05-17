import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/export_service.dart';
import '../../services/subscription_service.dart';
import '../subscription/paywall_screen.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final _exportService = ExportService();
  final _subscriptionService = SubscriptionService();
  bool _isPremium = false;
  bool _isLoading = false;
  String? _loadingItem;

  @override
  void initState() {
    super.initState();
    _checkPremium();
  }

  Future<void> _checkPremium() async {
    final sub = await _subscriptionService.getSubscription();
    setState(() => _isPremium = sub.isPremium);
  }

  Future<void> _export(String type, Future<void> Function() action) async {
    if (!_isPremium) {
      _showUpgradeDialog();
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingItem = type;
    });

    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$type exported successfully!'),
              ],
            ),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _loadingItem = null;
      });
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⭐', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: const Text(
          'Export reports is a Premium feature.\nUpgrade to download your fitness data anytime!',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaywallScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upgrade ⭐'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text('Export Reports'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Premium Banner
            if (!_isPremium)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
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
                          Text('Premium Feature',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Upgrade to export your fitness data',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const PaywallScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Upgrade',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.2),

            // PDF Reports Section
            const Text('📄 PDF Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                .animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 4),
            const Text('Detailed formatted reports',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                .animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 12),

            _buildExportCard(
              icon: Icons.picture_as_pdf_rounded,
              title: 'Weekly Summary Report',
              description: 'Complete weekly overview with calories, workouts, water intake & profile',
              color: Colors.red,
              format: 'PDF',
              isLoading: _loadingItem == 'Weekly Report',
              onTap: () => _export('Weekly Report', _exportService.exportWeeklyReport),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2),

            const SizedBox(height: 24),

            // CSV Exports Section
            const Text('📊 CSV Exports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                .animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 4),
            const Text('Raw data for spreadsheet analysis',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                .animate().fadeIn(delay: 350.ms),
            const SizedBox(height: 12),

            _buildExportCard(
              icon: Icons.restaurant_rounded,
              title: 'Meal History',
              description: 'Last 30 days of meals with calories, protein, carbs & fat data',
              color: AppTheme.secondary,
              format: 'CSV',
              isLoading: _loadingItem == 'Meal History',
              onTap: () => _export('Meal History', _exportService.exportMealsCSV),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2),

            const SizedBox(height: 12),

            _buildExportCard(
              icon: Icons.fitness_center_rounded,
              title: 'Workout History',
              description: 'Last 30 days of workouts with duration, calories burned & exercises',
              color: AppTheme.primary,
              format: 'CSV',
              isLoading: _loadingItem == 'Workout History',
              onTap: () => _export('Workout History', _exportService.exportWorkoutsCSV),
            ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.2),

            const SizedBox(height: 12),

            _buildExportCard(
              icon: Icons.bar_chart_rounded,
              title: 'Progress Data',
              description: 'Weekly progress including weight, calories & workout trends',
              color: Colors.orange,
              format: 'CSV',
              isLoading: _loadingItem == 'Progress Data',
              onTap: () => _export('Progress Data', _exportService.exportProgressCSV),
            ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.2),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('How It Works',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• PDF reports are beautifully formatted\n'
                        '• CSV files can be opened in Excel or Google Sheets\n'
                        '• Files are shared via your device\'s share menu\n'
                        '• Save to Google Drive, email, or WhatsApp',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 700.ms),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String format,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
          border: Border.all(
            color: _isPremium ? Colors.transparent : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(format,
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Action
            if (isLoading)
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: color, strokeWidth: 2),
              )
            else if (!_isPremium)
              const Text('🔒', style: TextStyle(fontSize: 20))
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.download_rounded, color: color, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}