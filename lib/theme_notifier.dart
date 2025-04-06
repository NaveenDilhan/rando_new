import 'package:flutter/material.dart';

class ThemeNotifier extends ValueNotifier<ThemeData> {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;

  ThemeNotifier._internal() : super(ThemeData.dark()); // Default to dark theme

  bool _isDarkMode = true; // Track the current theme mode
  double _fontSize = 16.0; // Default font size

  // Public getter for font size
  double get fontSize => _fontSize;

  // Getter to check if dark mode is enabled
  bool get isDarkMode => _isDarkMode;

  // Current theme based on dark mode and font size
  ThemeData get currentTheme {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: _fontSize, color: Colors.white),
              bodyMedium: TextStyle(fontSize: _fontSize, color: Colors.white),
              displayLarge: TextStyle(fontSize: _fontSize + 4, color: Colors.white), // Example for larger text
              // Add more styles as needed
            ),
          )
        : ThemeData.light().copyWith(
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontSize: _fontSize, color: Colors.black),
              bodyMedium: TextStyle(fontSize: _fontSize, color: Colors.black),
              displayLarge: TextStyle(fontSize: _fontSize + 4, color: Colors.black), // Example for larger text
              // Add more styles as needed
            ),
          );
  }

  // Toggle theme between dark and light
  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    value = currentTheme; // Update the theme value
    notifyListeners(); // Notify listeners to rebuild the UI
  }

  // Set font size and update the theme
  void setFontSize(double fontSize) {
    _fontSize = fontSize;
    value = currentTheme; // Update the theme value
    notifyListeners(); // Notify listeners to rebuild the UI
  }
}
