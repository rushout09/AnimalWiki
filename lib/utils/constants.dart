import 'package:flutter/material.dart';

// A new install starts with this many credits. A stored balance, including
// a stored 0, is never overwritten by this default.
const int kFreeStarterCredits = 2;

// Deprecated by Google, shutdown date 1 June 2026 (already past). Not
// changed here: picking the replacement needs a live API key to check
// which models are actually available, and there is no live key yet.
const String kGeminiModel = 'gemini-2.0-flash';

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