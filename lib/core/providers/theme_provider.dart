import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A provider that manages the app's theme state and persistence
class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _themeAnimationKey = 'theme_animation_duration';
  static const _defaultAnimationDuration = Duration(milliseconds: 300);

  final SharedPreferences _prefs;
  late ThemeMode _themeMode;
  Duration _animationDuration;
  bool _initialized = false;
  SchedulerBinding? _schedulerBinding;
  
  // Constructor with dependency injection
  ThemeProvider(this._prefs) : _animationDuration = _defaultAnimationDuration {
    _initializeTheme();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  Duration get animationDuration => _animationDuration;
  bool get initialized => _initialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
    (_themeMode == ThemeMode.system && _isPlatformDarkMode);

  bool get _isPlatformDarkMode {
    if (_schedulerBinding?.platformDispatcher == null) return false;
    final brightness = _schedulerBinding!.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  /// Initialize the theme provider
  void _initializeTheme() {
    try {
      _schedulerBinding = SchedulerBinding.instance;
      _loadSavedTheme();
      _loadAnimationDuration();
      _initialized = true;
      
      // Listen for system theme changes
      _schedulerBinding?.platformDispatcher.onPlatformBrightnessChanged = _onPlatformBrightnessChanged;
      
      developer.log(
        'Theme initialized: $_themeMode',
        name: 'ThemeProvider',
      );
    } catch (e) {
      developer.log(
        'Error initializing theme: $e',
        name: 'ThemeProvider',
        error: e,
      );
      // Fallback to light theme if initialization fails
      _themeMode = ThemeMode.light;
      _initialized = true;
    }
  }

  /// Load the saved theme from preferences
  void _loadSavedTheme() {
    try {
      final savedTheme = _prefs.getString(_themeKey)?.toLowerCase();
      switch (savedTheme) {
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.system; // Default to system theme
      }
    } catch (e) {
      developer.log(
        'Error loading saved theme: $e',
        name: 'ThemeProvider',
        error: e,
      );
      _themeMode = ThemeMode.system; // Fallback to system theme
    }
  }

  /// Load the saved animation duration from preferences
  void _loadAnimationDuration() {
    try {
      final savedDuration = _prefs.getInt(_themeAnimationKey);
      if (savedDuration != null) {
        _animationDuration = Duration(milliseconds: savedDuration);
      }
    } catch (e) {
      developer.log(
        'Error loading animation duration: $e',
        name: 'ThemeProvider',
        error: e,
      );
      _animationDuration = _defaultAnimationDuration;
    }
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set a specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    try {
      _themeMode = mode;
      await _persistThemeMode();
      notifyListeners();
      
      developer.log(
        'Theme changed to: $mode',
        name: 'ThemeProvider',
      );
    } catch (e) {
      developer.log(
        'Error setting theme mode: $e',
        name: 'ThemeProvider',
        error: e,
      );
      // Revert to previous theme if persistence fails
      _loadSavedTheme();
      notifyListeners();
    }
  }

  /// Set the theme animation duration
  Future<void> setAnimationDuration(Duration duration) async {
    if (_animationDuration == duration) return;

    try {
      _animationDuration = duration;
      await _prefs.setInt(_themeAnimationKey, duration.inMilliseconds);
      notifyListeners();
    } catch (e) {
      developer.log(
        'Error setting animation duration: $e',
        name: 'ThemeProvider',
        error: e,
      );
      // Revert to previous duration if persistence fails
      _loadAnimationDuration();
      notifyListeners();
    }
  }

  /// Handle system theme changes
  void _onPlatformBrightnessChanged() {
    if (_themeMode == ThemeMode.system) {
      notifyListeners(); // Update UI when system theme changes
    }
  }

  /// Persist theme mode to shared preferences
  Future<void> _persistThemeMode() async {
    final themeString = _themeMode.toString().split('.').last;
    await _prefs.setString(_themeKey, themeString);
  }

  @override
  void dispose() {
    // Remove system theme change listener
    if (_schedulerBinding?.platformDispatcher != null) {
      _schedulerBinding!.platformDispatcher.onPlatformBrightnessChanged = null;
    }
    super.dispose();
  }
}
