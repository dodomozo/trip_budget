import 'package:flutter/material.dart';

class Expense {
  final String tripId;
  final String category;
  final String description;
  final Map<DateTime, double> dailyAmounts;
  final IconData icon;

  Expense({
    required this.tripId,
    required this.category,
    required this.description,
    required this.dailyAmounts,
    required this.icon,
  });

  double get totalAmount {
    return dailyAmounts.values.fold(0, (total, amount) => total + amount);
  }
}
