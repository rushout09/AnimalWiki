import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4CAF50);
  static const secondary = Color(0xFF2196F3);
  static const background = Color(0xFFF5F5F5);
  static const cardBackground = Colors.white;
  static const text = Color(0xFF212121);
  static const textLight = Color(0xFF757575);
}

class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );
  
  static const subheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  
  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );
  
  static const caption = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );
}