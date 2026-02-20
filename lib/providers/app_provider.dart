import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:jsontry/models/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  late SharedPreferences _sharedPreferences;
  Settings _settings = Settings.empty;

  ThemeMode get themeMode => _settings.themeMode;

  AppProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    var savedSettings = _sharedPreferences.getString("settings");
    _settings = savedSettings == null ? Settings.empty : Settings.fromJson(jsonDecode(savedSettings));
    notifyListeners();
  }

  void handleToggleThemeMode(ThemeMode mode) {
    _settings = _settings.copyWith(themeMode: mode);
    _saveSettingToStorage();
    notifyListeners();
  }

  void _saveSettingToStorage() {
    _sharedPreferences.setString("settings", jsonEncode(_settings.toJson()));
  }
}
