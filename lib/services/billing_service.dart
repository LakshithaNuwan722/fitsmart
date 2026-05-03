import 'dart:async';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'subscription_service.dart';

class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final SubscriptionService _subscriptionService = SubscriptionService();

  // Product IDs (must match Play Console exactly)
  static const String monthlyProductId = 'fitsmart_premium_monthly';
  static const String yearlyProductId = 'fitsmart_premium_yearly';

  static const Set<String> _productIds = {
    monthlyProductId,
    yearlyProductId,
  };

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;

  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  // Initialize billing
  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) {
      print('Play Store not available');
      return;
    }

    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => print('Purchase error: $error'),
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);
      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  // Handle purchase updates
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
        // Verify and activate
          await _handleSuccessfulPurchase(purchase);
          await _iap.completePurchase(purchase);
          break;

        case PurchaseStatus.error:
          print('Purchase error: ${purchase.error}');
          await _iap.completePurchase(purchase);
          break;

        case PurchaseStatus.pending:
          print('Purchase pending...');
          break;

        case PurchaseStatus.canceled:
          print('Purchase canceled');
          break;
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    try {
      final plan = purchase.productID == monthlyProductId ? 'monthly' : 'yearly';
      await _subscriptionService.activateSubscription(plan);
      print('✅ Premium activated: $plan');
    } catch (e) {
      print('Error activating subscription: $e');
    }
  }

  // Buy subscription
  Future<void> buySubscription(String productId) async {
    final product = _products.firstWhere(
          (p) => p.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  // Restore purchases
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}