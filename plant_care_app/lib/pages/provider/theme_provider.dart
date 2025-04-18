import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  // Getters
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  // Load saved theme from SharedPreferences
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme') ?? 'light';
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(); // Persist the theme choice
    notifyListeners();
  }

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      color: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.green),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.lightGreen,
    scaffoldBackgroundColor: Colors.grey[900]!,
    cardColor: Colors.grey[800]!,
    appBarTheme: AppBarTheme(
      color: Colors.grey[900]!,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}