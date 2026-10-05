import 'package:flutter/material.dart';

import 'pages/startup_page.dart';
import 'services/theme_mode_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeModeService.load();

  runApp(const BudgetMonitoringApp());
}

class BudgetMonitoringApp extends StatelessWidget {
  const BudgetMonitoringApp({super.key});

  static const _seedColor = Color(0xFF6B5B73);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeModeService.mode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Budget Monitoring',

          themeMode: themeMode,

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),

          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: _seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),

          home: const StartupPage(),
        );
      },
    );
  }
}
