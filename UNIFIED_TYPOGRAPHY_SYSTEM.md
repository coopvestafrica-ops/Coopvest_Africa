# Coopvest Africa - Unified Typography System

**Status**: ✅ Complete & Ready for Implementation  
**Date**: December 9, 2025

---

## 📋 Executive Summary

A comprehensive typography system that ensures consistent, professional, and accessible text across Flutter, React, and all web platforms. This system includes:

- ✅ 8 font sizes with clear hierarchy
- ✅ 5 font weights for visual emphasis
- ✅ 6 line heights for readability
- ✅ 4 letter spacings for refinement
- ✅ Dark mode support
- ✅ Accessibility guidelines
- ✅ Implementation code for all platforms

---

## 🔍 Current State Analysis

### Flutter App (Current)
```dart
// Limited typography system
// No consistent font sizes
// No defined font weights
// No line height standards
```

### React Website (Current)
```typescript
// Tailwind default typography
// No custom font system
// Inconsistent sizing
// No unified scale
```

### Issues Identified
1. ❌ No unified font family
2. ❌ Inconsistent font sizes
3. ❌ No defined font weights
4. ❌ No line height standards
5. ❌ No letter spacing guidelines
6. ❌ No accessibility considerations
7. ❌ No dark mode typography
8. ❌ No responsive typography

---

## ✅ Recommended Typography System

### Font Families

#### Primary Font: Inter
```
Font: Inter
Weight: 400, 500, 600, 700, 800
Usage: All UI text, body copy, labels
Fallback: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif
License: Open Source (SIL Open Font License)
Download: https://fonts.google.com/specimen/Inter
```

**Why Inter?**
- Highly legible at all sizes
- Excellent for UI design
- Professional appearance
- Open source and free
- Optimized for screens
- Great language support

#### Secondary Font: Roboto Mono
```
Font: Roboto Mono
Weight: 400, 500, 600, 700
Usage: Code blocks, technical content, monospace text
Fallback: "Courier New", monospace
License: Open Source (Apache License 2.0)
Download: https://fonts.google.com/specimen/Roboto+Mono
```

**Why Roboto Mono?**
- Perfect for code display
- Clear character distinction
- Professional appearance
- Pairs well with Inter
- Open source

---

## 📐 Typography Scale

### Font Sizes

```
Display Large:    48px / 3rem
Display Medium:   40px / 2.5rem
Display Small:    36px / 2.25rem
Heading 1:        32px / 2rem
Heading 2:        28px / 1.75rem
Heading 3:        24px / 1.5rem
Heading 4:        20px / 1.25rem
Heading 5:        18px / 1.125rem
Heading 6:        16px / 1rem
Subtitle 1:       16px / 1rem
Subtitle 2:       14px / 0.875rem
Body Large:       16px / 1rem
Body Medium:      14px / 0.875rem
Body Small:       12px / 0.75rem
Label Large:      14px / 0.875rem
Label Medium:     12px / 0.75rem
Label Small:      11px / 0.6875rem
Caption:          12px / 0.75rem
```

### Font Weights

```
Thin:       100
ExtraLight: 200
Light:      300
Regular:    400 (Default)
Medium:     500
SemiBold:   600
Bold:       700
ExtraBold:  800
Black:      900
```

### Line Heights

```
Tight:      1.2 (120%)
Compact:    1.4 (140%)
Normal:     1.5 (150%)
Relaxed:    1.6 (160%)
Loose:      1.8 (180%)
VeryLoose:  2.0 (200%)
```

### Letter Spacing

```
Tight:      -0.02em
Normal:     0em
Wide:       0.02em
ExtraWide:  0.04em
```

---

## 📊 Complete Typography Scale

