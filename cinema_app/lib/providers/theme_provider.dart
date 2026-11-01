import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider quản lý chế độ sáng / tối (Theme)
class ThemeProvider extends ChangeNotifier {
  ThemeProvider._();

  static final ThemeProvider instance = ThemeProvider._();
  factory ThemeProvider() => instance;

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool('app_is_dark_mode') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_dark_mode', _isDarkMode);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('app_is_dark_mode', _isDarkMode);
    } catch (_) {}
  }
}
