import 'package:flutter/material.dart';
import '../constants/text_styles.dart';

/// Unified Theme for Coopvest Africa
/// 
/// This theme integrates the unified typography system with Material Design 3
/// and provides consistent styling across light and dark modes.
class AppTheme {
  // Color definitions
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFFFF6F00);
  
  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textDisabled = Color(0xFFCCCCCC);

  // Dark mode text colors
  static const Color darkTextPrimary = Color(0xFFE8E8E8);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkTextDisabled = Color(0xFF4A4A4A);

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      
      // ========================================================================
      // TEXT THEME - Unified Typography System
      // ========================================================================
      textTheme: TextTheme(
        // Display styles
        displayLarge: AppTypography.displayLarge.copyWith(color: textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: textPrimary),
        
        // Headline styles
        headlineLarge: AppTypography.headlineLarge.copyWith(color: textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: textPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: textPrimary),
        
        // Title styles
        titleLarge: AppTypography.titleLarge.copyWith(color: textPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: textPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: textPrimary),
        
        // Body styles
        bodyLarge: AppTypography.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: textSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: textTertiary),
        
        // Label styles
        labelLarge: AppTypography.labelLarge.copyWith(color: textPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: textSecondary),
        labelSmall: AppTypography.labelSmall.copyWith(color: textTertiary),
      ),

      // ========================================================================
      // COMPONENT THEMES
      // ========================================================================
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTypography.labelLarge.copyWith(color: textSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: textTertiary),
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: textPrimary),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: textPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: textSecondary),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        labelStyle: AppTypography.labelMedium.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryLightColor,
        brightness: Brightness.dark,
      ),

      // ========================================================================
      // TEXT THEME - Unified Typography System (Dark Mode)
      // ========================================================================
      textTheme: TextTheme(
        // Display styles
        displayLarge: AppTypography.displayLarge.copyWith(color: darkTextPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: darkTextPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: darkTextPrimary),
        
        // Headline styles
        headlineLarge: AppTypography.headlineLarge.copyWith(color: darkTextPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: darkTextPrimary),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: darkTextPrimary),
        
        // Title styles
        titleLarge: AppTypography.titleLarge.copyWith(color: darkTextPrimary),
        titleMedium: AppTypography.titleMedium.copyWith(color: darkTextPrimary),
        titleSmall: AppTypography.titleSmall.copyWith(color: darkTextPrimary),
        
        // Body styles
        bodyLarge: AppTypography.bodyLarge.copyWith(color: darkTextPrimary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: darkTextSecondary),
        bodySmall: AppTypography.bodySmall.copyWith(color: darkTextTertiary),
        
        // Label styles
        labelLarge: AppTypography.labelLarge.copyWith(color: darkTextPrimary),
        labelMedium: AppTypography.labelMedium.copyWith(color: darkTextSecondary),
        labelSmall: AppTypography.labelSmall.copyWith(color: darkTextTertiary),
      ),

      // ========================================================================
      // COMPONENT THEMES (Dark Mode)
      // ========================================================================
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryLightColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: AppTypography.labelLarge.copyWith(color: darkTextSecondary),
        hintStyle: AppTypography.bodyMedium.copyWith(color: darkTextTertiary),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: darkTextPrimary),
      ),

      cardTheme: CardTheme(
        elevation: 2,
        color: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: darkTextPrimary),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: darkTextSecondary),
      ),

      chipTheme: ChipThemeData(
        labelStyle: AppTypography.labelMedium.copyWith(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