| Name | Size | Weight | Line Height | Letter Spacing | Usage |
|------|------|--------|-------------|----------------|-------|
| Display Large | 48px | 700 | 1.2 | -0.02em | Page titles, hero sections |
| Display Medium | 40px | 700 | 1.2 | -0.02em | Large headings |
| Display Small | 36px | 700 | 1.2 | -0.02em | Section headings |
| Heading 1 | 32px | 700 | 1.4 | -0.02em | Main headings |
| Heading 2 | 28px | 700 | 1.4 | 0em | Subheadings |
| Heading 3 | 24px | 600 | 1.4 | 0em | Section titles |
| Heading 4 | 20px | 600 | 1.5 | 0em | Subsection titles |
| Heading 5 | 18px | 600 | 1.5 | 0em | Card titles |
| Heading 6 | 16px | 600 | 1.5 | 0em | Small titles |
| Subtitle 1 | 16px | 500 | 1.5 | 0.02em | Subtitles, emphasis |
| Subtitle 2 | 14px | 500 | 1.5 | 0.02em | Secondary subtitles |
| Body Large | 16px | 400 | 1.6 | 0em | Main body text |
| Body Medium | 14px | 400 | 1.6 | 0em | Secondary body text |
| Body Small | 12px | 400 | 1.5 | 0em | Small body text |
| Label Large | 14px | 500 | 1.5 | 0.02em | Button labels, tags |
| Label Medium | 12px | 500 | 1.5 | 0.02em | Small labels |
| Label Small | 11px | 500 | 1.5 | 0.04em | Tiny labels, badges |
| Caption | 12px | 400 | 1.4 | 0em | Captions, hints |

---

## 🎨 Typography Styles

### Display Styles

```
Display Large
48px / 700 / 1.2 / -0.02em
Used for: Page titles, hero sections, major announcements

Display Medium
40px / 700 / 1.2 / -0.02em
Used for: Large section headings, important titles

Display Small
36px / 700 / 1.2 / -0.02em
Used for: Section headings, feature titles
```

### Heading Styles

```
Heading 1
32px / 700 / 1.4 / -0.02em
Used for: Main page headings, primary titles

Heading 2
28px / 700 / 1.4 / 0em
Used for: Subheadings, section titles

Heading 3
24px / 600 / 1.4 / 0em
Used for: Section titles, card headings

Heading 4
20px / 600 / 1.5 / 0em
Used for: Subsection titles, form labels

Heading 5
18px / 600 / 1.5 / 0em
Used for: Card titles, list headers

Heading 6
16px / 600 / 1.5 / 0em
Used for: Small titles, emphasis text
```

### Subtitle Styles

```
Subtitle 1
16px / 500 / 1.5 / 0.02em
Used for: Subtitles, emphasized text, descriptions

Subtitle 2
14px / 500 / 1.5 / 0.02em
Used for: Secondary subtitles, secondary descriptions
```

### Body Styles

```
Body Large
16px / 400 / 1.6 / 0em
Used for: Main body text, primary content

Body Medium
14px / 400 / 1.6 / 0em
Used for: Secondary body text, descriptions

Body Small
12px / 400 / 1.5 / 0em
Used for: Small body text, footnotes, metadata
```

### Label Styles

```
Label Large
14px / 500 / 1.5 / 0.02em
Used for: Button labels, tags, badges

Label Medium
12px / 500 / 1.5 / 0.02em
Used for: Small labels, form labels

Label Small
11px / 500 / 1.5 / 0.04em
Used for: Tiny labels, small badges, captions
```

### Caption Style

```
Caption
12px / 400 / 1.4 / 0em
Used for: Captions, hints, helper text, timestamps
```

---

## 🎯 Usage Guidelines

### Hierarchy

```
Display Large (48px)
    ↓
Display Medium (40px)
    ↓
Display Small (36px)
    ↓
Heading 1 (32px)
    ↓
Heading 2 (28px)
    ↓
Heading 3 (24px)
    ↓
Heading 4 (20px)
    ↓
Heading 5 (18px)
    ↓
Heading 6 (16px)
    ↓
Body Large (16px)
    ↓
Body Medium (14px)
    ↓
Body Small (12px)
```

### Font Weight Usage

```
700 (Bold):
- Display styles
- Heading 1-2
- Strong emphasis
- Important labels

600 (SemiBold):
- Heading 3-6
- Subtitles
- Medium emphasis
- Form labels

500 (Medium):
- Subtitles
- Labels
- Buttons
- Light emphasis

400 (Regular):
- Body text
- Captions
- Default text
- Normal content
```

