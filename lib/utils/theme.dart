import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const primary = Color(0xFF00A86B);     // Vibrant green
  static const secondary = Color(0xFF4A90E2);   // Sky blue
  static const accent = Color(0xFFFFA726);      // Warm orange
  static const danger = Color(0xFFFF5252);      // Coral red

  // Background & Surface Colors
  static const background = Color(0xFFF9F9F7);  // Off-white
  static const surfaceLight = Colors.white;     // White
  static const surfaceMedium = Color(0xFFF2F4F5); // Light gray 
  static const surfaceDark = Color(0xFFE8ECF0);   // Medium gray

  // Text Colors
  static const textDark = Color(0xFF263238);    // Almost black
  static const textMedium = Color(0xFF546E7A);  // Dark gray
  static const textLight = Color(0xFF78909C);   // Medium gray
  static const textWhite = Colors.white;        // White

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF00A86B), Color(0xFF16DB93)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const accentGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFFCC80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Text Styles
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.montserrat(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textDark,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.montserrat(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: textDark,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.montserrat(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: textDark,
      letterSpacing: -0.25,
    ),
    headlineMedium: GoogleFonts.montserrat(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    headlineSmall: GoogleFonts.montserrat(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    titleLarge: GoogleFonts.montserrat(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    titleMedium: GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textDark,
    ),
    bodyLarge: GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: textMedium,
    ),
    bodyMedium: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: textMedium,
    ),
    labelLarge: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: textMedium,
    ),
  );

  // Radius values
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusExtraLarge = 32.0;
  
  // Spacing values
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;
  static const double spacingHuge = 48.0;
  
  // Shadows
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 25,
      offset: Offset(0, 8),
    ),
  ];
  
  // ThemeData
  static ThemeData getTheme() {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surfaceLight,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: textTheme.headlineMedium?.copyWith(color: textDark),
        iconTheme: IconThemeData(color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: BorderSide(color: primary, width: 1.5),
          foregroundColor: primary,
          textStyle: textTheme.labelLarge?.copyWith(
            color: primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        clipBehavior: Clip.antiAlias,
        color: surfaceLight,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primary.withOpacity(0.1),
        labelTextStyle: MaterialStateProperty.all(
          textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}