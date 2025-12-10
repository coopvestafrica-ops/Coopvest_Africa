import 'package:flutter/material.dart';

/// Unified Typography System for Coopvest Africa
/// 
/// This file defines all typography styles used across the application.
/// Styles are organized by hierarchy: Display → Headline → Title → Body → Label
/// 
/// Font Families:
/// - Primary: Inter (body text, UI elements)
/// - Secondary: Poppins (headings, display text)
/// - Mono: JetBrains Mono (code, technical content)
class AppTypography {
  // Font families
  static const String primaryFont = 'Inter';
  static const String secondaryFont = 'Poppins';
  static const String monoFont = 'JetBrainsMono';

  // ============================================================================
  // DISPLAY STYLES - For hero titles and main headings
  // ============================================================================

  /// Display Large: 57px, Bold, -0.25px letter spacing
  /// Use for: Hero titles, main page headings
  static const TextStyle displayLarge = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.25,
  );

  /// Display Medium: 45px, Bold, 0px letter spacing
  /// Use for: Page titles, section headers
  static const TextStyle displayMedium = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  /// Display Small: 36px, Bold, 0px letter spacing
  /// Use for: Large section headers
  static const TextStyle displaySmall = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
  );

  // ============================================================================
  // HEADLINE STYLES - For section headers and major content divisions
  // ============================================================================

  /// Headline Large: 32px, Bold, 0px letter spacing
  /// Use for: Card titles, major sections
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Headline Medium: 28px, Bold, 0px letter spacing
  /// Use for: Subsection headers
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Headline Small: 24px, Bold, 0px letter spacing
  /// Use for: Component headers
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: secondaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0,
  );

  // ============================================================================
  // TITLE STYLES - For smaller headings and emphasis
  // ============================================================================

  /// Title Large: 22px, Semi-bold, 0px letter spacing
  /// Use for: Dialog titles, form labels
  static const TextStyle titleLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Title Medium: 18px, Semi-bold, 0.15px letter spacing
  /// Use for: Subheadings
  static const TextStyle titleMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
  );

  /// Title Small: 16px, Semi-bold, 0.1px letter spacing
  /// Use for: Small titles, emphasis
  static const TextStyle titleSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // ============================================================================
  // BODY STYLES - For main content and descriptions
  // ============================================================================

  /// Body Large: 16px, Regular, 0.5px letter spacing
  /// Use for: Primary body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.5,
  );

  /// Body Medium: 14px, Regular, 0.25px letter spacing
  /// Use for: Secondary body text
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.25,
  );

  /// Body Small: 12px, Regular, 0.4px letter spacing
  /// Use for: Tertiary text, captions
  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.4,
  );

  // ============================================================================
  // LABEL STYLES - For buttons, badges, and small UI elements
  // ============================================================================

  /// Label Large: 14px, Medium weight, 0.1px letter spacing
  /// Use for: Button text, labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Label Medium: 12px, Medium weight, 0.5px letter spacing
  /// Use for: Small labels, badges
  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  /// Label Small: 11px, Medium weight, 0.5px letter spacing
  /// Use for: Tiny labels, tags
  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get responsive typography based on screen size
  /// Reduces display and headline sizes on smaller screens
  static TextStyle getResponsiveStyle(
    TextStyle baseStyle,
    double screenWidth,
  ) {
    if (screenWidth < 640) {
      // Mobile: Reduce display and headline sizes
      if (baseStyle == displayLarge) return displayMedium;
      if (baseStyle == displayMedium) return displaySmall;
      if (baseStyle == headlineLarge) return headlineMedium;
      if (baseStyle == headlineMedium) return headlineSmall;
    }
    return baseStyle;
  }

  /// Apply color to a text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply custom letter spacing
  static TextStyle withLetterSpacing(TextStyle style, double spacing) {
    return style.copyWith(letterSpacing: spacing);
  }

  /// Apply custom line height
  static TextStyle withLineHeight(TextStyle style, double height) {
    return style.copyWith(height: height);
  }
}