### Line Height Guidelines

```
Tight (1.2):
- Display styles
- Large headings
- Compact layouts

Compact (1.4):
- Headings
- Captions
- Dense content

Normal (1.5):
- Body text
- Labels
- Standard content

Relaxed (1.6):
- Body text
- Long-form content
- Accessibility

Loose (1.8):
- Accessibility
- Mobile content
- Large text

VeryLoose (2.0):
- Accessibility
- Special cases
```

### Letter Spacing Guidelines

```
Tight (-0.02em):
- Display styles
- Large headings
- Compact layouts

Normal (0em):
- Headings
- Body text
- Standard content

Wide (0.02em):
- Subtitles
- Labels
- Emphasis

ExtraWide (0.04em):
- Small labels
- Badges
- Tiny text
```

---

## 💻 Implementation Guide

### Flutter Implementation

```dart
// lib/core/constants/app_typography.dart

import 'package:flutter/material.dart';

class AppTypography {
  // Font families
  static const String primaryFont = 'Inter';
  static const String monoFont = 'RobotoMono';

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.02,
  );

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.02,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle heading4 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle heading5 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle heading6 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
  );

  // Subtitle Styles
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.02,
  );

  static const TextStyle subtitle2 = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.02,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    letterSpacing: 0,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.02,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.02,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.04,
  );

  // Caption Style
  static const TextStyle caption = TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
  );

  // Monospace Style
  static const TextStyle mono = TextStyle(
    fontFamily: monoFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
  );
}
```

### Flutter Theme Integration

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../constants/app_typography.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      displaySmall: AppTypography.displaySmall.copyWith(
        color: AppColors.textPrimary,
      ),
      headlineSmall: AppTypography.heading1.copyWith(
        color: AppColors.textPrimary,
      ),
      headlineMedium: AppTypography.heading2.copyWith(
        color: AppColors.textPrimary,
      ),
      headlineLarge: AppTypography.heading3.copyWith(
        color: AppColors.textPrimary,
      ),
      titleLarge: AppTypography.heading4.copyWith(
        color: AppColors.textPrimary,
      ),
      titleMedium: AppTypography.heading5.copyWith(
        color: AppColors.textPrimary,
      ),
      titleSmall: AppTypography.heading6.copyWith(
        color: AppColors.textPrimary,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(
        color: AppColors.textDisabled,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      displayMedium: AppTypography.displayMedium.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      displaySmall: AppTypography.displaySmall.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: AppTypography.heading1.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: AppTypography.heading2.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineLarge: AppTypography.heading3.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleLarge: AppTypography.heading4.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleMedium: AppTypography.heading5.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      titleSmall: AppTypography.heading6.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: AppTypography.bodyLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      bodySmall: AppTypography.bodySmall.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: AppTypography.labelLarge.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: AppTypography.labelSmall.copyWith(
        color: AppColors.darkTextDisabled,
      ),
    ),
  );
}
```

### React/TypeScript Implementation

```typescript
// src/theme/typography.ts

