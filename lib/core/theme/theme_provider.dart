import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = AppTheme.darkTheme;
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemeFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = !_isDarkMode;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = isDark;
    _themeData = _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
} 