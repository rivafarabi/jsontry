import 'package:flutter/material.dart';

class Settings {
  final ThemeMode themeMode;

  Settings({required this.themeMode});

  Settings copyWith({ThemeMode? themeMode}) => Settings(
        themeMode: themeMode ?? this.themeMode,
      );

  Map<String, dynamic> toJson() {
    return {
      "themeMode": themeMode.name,
    };
  }

  static Settings fromJson(Map data) {
    return Settings(
      themeMode: ThemeMode.values.firstWhere((e) => e.name == (data["themeMode"] ?? ThemeMode.system.name)),
    );
  }

  static Settings empty = Settings(themeMode: ThemeMode.system);
}