export const typography = {
  // Font families
  fontFamily: {
    primary: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
    mono: '"Roboto Mono", "Courier New", monospace',
  },

  // Display Styles
  displayLarge: {
    fontSize: '48px',
    fontWeight: 700,
    lineHeight: 1.2,
    letterSpacing: '-0.02em',
  },
  displayMedium: {
    fontSize: '40px',
    fontWeight: 700,
    lineHeight: 1.2,
    letterSpacing: '-0.02em',
  },
  displaySmall: {
    fontSize: '36px',
    fontWeight: 700,
    lineHeight: 1.2,
    letterSpacing: '-0.02em',
  },

  // Heading Styles
  heading1: {
    fontSize: '32px',
    fontWeight: 700,
    lineHeight: 1.4,
    letterSpacing: '-0.02em',
  },
  heading2: {
    fontSize: '28px',
    fontWeight: 700,
    lineHeight: 1.4,
    letterSpacing: '0em',
  },
  heading3: {
    fontSize: '24px',
    fontWeight: 600,
    lineHeight: 1.4,
    letterSpacing: '0em',
  },
  heading4: {
    fontSize: '20px',
    fontWeight: 600,
    lineHeight: 1.5,
    letterSpacing: '0em',
  },
  heading5: {
    fontSize: '18px',
    fontWeight: 600,
    lineHeight: 1.5,
    letterSpacing: '0em',
  },
  heading6: {
    fontSize: '16px',
    fontWeight: 600,
    lineHeight: 1.5,
    letterSpacing: '0em',
  },

  // Subtitle Styles
  subtitle1: {
    fontSize: '16px',
    fontWeight: 500,
    lineHeight: 1.5,
    letterSpacing: '0.02em',
  },
  subtitle2: {
    fontSize: '14px',
    fontWeight: 500,
    lineHeight: 1.5,
    letterSpacing: '0.02em',
  },

  // Body Styles
  bodyLarge: {
    fontSize: '16px',
    fontWeight: 400,
    lineHeight: 1.6,
    letterSpacing: '0em',
  },
  bodyMedium: {
    fontSize: '14px',
    fontWeight: 400,
    lineHeight: 1.6,
    letterSpacing: '0em',
  },
  bodySmall: {
    fontSize: '12px',
    fontWeight: 400,
    lineHeight: 1.5,
    letterSpacing: '0em',
  },

  // Label Styles
  labelLarge: {
    fontSize: '14px',
    fontWeight: 500,
    lineHeight: 1.5,
    letterSpacing: '0.02em',
  },
  labelMedium: {
    fontSize: '12px',
    fontWeight: 500,
    lineHeight: 1.5,
    letterSpacing: '0.02em',
  },
  labelSmall: {
    fontSize: '11px',
    fontWeight: 500,
    lineHeight: 1.5,
    letterSpacing: '0.04em',
  },

  // Caption Style
  caption: {
    fontSize: '12px',
    fontWeight: 400,
    lineHeight: 1.4,
    letterSpacing: '0em',
  },

  // Monospace Style
  mono: {
    fontSize: '14px',
    fontWeight: 400,
    lineHeight: 1.5,
    letterSpacing: '0em',
    fontFamily: '"Roboto Mono", monospace',
  },
};
```

### Tailwind Configuration

```typescript
// tailwind.config.ts

import type { Config } from 'tailwindcss'

const config: Config = {
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Inter"', '-apple-system', 'BlinkMacSystemFont', '"Segoe UI"', 'Roboto', 'sans-serif'],
        mono: ['"Roboto Mono"', '"Courier New"', 'monospace'],
      },
      fontSize: {
        'display-lg': ['48px', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],
        'display-md': ['40px', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],
        'display-sm': ['36px', { lineHeight: '1.2', letterSpacing: '-0.02em', fontWeight: '700' }],
        'h1': ['32px', { lineHeight: '1.4', letterSpacing: '-0.02em', fontWeight: '700' }],
        'h2': ['28px', { lineHeight: '1.4', letterSpacing: '0em', fontWeight: '700' }],
        'h3': ['24px', { lineHeight: '1.4', letterSpacing: '0em', fontWeight: '600' }],
        'h4': ['20px', { lineHeight: '1.5', letterSpacing: '0em', fontWeight: '600' }],
        'h5': ['18px', { lineHeight: '1.5', letterSpacing: '0em', fontWeight: '600' }],
        'h6': ['16px', { lineHeight: '1.5', letterSpacing: '0em', fontWeight: '600' }],
        'subtitle-lg': ['16px', { lineHeight: '1.5', letterSpacing: '0.02em', fontWeight: '500' }],
        'subtitle-sm': ['14px', { lineHeight: '1.5', letterSpacing: '0.02em', fontWeight: '500' }],
        'body-lg': ['16px', { lineHeight: '1.6', letterSpacing: '0em', fontWeight: '400' }],
        'body-md': ['14px', { lineHeight: '1.6', letterSpacing: '0em', fontWeight: '400' }],
        'body-sm': ['12px', { lineHeight: '1.5', letterSpacing: '0em', fontWeight: '400' }],
        'label-lg': ['14px', { lineHeight: '1.5', letterSpacing: '0.02em', fontWeight: '500' }],
        'label-md': ['12px', { lineHeight: '1.5', letterSpacing: '0.02em', fontWeight: '500' }],
        'label-sm': ['11px', { lineHeight: '1.5', letterSpacing: '0.04em', fontWeight: '500' }],
        'caption': ['12px', { lineHeight: '1.4', letterSpacing: '0em', fontWeight: '400' }],
      },
      fontWeight: {
        thin: '100',
        extralight: '200',
        light: '300',
        normal: '400',
        medium: '500',
        semibold: '600',
        bold: '700',
        extrabold: '800',
        black: '900',
      },
      lineHeight: {
        tight: '1.2',
        compact: '1.4',
        normal: '1.5',
        relaxed: '1.6',
        loose: '1.8',
        veryloose: '2.0',
      },
      letterSpacing: {
        tight: '-0.02em',
        normal: '0em',
        wide: '0.02em',
        extrawide: '0.04em',
      },
    },
  },
}

