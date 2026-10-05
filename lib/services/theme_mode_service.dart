import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeService {
  static const _themeModeKey = 'theme_mode';

  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMode = prefs.getString(_themeModeKey);

    switch (savedMode) {
      case 'light':
        mode.value = ThemeMode.light;
        break;

      case 'dark':
        mode.value = ThemeMode.dark;
        break;

      default:
        mode.value = ThemeMode.system;
    }
  }

  static Future<void> setMode(ThemeMode newMode) async {
    mode.value = newMode;

    final prefs = await SharedPreferences.getInstance();

    switch (newMode) {
      case ThemeMode.light:
        await prefs.setString(_themeModeKey, 'light');
        break;

      case ThemeMode.dark:
        await prefs.setString(_themeModeKey, 'dark');
        break;

      case ThemeMode.system:
        await prefs.setString(_themeModeKey, 'system');
        break;
    }
  }

  static String getModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';

      case ThemeMode.dark:
        return 'Dark';

      case ThemeMode.system:
        return 'System default';
    }
  }

  static IconData getModeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;

      case ThemeMode.dark:
        return Icons.dark_mode_outlined;

      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
