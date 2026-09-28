import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ExpenseStorageService {
  static const _descriptionsKey = 'expense_descriptions';
  static const _categoriesKey = 'expense_categories';
  static const _amountsKey = 'expense_amounts';
  static const _datesKey = 'expense_dates';

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    final descriptions = prefs.getStringList(_descriptionsKey) ?? [];
    final categories = prefs.getStringList(_categoriesKey) ?? [];
    final amounts = prefs.getStringList(_amountsKey) ?? [];
    final dates = prefs.getStringList(_datesKey) ?? [];

    final expenses = <Expense>[];

    for (var i = 0; i < descriptions.length; i++) {
      expenses.add(
        Expense(
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

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _descriptionsKey,
      expenses.map((expense) => expense.description).toList(),
    );

    await prefs.setStringList(
      _categoriesKey,
      expenses.map((expense) => expense.category).toList(),
    );

    await prefs.setStringList(
      _amountsKey,
      expenses.map((expense) => expense.amount.toString()).toList(),
    );

    await prefs.setStringList(
      _datesKey,
      expenses.map((expense) => expense.date.toIso8601String()).toList(),
    );
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