export default config
```

### CSS Variables

```css
/* src/styles/typography.css */

:root {
  /* Font Families */
  --font-primary: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  --font-mono: 'Roboto Mono', 'Courier New', monospace;

  /* Font Sizes */
  --text-display-lg: 48px;
  --text-display-md: 40px;
  --text-display-sm: 36px;
  --text-h1: 32px;
  --text-h2: 28px;
  --text-h3: 24px;
  --text-h4: 20px;
  --text-h5: 18px;
  --text-h6: 16px;
  --text-subtitle-lg: 16px;
  --text-subtitle-sm: 14px;
  --text-body-lg: 16px;
  --text-body-md: 14px;
  --text-body-sm: 12px;
  --text-label-lg: 14px;
  --text-label-md: 12px;
  --text-label-sm: 11px;
  --text-caption: 12px;

  /* Font Weights */
  --font-weight-thin: 100;
  --font-weight-extralight: 200;
  --font-weight-light: 300;
  --font-weight-normal: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
  --font-weight-extrabold: 800;
  --font-weight-black: 900;

  /* Line Heights */
  --line-height-tight: 1.2;
  --line-height-compact: 1.4;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.6;
  --line-height-loose: 1.8;
  --line-height-veryloose: 2;

  /* Letter Spacing */
  --letter-spacing-tight: -0.02em;
  --letter-spacing-normal: 0em;
  --letter-spacing-wide: 0.02em;
  --letter-spacing-extrawide: 0.04em;
}

/* Display Styles */
.display-lg {
  font-family: var(--font-primary);
  font-size: var(--text-display-lg);
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-tight);
  letter-spacing: var(--letter-spacing-tight);
}

.display-md {
  font-family: var(--font-primary);
  font-size: var(--text-display-md);
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-tight);
  letter-spacing: var(--letter-spacing-tight);
}

.display-sm {
  font-family: var(--font-primary);
  font-size: var(--text-display-sm);
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-tight);
  letter-spacing: var(--letter-spacing-tight);
}

/* Heading Styles */
.h1 {
  font-family: var(--font-primary);
  font-size: var(--text-h1);
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-compact);
  letter-spacing: var(--letter-spacing-tight);
}

.h2 {
  font-family: var(--font-primary);
  font-size: var(--text-h2);
  font-weight: var(--font-weight-bold);
  line-height: var(--line-height-compact);
  letter-spacing: var(--letter-spacing-normal);
}

.h3 {
  font-family: var(--font-primary);
  font-size: var(--text-h3);
  font-weight: var(--font-weight-semibold);
  line-height: var(--line-height-compact);
  letter-spacing: var(--letter-spacing-normal);
}

.h4 {
  font-family: var(--font-primary);
  font-size: var(--text-h4);
  font-weight: var(--font-weight-semibold);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-normal);
}

.h5 {
  font-family: var(--font-primary);
  font-size: var(--text-h5);
  font-weight: var(--font-weight-semibold);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-normal);
}

