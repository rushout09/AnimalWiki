import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/theme.dart';
import '../widgets/animated_gradient_button.dart';
import '../services/payment_service.dart';
import 'camera_screen.dart';
import 'credits_screen.dart'; // Import the credits screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the payment service to access credits
    final paymentService = Provider.of<PaymentService>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background patterns/decorations
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.secondary.withOpacity(0.05),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppTheme.spacingHuge),
                    
                    // App title/branding and credits button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.pets,
                                color: AppTheme.primary,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Animal',
                                  style: AppTheme.textTheme.displayMedium?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Identifier',
                                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Credits counter button
                        _buildCreditsButton(context, paymentService),
                      ],
                    ),
                    
                    SizedBox(height: AppTheme.spacingHuge),
                    
                    // Hero text
                    Text(
                      'Discover the\nWorld\'s Wildlife',
                      style: AppTheme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingMedium),
                    
                    Text(
                      'Take a photo of any animal and learn everything about it in seconds.',
                      style: AppTheme.textTheme.bodyLarge,
                    ),
                    
                    SizedBox(height: AppTheme.spacingExtraLarge),
                    
                    // Main action buttons
                    AnimatedGradientButton(
                      text: 'Take a Photo',
                      icon: Icons.camera_alt_rounded,
                      onPressed: () => _pickImage(context, ImageSource.camera, paymentService),
                      isFullWidth: true,
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF16DB93)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingMedium),
                    
                    // Secondary action
                    OutlinedButton.icon(
                      onPressed: () => _pickImage(context, ImageSource.gallery, paymentService),
                      icon: Icon(Icons.photo_library_rounded),
                      label: Text('Choose from Gallery'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 58),
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingMedium),
                    
                    // Buy credits button
                    _buildBuyCreditsButton(context),
                    
                    SizedBox(height: AppTheme.spacingExtraLarge * 2),
                    
                    // App information
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        boxShadow: AppTheme.shadowSmall,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'How It Works',
                            style: AppTheme.textTheme.headlineSmall,
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          _buildInfoRow(
                            icon: Icons.camera_alt,
                            title: 'Capture',
                            description: 'Take a photo or select from your gallery',
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          _buildInfoRow(
                            icon: Icons.auto_awesome,
                            title: 'Analyze',
                            description: 'AI identifies the animal species and details',
                          ),
                          SizedBox(height: AppTheme.spacingMedium),
                          _buildInfoRow(
                            icon: Icons.info_outline,
                            title: 'Discover',
                            description: 'Learn fascinating facts about the animal',
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppTheme.spacingHuge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Credits display button
  Widget _buildCreditsButton(BuildContext context, PaymentService paymentService) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreditsScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: paymentService.credits > 0 ? Colors.green : Colors.amber,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.monetization_on,
              color: paymentService.credits > 0 ? Colors.green : Colors.amber,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              '${paymentService.credits}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: paymentService.credits > 0 ? Colors.green : Colors.amber,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Buy credits button
  Widget _buildBuyCreditsButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreditsScreen()),
        );
      },
      icon: Icon(
        Icons.monetization_on,
        color: Colors.amber,
      ),
      label: Text('Buy Credits'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 58),
        side: BorderSide(color: Colors.amber),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: 24,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickImage(BuildContext context, ImageSource source, PaymentService paymentService) async {
    // Check if user has enough credits
    if (paymentService.credits <= 0) {
      // Show dialog to buy credits
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No Credits Available'),
          content: Text(
            'You need at least 1 credit to identify an animal. Would you like to purchase credits now?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => CreditsScreen())
                );
              },
              child: Text('Buy Credits'),
            ),
          ],
        ),
      );
      return;
    }
    
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Use 1 credit when starting the identification
      await paymentService.useCredits(1);
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            imageFile: File(pickedFile.path),
          ),
        ),
      );
    }
  }
}