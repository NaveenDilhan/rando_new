import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeData> {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;

  ThemeNotifier._internal() : super(ThemeData.dark()); // Default to dark theme

  bool _isDarkMode = true; // Track the current theme mode

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    value = _isDarkMode ? ThemeData.dark() : ThemeData.light(); // Update the value
  }
} 