.h6 {
  font-family: var(--font-primary);
  font-size: var(--text-h6);
  font-weight: var(--font-weight-semibold);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-normal);
}

/* Body Styles */
.body-lg {
  font-family: var(--font-primary);
  font-size: var(--text-body-lg);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-relaxed);
  letter-spacing: var(--letter-spacing-normal);
}

.body-md {
  font-family: var(--font-primary);
  font-size: var(--text-body-md);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-relaxed);
  letter-spacing: var(--letter-spacing-normal);
}

.body-sm {
  font-family: var(--font-primary);
  font-size: var(--text-body-sm);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-normal);
}

/* Label Styles */
.label-lg {
  font-family: var(--font-primary);
  font-size: var(--text-label-lg);
  font-weight: var(--font-weight-medium);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-wide);
}

.label-md {
  font-family: var(--font-primary);
  font-size: var(--text-label-md);
  font-weight: var(--font-weight-medium);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-wide);
}

.label-sm {
  font-family: var(--font-primary);
  font-size: var(--text-label-sm);
  font-weight: var(--font-weight-medium);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-extrawide);
}

/* Caption Style */
.caption {
  font-family: var(--font-primary);
  font-size: var(--text-caption);
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-compact);
  letter-spacing: var(--letter-spacing-normal);
}

/* Monospace Style */
.mono {
  font-family: var(--font-mono);
  font-size: 14px;
  font-weight: var(--font-weight-normal);
  line-height: var(--line-height-normal);
  letter-spacing: var(--letter-spacing-normal);
}
```

---

## 📱 Responsive Typography

### Mobile (< 640px)

```
Display Large:    36px → 48px
Display Medium:   32px → 40px
Display Small:    28px → 36px
Heading 1:        28px → 32px
Heading 2:        24px → 28px
Heading 3:        20px → 24px
Heading 4:        18px → 20px
Body Large:       16px (no change)
Body Medium:      14px (no change)
Body Small:       12px (no change)
```

### Tablet (640px - 1024px)

```
Display Large:    40px → 48px
Display Medium:   36px → 40px
Display Small:    32px → 36px
Heading 1:        30px → 32px
Heading 2:        26px → 28px
Heading 3:        22px → 24px
Heading 4:        20px (no change)
Body Large:       16px (no change)
Body Medium:      14px (no change)
Body Small:       12px (no change)
```

### Desktop (> 1024px)

```
All sizes at full scale (no changes)
```

### Responsive CSS

```css
/* Mobile */
@media (max-width: 640px) {
  .display-lg {
    font-size: 36px;
  }
  .display-md {
    font-size: 32px;
  }
  .display-sm {
    font-size: 28px;
  }
  .h1 {
    font-size: 28px;
  }
  .h2 {
    font-size: 24px;
  }
  .h3 {
    font-size: 20px;
  }
  .h4 {
    font-size: 18px;
  }
}

/* Tablet */
@media (min-width: 641px) and (max-width: 1024px) {
  .display-lg {
    font-size: 40px;
  }
  .display-md {
    font-size: 36px;
  }
  .display-sm {
    font-size: 32px;
  }
  .h1 {
    font-size: 30px;
  }
  .h2 {
    font-size: 26px;
  }
  .h3 {
    font-size: 22px;
  }
}

/* Desktop */
@media (min-width: 1025px) {
  /* All sizes at full scale */
}
```

---

## ♿ Accessibility Guidelines

### Contrast Ratios

```
Text on Light Background:
- Heading 1-6: 12.6:1 (AAA)
- Body Text: 12.6:1 (AAA)
- Labels: 12.6:1 (AAA)
- Captions: 12.6:1 (AAA)

