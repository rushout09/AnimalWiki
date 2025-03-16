import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';
import '../widgets/app_button.dart';
import '../widgets/animated_gradient_button.dart';

class PremiumScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Features'),
        elevation: 0,
      ),
      body: Consumer<PaymentService>(
        builder: (context, paymentService, child) {
          if (paymentService.loading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!paymentService.isAvailable) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'In-app purchases are not available',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    paymentService.queryProductError ?? 'Store not available',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  AppButton(
                    onPressed: () {
                      paymentService.initStoreInfo();
                    },
                    text: 'Retry',
                  ),
                ],
              ),
            );
          }

          // If purchases are pending, show loading indicator
          if (paymentService.purchasePending) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Processing your purchase...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Center(
                    child: Text(
                      'Unlock Premium Features',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get the most out of your Animal Identifier experience',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Feature cards
                  _buildPremiumOption(
                    context,
                    title: 'Unlimited Identifications',
                    description: 'Identify as many animals as you want without daily limits',
                    icon: Icons.photo_library,
                    isPurchased: paymentService.hasUnlimitedIdentification,
                    onPurchase: () => _purchaseProduct(
                      context,
                      paymentService,
                      'animal_identifier_unlimited',
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  _buildPremiumOption(
                    context,
                    title: 'Premium Features',
                    description: 'Get detailed animal data, offline mode, and no ads',
                    icon: Icons.stars,
                    isPurchased: paymentService.hasPremiumFeatures,
                    onPurchase: () => _purchaseProduct(
                      context,
                      paymentService,
                      'animal_identifier_premium',
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Restore purchases button
                  TextButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Restoring purchases...')),
                      );
                      await paymentService.restorePurchases();
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Purchases restored')),
                      );
                    },
                    child: Text('Restore Purchases'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool isPurchased,
    required VoidCallback onPurchase,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isPurchased)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Purchased',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            if (!isPurchased)
              AnimatedGradientButton(
                onPressed: onPurchase,
                text: 'Purchase',
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseProduct(
    BuildContext context,
    PaymentService paymentService,
    String productId,
  ) async {
    final product = paymentService.products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    try {
      await paymentService.purchaseProduct(product);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}