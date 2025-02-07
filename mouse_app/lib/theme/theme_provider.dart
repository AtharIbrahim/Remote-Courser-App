import 'package:flutter/material.dart';
import 'package:mouse_app/theme/dark_theme.dart';
import 'package:mouse_app/theme/light_theme.dart';

class ThemeProvider with ChangeNotifier {
  // Initial Theme is light mode
  ThemeData _themeData = lightMode;

  // Access that which is connected now
  ThemeData get themeData => _themeData;

  // get method to chekc if we are in dark mode or not
  bool get isDarkMode => _themeData == darkMode;

  // Setter method to set the new theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  // Toogle between light and dark mode later on...
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