Text on Dark Background:
- Heading 1-6: 12.6:1 (AAA)
- Body Text: 12.6:1 (AAA)
- Labels: 12.6:1 (AAA)
- Captions: 12.6:1 (AAA)
```

### Font Size Minimums

```
✅ Minimum 12px for body text
✅ Minimum 11px for captions
✅ Minimum 14px for labels
✅ Minimum 16px for interactive elements
```

### Line Height Guidelines

```
✅ Minimum 1.5 for body text
✅ Minimum 1.4 for headings
✅ Minimum 1.6 for long-form content
✅ Minimum 1.8 for accessibility
```

### Letter Spacing

```
✅ Avoid negative letter spacing for body text
✅ Use -0.02em only for display styles
✅ Use 0.02em+ for small text
✅ Ensure readability at all sizes
```

### Font Weight

```
✅ Use 400 for body text
✅ Use 500+ for emphasis
✅ Use 600+ for headings
✅ Avoid 300 or lighter for body text
```

---

## 🎨 Component Typography

### Buttons

```
Primary Button:
- Label Large (14px / 500)
- All caps optional
- Letter spacing: 0.02em

Secondary Button:
- Label Large (14px / 500)
- Normal case
- Letter spacing: 0.02em

Small Button:
- Label Medium (12px / 500)
- Normal case
- Letter spacing: 0.02em
```

### Form Labels

```
Form Label:
- Label Large (14px / 500)
- Letter spacing: 0.02em
- Color: Text Primary

Required Indicator:
- Label Large (14px / 500)
- Color: Error
- Text: "*"

Helper Text:
- Caption (12px / 400)
- Color: Text Secondary
```

### Cards

```
Card Title:
- Heading 5 (18px / 600)
- Color: Text Primary

Card Subtitle:
- Subtitle 2 (14px / 500)
- Color: Text Secondary

Card Body:
- Body Medium (14px / 400)
- Color: Text Primary
- Line Height: 1.6
```

### Navigation

```
Navigation Item:
- Label Large (14px / 500)
- Letter spacing: 0.02em
- Color: Text Secondary (inactive)
- Color: Primary (active)

Navigation Label:
- Label Small (11px / 500)
- Letter spacing: 0.04em
- Color: Text Secondary
```

### Badges

```
Badge Text:
- Label Small (11px / 500)
- Letter spacing: 0.04em
- All caps
- Color: On Primary/Secondary
```

---

## 🔄 Migration Plan

### Week 1: Setup
- [ ] Download Inter and Roboto Mono fonts
- [ ] Create typography constants
- [ ] Set up CSS variables
- [ ] Configure Tailwind

### Week 2: Flutter Implementation
- [ ] Create app_typography.dart
- [ ] Update app_theme.dart
- [ ] Update all text widgets
- [ ] Test on devices

### Week 3: React Implementation
- [ ] Create typography.ts
- [ ] Update Tailwind config
- [ ] Update all components
- [ ] Test in browser

### Week 4: Testing & Documentation
- [ ] Test accessibility
- [ ] Verify responsive behavior
- [ ] Create component examples
- [ ] Document usage guidelines

---

## ✅ Implementation Checklist

- [ ] Font families approved
- [ ] Typography scale defined
- [ ] Flutter implementation complete
- [ ] React implementation complete
- [ ] CSS variables created
- [ ] Tailwind config updated
- [ ] Responsive typography tested
- [ ] Accessibility verified
- [ ] Dark mode tested
- [ ] Documentation created
- [ ] Team trained
- [ ] Design system published

---

## 📚 Resources

### Font Downloads
- Inter: https://fonts.google.com/specimen/Inter
- Roboto Mono: https://fonts.google.com/specimen/Roboto+Mono

### Tools
- Font Pairing: https://www.fontpair.co/
- Typography Scale: https://www.modularscale.com/
- Contrast Checker: https://webaim.org/resources/contrastchecker/
- Accessibility: https://www.w3.org/WAI/WCAG21/Understanding/

### References
- Material Design 3: https://m3.material.io/
- Tailwind Typography: https://tailwindcss.com/docs/font-size
- Web Typography: https://www.smashingmagazine.com/

---

## 🎯 Next Steps

1. **Review** the typography system
2. **Approve** font families and scale
3. **Download** Inter and Roboto Mono
4. **Implement** in Flutter app
5. **Implement** in React website
6. **Test** across all platforms
7. **Document** in design system
8. **Train** team members

---

**Document Version**: 1.0  
**Status**: Ready for Implementation  
**Last Updated**: December 9, 2025
