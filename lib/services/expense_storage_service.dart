import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ExpenseStorageService {
  String _key(String tripId, String type) {
    return 'trip_${tripId}_expense_$type';
  }

  Future<List<Expense>> loadExpenses(String tripId) async {
    final prefs = await SharedPreferences.getInstance();

    final descriptions =
        prefs.getStringList(_key(tripId, 'descriptions')) ?? [];
    final categories = prefs.getStringList(_key(tripId, 'categories')) ?? [];
    final amounts = prefs.getStringList(_key(tripId, 'amounts')) ?? [];
    final dates = prefs.getStringList(_key(tripId, 'dates')) ?? [];

    final expenses = <Expense>[];

    for (var i = 0; i < descriptions.length; i++) {
      expenses.add(
        Expense(
          tripId: tripId,
          description: descriptions[i],
          category: categories[i],
          amount: double.parse(amounts[i]),
          icon: getIcon(categories[i]),
          date: DateTime.parse(dates[i]),
        ),
      );
    }

    return expenses;
  }

  Future<void> saveExpenses(String tripId, List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key(tripId, 'descriptions'),
      expenses.map((expense) => expense.description).toList(),
    );

    await prefs.setStringList(
      _key(tripId, 'categories'),
      expenses.map((expense) => expense.category).toList(),
    );

    await prefs.setStringList(
      _key(tripId, 'amounts'),
      expenses.map((expense) => expense.amount.toString()).toList(),
    );

    await prefs.setStringList(
      _key(tripId, 'dates'),
      expenses.map((expense) => expense.date.toIso8601String()).toList(),
    );
  }

  Future<void> deleteExpenses(String tripId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key(tripId, 'descriptions'));
    await prefs.remove(_key(tripId, 'categories'));
    await prefs.remove(_key(tripId, 'amounts'));
    await prefs.remove(_key(tripId, 'dates'));
  }

  static IconData getIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.train;
      case 'Shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt;
    }
  }
}
