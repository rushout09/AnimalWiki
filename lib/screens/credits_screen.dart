import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kDebugMode
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart'; // Import for ProductDetails
import '../services/payment_service.dart';
import '../utils/theme.dart';
import '../widgets/app_button.dart';
import '../widgets/animated_gradient_button.dart';

class CreditsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buy Credits'),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      paymentService.queryProductError ?? 'Store not available on this device',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
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

          // Check if we have products to display
          if (paymentService.products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 60,
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No credit packs available',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'Credit packs are not yet configured in the store.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 24),
                  AppButton(
                    onPressed: () {
                      paymentService.initStoreInfo();
                    },
                    text: 'Refresh',
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
                  // Current credits display
                  _buildCurrentCreditsCard(context, paymentService),
                  SizedBox(height: 24),
                  
                  // Header
                  Center(
                    child: Text(
                      'Purchase Credits',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Credits are used for animal identifications',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Credit pack options from the store
                  ...paymentService.products.map((product) => 
                    _buildCreditPackOption(
                      context,
                      product: product,
                      paymentService: paymentService,
                    ),
                  ).toList(),
                  
                  SizedBox(height: 24),
                  
                  // Credit usage information
                  _buildCreditUsageInfo(context),
                  
                  SizedBox(height: 16),
                  
                  // Debug buttons in debug mode ONLY
                  if (kDebugMode)
                    _buildDebugControls(context, paymentService),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentCreditsCard(BuildContext context, PaymentService paymentService) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withOpacity(0.8), AppTheme.secondary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Credits',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                Icons.monetization_on,
                color: Colors.white,
                size: 28,
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${paymentService.credits}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'credits',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Each animal identification uses 1 credit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditPackOption(
    BuildContext context, {
    required ProductDetails product,
    required PaymentService paymentService,
  }) {
    // Extract the credit amount from product ID or title
    String creditsText = '10 Credits';
    Color bgColor = AppTheme.surfaceLight;
    bool isBestValue = false;
    
    // Parse credit amounts from product IDs
    if (product.id.contains('10_credits')) {
      creditsText = '10 Credits';
    } else if (product.id.contains('50_credits')) {
      creditsText = '50 Credits';
      bgColor = AppTheme.surfaceLight.withBlue(bgColor.blue + 5);
    } else if (product.id.contains('100_credits')) {
      creditsText = '100 + 20 Bonus Credits';
      isBestValue = true;
      bgColor = AppTheme.surfaceLight.withBlue(bgColor.blue + 10);
    } else {
      // Default display for products without recognized IDs
      creditsText = product.title;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: isBestValue 
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Column(
        children: [
          if (isBestValue)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
              ),
              child: Text(
                'BEST VALUE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: isBestValue ? Colors.amber : AppTheme.primary,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        creditsText,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      product.price,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),
                AnimatedGradientButton(
                  onPressed: () async {
                    try {
                      await paymentService.purchaseCredits(product);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  text: 'Purchase',
                  gradient: LinearGradient(
                    colors: isBestValue 
                        ? [Colors.amber, Colors.orange]
                        : [AppTheme.primary, AppTheme.secondary],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditUsageInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How Credits Work',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          _buildInfoItem(
            context, 
            icon: Icons.check_circle_outline,
            text: 'Each animal identification costs 1 credit'
          ),
          SizedBox(height: 8),
          _buildInfoItem(
            context, 
            icon: Icons.check_circle_outline,
            text: 'Credits never expire'
          ),
          SizedBox(height: 8),
          _buildInfoItem(
            context, 
            icon: Icons.check_circle_outline,
            text: 'Larger packs give you bonus credits'
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, {required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon, 
          color: AppTheme.primary,
          size: 18,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDebugControls(BuildContext context, PaymentService paymentService) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Debug Controls',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => paymentService.resetCredits(),
                  child: Text('Reset Credits'),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => paymentService.addFreeCredits(10),
                  child: Text('Add 10 Free'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}