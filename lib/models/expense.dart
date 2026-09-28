import 'package:flutter/material.dart';

class Expense {
  final String category;
  final String description;
  final double amount;
  final IconData icon;
  final DateTime date;

  Expense({
    required this.category,
    required this.description,
    required this.amount,
    required this.icon,
    required this.date,
  });
}
