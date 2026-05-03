import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../services/billing_service.dart';
import '../../services/subscription_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  String _selectedPlan = 'monthly';
  bool _isLoading = false;
  final _subscriptionService = SubscriptionService();

  final _billingService = BillingService();
  bool _billingInitialized = false;

  @override
  void initState() {
    super.initState();
    _initBilling();
  }

  Future<void> _initBilling() async {
    await _billingService.initialize();
    setState(() => _billingInitialized = true);
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    try {
      if (!_billingService.isAvailable) {
        // Fallback for testing only
        await _subscriptionService.activateSubscription(_selectedPlan);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Premium activated!')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Real Google Play purchase
      final productId = _selectedPlan == 'monthly'
          ? BillingService.monthlyProductId
          : BillingService.yearlyProductId;

      await _billingService.buySubscription(productId);
      // Purchase result handled by stream listener
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(10), boxShadow: AppTheme.cardShadow,
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('FitSmart Premium',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Unlock all AI features', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
                ],
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 24),

            // Features
            const Text('Premium Benefits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildFeature(Icons.camera_alt_rounded, 'Unlimited AI Food Scans', 'Scan any meal, anytime', Colors.orange),
            _buildFeature(Icons.fitness_center_rounded, 'Unlimited AI Workouts', 'Generate unlimited plans', Colors.blue),
            _buildFeature(Icons.bar_chart_rounded, 'Advanced Analytics', 'Detailed progress insights', Colors.green),
            _buildFeature(Icons.block_rounded, 'Ad-Free Experience', 'No interruptions', Colors.purple),
            _buildFeature(Icons.download_rounded, 'Export Reports', 'Download your data', AppTheme.primary),

            const SizedBox(height: 24),

            // Plans
            const Text('Choose Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Monthly
            _buildPlanCard(
              plan: 'monthly',
              title: 'Monthly',
              price: '\$4.99',
              period: '/month',
              subtitle: 'Billed monthly',
            ),
            const SizedBox(height: 12),

            // Yearly
            _buildPlanCard(
              plan: 'yearly',
              title: 'Yearly',
              price: '\$29.99',
              period: '/year',
              subtitle: 'Save 50% • \$2.49/mo',
              isBestValue: true,
            ),

            const SizedBox(height: 24),

            // Subscribe Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Text(
                  _selectedPlan == 'monthly' ? 'Subscribe • \$4.99/month' : 'Subscribe • \$29.99/year',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 12),
            const Text('Cancel anytime', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue with Free Plan', style: TextStyle(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 22),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2);
  }

  Widget _buildPlanCard({
    required String plan,
    required String title,
    required String price,
    required String period,
    required String subtitle,
    bool isBestValue = false,
  }) {
    final isSelected = _selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary.withOpacity(0.06) : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected ? AppTheme.cardShadow : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade300, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : const SizedBox(width: 14, height: 14),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(subtitle,
                          style: TextStyle(
                              color: isBestValue ? AppTheme.secondary : AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Text(price,
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.primary : AppTheme.textPrimary)),
                Text(period, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          if (isBestValue)
            Positioned(
              top: -8, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.greenGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('BEST VALUE',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}