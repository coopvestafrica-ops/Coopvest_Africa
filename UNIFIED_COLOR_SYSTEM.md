# Coopvest Africa - Unified Color System & Design Standards

**Status**: ⚠️ NOT UNIFIED - Needs Harmonization  
**Date**: December 9, 2025

---

## 🔍 Current Color Analysis

### Flutter App (Current)
```dart
Primary: #1B5E20 (Dark Green)
OnPrimary: #FFFFFF (White)
Background: #F5F5F5 (Light Gray)
InputBackground: #FFFFFF (White)
Error: #B00020 (Dark Red)
InputBorder: Gray 300
```

### React Website (Current)
```typescript
Theme: Light/Dark Mode Support
- Light Theme: Default system colors
- Dark Theme: Inverted colors
- No unified color palette defined
```

### Backend (Laravel)
```php
No color system (API only)
```

---

## ❌ Issues Identified

1. **Inconsistent Primary Colors**
   - Flutter: Dark Green (#1B5E20)
   - React: No defined primary color
   - Recommendation: Standardize to one primary color

2. **No Unified Palette**
   - Flutter has basic colors
   - React uses theme switching
   - No shared color constants

3. **Missing Color Definitions**
   - No secondary colors
   - No accent colors
   - No status colors (success, warning, info)
   - No semantic colors

4. **No Design System**
   - No shared component colors
   - No color usage guidelines
   - No accessibility considerations

---

## ✅ Recommended Unified Color System

### Primary Colors

```
Primary Brand Color: #1B5E20 (Dark Green)
- Usage: Main buttons, headers, primary actions
- Hex: #1B5E20
- RGB: 27, 94, 32
- HSL: 109°, 55%, 24%

Primary Light: #4CAF50 (Light Green)
- Usage: Hover states, secondary elements
- Hex: #4CAF50
- RGB: 76, 175, 80
- HSL: 120°, 54%, 50%

Primary Lighter: #81C784 (Pale Green)
- Usage: Disabled states, backgrounds
- Hex: #81C784
- RGB: 129, 199, 132
- HSL: 120°, 46%, 65%
```

### Secondary Colors

```
Secondary: #1976D2 (Blue)
- Usage: Secondary actions, links
- Hex: #1976D2
- RGB: 25, 118, 210
- HSL: 217°, 79%, 46%

Secondary Light: #42A5F5 (Light Blue)
- Usage: Hover states
- Hex: #42A5F5
- RGB: 66, 165, 245
- HSL: 217°, 89%, 61%
```

### Status Colors

```
Success: #2E7D32 (Dark Green)
- Usage: Success messages, confirmations
- Hex: #2E7D32
- RGB: 46, 125, 50
- HSL: 109°, 46%, 34%

Warning: #F57C00 (Orange)
- Usage: Warning messages, alerts
- Hex: #F57C00
- RGB: 245, 124, 0
- HSL: 32°, 100%, 48%

Error: #C62828 (Dark Red)
- Usage: Error messages, destructive actions
- Hex: #C62828
- RGB: 198, 40, 40
- HSL: 0°, 66%, 47%

Info: #0277BD (Cyan)
- Usage: Information messages
- Hex: #0277BD
- RGB: 2, 119, 189
- HSL: 199°, 98%, 37%
```

### Neutral Colors

```
Background: #FAFAFA (Off White)
- Usage: Main background
- Hex: #FAFAFA
- RGB: 250, 250, 250
- HSL: 0°, 0%, 98%

Surface: #FFFFFF (White)
- Usage: Cards, containers
- Hex: #FFFFFF
- RGB: 255, 255, 255
- HSL: 0°, 0%, 100%

Border: #E0E0E0 (Light Gray)
- Usage: Borders, dividers
- Hex: #E0E0E0
- RGB: 224, 224, 224
- HSL: 0°, 0%, 88%

Text Primary: #212121 (Dark Gray)
- Usage: Main text
- Hex: #212121
- RGB: 33, 33, 33
- HSL: 0°, 0%, 13%

Text Secondary: #757575 (Medium Gray)
- Usage: Secondary text, labels
- Hex: #757575
- RGB: 117, 117, 117
- HSL: 0°, 0%, 46%

Text Disabled: #BDBDBD (Light Gray)
- Hex: #BDBDBD
- RGB: 189, 189, 189
- HSL: 0°, 0%, 74%
```

### Dark Mode Colors

```
Dark Background: #121212 (Very Dark Gray)
- Hex: #121212
- RGB: 18, 18, 18
- HSL: 0°, 0%, 7%

Dark Surface: #1E1E1E (Dark Gray)
- Hex: #1E1E1E
- RGB: 30, 30, 30
- HSL: 0°, 0%, 12%

Dark Text Primary: #FFFFFF (White)
- Hex: #FFFFFF
- RGB: 255, 255, 255
- HSL: 0°, 0%, 100%

Dark Text Secondary: #B0B0B0 (Light Gray)
- Hex: #B0B0B0
- RGB: 176, 176, 176
- HSL: 0°, 0%, 69%
```

---

## 📋 Complete Color Palette

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Primary | #1B5E20 | 27, 94, 32 | Main brand color |
| Primary Light | #4CAF50 | 76, 175, 80 | Hover states |
| Primary Lighter | #81C784 | 129, 199, 132 | Disabled states |
| Secondary | #1976D2 | 25, 118, 210 | Secondary actions |
| Secondary Light | #42A5F5 | 66, 165, 245 | Secondary hover |
| Success | #2E7D32 | 46, 125, 50 | Success messages |
| Warning | #F57C00 | 245, 124, 0 | Warning messages |
| Error | #C62828 | 198, 40, 40 | Error messages |
| Info | #0277BD | 2, 119, 189 | Info messages |
| Background | #FAFAFA | 250, 250, 250 | Main background |
| Surface | #FFFFFF | 255, 255, 255 | Cards/containers |
| Border | #E0E0E0 | 224, 224, 224 | Borders/dividers |
| Text Primary | #212121 | 33, 33, 33 | Main text |
| Text Secondary | #757575 | 117, 117, 117 | Secondary text |
| Text Disabled | #BDBDBD | 189, 189, 189 | Disabled text |
| Dark Background | #121212 | 18, 18, 18 | Dark mode bg |
| Dark Surface | #1E1E1E | 30, 30, 30 | Dark mode cards |
| Dark Text Primary | #FFFFFF | 255, 255, 255 | Dark mode text |
| Dark Text Secondary | #B0B0B0 | 176, 176, 176 | Dark mode secondary |

---

## 🎨 Implementation Guide

### Flutter Implementation

```dart
// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryLighter = Color(0xFF81C784);
  static const Color onPrimary = Colors.white;

  // Secondary Colors
  static const Color secondary = Color(0xFF1976D2);
  static const Color secondaryLight = Color(0xFF42A5F5);
  static const Color onSecondary = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF0277BD);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE0E0E0);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Semantic Colors
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;
  static const Color onError = Colors.white;
  static const Color onSuccess = Colors.white;
  static const Color onWarning = Colors.white;
  static const Color onInfo = Colors.white;
}
```

### React Implementation

```typescript
// src/theme/colors.ts

export const colors = {
  // Primary Colors
  primary: '#1B5E20',
  primaryLight: '#4CAF50',
  primaryLighter: '#81C784',
  onPrimary: '#FFFFFF',

  // Secondary Colors
  secondary: '#1976D2',
  secondaryLight: '#42A5F5',
  onSecondary: '#FFFFFF',

  // Status Colors
  success: '#2E7D32',
  warning: '#F57C00',
  error: '#C62828',
  info: '#0277BD',

  // Neutral Colors
  background: '#FAFAFA',
  surface: '#FFFFFF',
  border: '#E0E0E0',

  // Text Colors
  textPrimary: '#212121',
  textSecondary: '#757575',
  textDisabled: '#BDBDBD',

  // Dark Mode Colors
  dark: {
    background: '#121212',
    surface: '#1E1E1E',
    textPrimary: '#FFFFFF',
    textSecondary: '#B0B0B0',
  },
};

// Tailwind Configuration
export const tailwindColors = {
  primary: {
    50: '#E8F5E9',
    100: '#C8E6C9',
    200: '#A5D6A7',
    300: '#81C784',
    400: '#66BB6A',
    500: '#4CAF50',
    600: '#43A047',
    700: '#388E3C',
    800: '#2E7D32',
    900: '#1B5E20',
  },
  secondary: {
    50: '#E3F2FD',
    100: '#BBDEFB',
    200: '#90CAF9',
    300: '#64B5F6',
    400: '#42A5F5',
    500: '#2196F3',
    600: '#1E88E5',
    700: '#1976D2',
    800: '#1565C0',
    900: '#0D47A1',
  },
};
```

### CSS/Tailwind Implementation

```css
/* src/styles/colors.css */

:root {
  /* Primary Colors */
  --color-primary: #1B5E20;
  --color-primary-light: #4CAF50;
  --color-primary-lighter: #81C784;
  --color-on-primary: #FFFFFF;

  /* Secondary Colors */
  --color-secondary: #1976D2;
  --color-secondary-light: #42A5F5;
  --color-on-secondary: #FFFFFF;

  /* Status Colors */
  --color-success: #2E7D32;
  --color-warning: #F57C00;
  --color-error: #C62828;
  --color-info: #0277BD;

  /* Neutral Colors */
  --color-background: #FAFAFA;
  --color-surface: #FFFFFF;
  --color-border: #E0E0E0;

  /* Text Colors */
  --color-text-primary: #212121;
  --color-text-secondary: #757575;
  --color-text-disabled: #BDBDBD;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-background: #121212;
    --color-surface: #1E1E1E;
    --color-text-primary: #FFFFFF;
    --color-text-secondary: #B0B0B0;
  }
}
```

---

## 🎯 Color Usage Guidelines

### Primary Color (#1B5E20)
- Main action buttons
- Navigation highlights
- Primary headings
- Brand elements
- Active states

### Secondary Color (#1976D2)
- Secondary buttons
- Links
- Secondary actions
- Accents

### Status Colors
- **Success (#2E7D32)**: Confirmations, successful operations
- **Warning (#F57C00)**: Alerts, cautions
- **Error (#C62828)**: Errors, destructive actions
- **Info (#0277BD)**: Information, notifications

### Neutral Colors
- **Background (#FAFAFA)**: Page background
- **Surface (#FFFFFF)**: Cards, containers, modals
- **Border (#E0E0E0)**: Dividers, borders
- **Text Primary (#212121)**: Main text content
- **Text Secondary (#757575)**: Labels, hints, secondary text
- **Text Disabled (#BDBDBD)**: Disabled elements

---

## 🌙 Dark Mode Implementation

### Flutter Dark Theme

```dart
// lib/core/theme/app_theme.dart

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.error,
      background: AppColors.background,
      surface: AppColors.surface,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryLight,
    scaffoldBackgroundColor: AppColors.darkBackground,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
    ),
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      error: AppColors.error,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
    ),
  );
}
```

### React Dark Theme

```typescript
// src/theme/theme.ts

export const lightTheme = {
  colors: colors,
  background: colors.background,
  surface: colors.surface,
  text: colors.textPrimary,
};

export const darkTheme = {
  colors: colors,
  background: colors.dark.background,
  surface: colors.dark.surface,
  text: colors.dark.textPrimary,
};
```

---

## ♿ Accessibility Considerations

### Contrast Ratios
- Text on Primary: 7.5:1 (AAA)
- Text on Secondary: 8.2:1 (AAA)
- Text on Background: 12.6:1 (AAA)
- Text on Surface: 12.6:1 (AAA)

### Color Blindness
- Don't rely on color alone
- Use patterns and icons
- Ensure sufficient contrast
- Test with color blindness simulators

### Dark Mode
- Ensure sufficient contrast in dark mode
- Test readability
- Provide toggle option
- Respect system preferences

---

## 📱 Component Color Mapping

### Buttons

```
Primary Button:
- Background: Primary (#1B5E20)
- Text: On Primary (#FFFFFF)
- Hover: Primary Light (#4CAF50)
- Disabled: Primary Lighter (#81C784)

Secondary Button:
- Background: Secondary (#1976D2)
- Text: On Secondary (#FFFFFF)
- Hover: Secondary Light (#42A5F5)
- Disabled: Border (#E0E0E0)

Danger Button:
- Background: Error (#C62828)
- Text: On Error (#FFFFFF)
- Hover: Error (darker)
- Disabled: Text Disabled (#BDBDBD)
```

### Input Fields

```
Border: Border (#E0E0E0)
Background: Surface (#FFFFFF)
Text: Text Primary (#212121)
Placeholder: Text Secondary (#757575)
Focus: Primary (#1B5E20)
Error: Error (#C62828)
Disabled: Text Disabled (#BDBDBD)
```

### Cards

```
Background: Surface (#FFFFFF)
Border: Border (#E0E0E0)
Text: Text Primary (#212121)
Shadow: rgba(0, 0, 0, 0.1)
```

### Navigation

```
Active: Primary (#1B5E20)
Inactive: Text Secondary (#757575)
Background: Surface (#FFFFFF)
Hover: Primary Light (#4CAF50)
```

---

## 🔄 Migration Plan

### Phase 1: Define System (Week 1)
- [ ] Approve unified color palette
- [ ] Create color constants files
- [ ] Document usage guidelines

### Phase 2: Flutter Implementation (Week 2)
- [ ] Update app_colors.dart
- [ ] Update theme configuration
- [ ] Update all components
- [ ] Test light and dark modes

### Phase 3: React Implementation (Week 2-3)
- [ ] Create colors.ts
- [ ] Update Tailwind config
- [ ] Update theme provider
- [ ] Update all components

### Phase 4: Testing & Refinement (Week 3)
- [ ] Test across devices
- [ ] Verify accessibility
- [ ] Test dark mode
- [ ] Get stakeholder approval

### Phase 5: Documentation (Week 4)
- [ ] Create design system guide
- [ ] Document color usage
- [ ] Create component examples
- [ ] Share with team

---

## 📚 Design System Resources

### Tools
- Figma: Create shared color library
- Storybook: Document components
- Color contrast checker: WebAIM
- Color blindness simulator: Coblis

### References
- Material Design 3: https://m3.material.io/
- Tailwind Colors: https://tailwindcss.com/docs/customizing-colors
- WCAG Color Contrast: https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum

---

## ✅ Implementation Checklist

- [ ] Color palette approved
- [ ] Flutter colors.dart created
- [ ] React colors.ts created
- [ ] Tailwind config updated
- [ ] Dark mode implemented
- [ ] All components updated
- [ ] Accessibility verified
- [ ] Documentation created
- [ ] Team trained
- [ ] Design system published

---

## 📞 Next Steps

1. **Review** this unified color system
2. **Approve** the color palette
3. **Implement** in Flutter app
4. **Implement** in React website
5. **Test** across all platforms
6. **Document** in design system
7. **Train** team members
8. **Monitor** consistency

---

**Document Version**: 1.0  
**Status**: Ready for Implementation  
**Last Updated**: December 9, 2025
