import 'package:flutter/material.dart';

import 'pages/budget_home_page.dart';
import 'models/trip.dart';

void main() {
  runApp(const BudgetMonitoringApp());
}

class BudgetMonitoringApp extends StatelessWidget {
  const BudgetMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Budget Monitoring',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: BudgetHomePage(
        trip: Trip(
          id: 'default-trip',
          name: 'Japan Business Trip',
          allowance: 200000,
          startDate: DateTime(2026, 9, 22),
          endDate: DateTime(2026, 12, 15),
        ),
      ),
    );
  }
}
