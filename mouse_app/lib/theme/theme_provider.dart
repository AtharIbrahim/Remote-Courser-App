import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mouse_app/theme/dark_theme.dart';
import 'package:mouse_app/theme/light_theme.dart';

class ThemeProvider with ChangeNotifier {
  // Initial Theme is light mode
  ThemeData _themeData = lightMode;

  // Access the current theme
  ThemeData get themeData => _themeData;

  // Check if we are in dark mode or not
  bool get isDarkMode => _themeData == darkMode;

  // Constructor to load saved theme on app start
  ThemeProvider() {
    _loadTheme();
  }

  // Setter method to set the new theme and save it
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    _saveTheme(); // Save the theme preference
    notifyListeners();
  }

  // Toggle between light and dark mode
  void toggleTheme() {
    themeData = isDarkMode ? lightMode : darkMode;
  }

  // Load the saved theme preference
  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDarkMode =
        prefs.getBool('is_dark_mode') ?? false; // Default to light mode
    _themeData = isDarkMode ? darkMode : lightMode;
    notifyListeners();
  }

  // Save the current theme preference
  void _saveTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('is_dark_mode', isDarkMode);
  }
}
