import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

class ExpenseStorageService {
  String _key(String tripId, String type) {
    return 'trip_${tripId}_expense_$type';
  }

  String _formatDateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDateKey(String value) {
    return DateTime.parse(value);
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
      if (i >= categories.length || i >= amounts.length || i >= dates.length) {
        continue;
      }

      final rawAmount = amounts[i];

      Map<DateTime, double> dailyAmounts;

      // New format: JSON containing one or more date/amount pairs.
      try {
        final decoded = jsonDecode(rawAmount);

        if (decoded is Map<String, dynamic>) {
          dailyAmounts = {};

          for (final entry in decoded.entries) {
            final date = _parseDateKey(entry.key);
            final amount = (entry.value as num).toDouble();

            dailyAmounts[DateTime(date.year, date.month, date.day)] = amount;
          }
        } else {
          throw const FormatException();
        }
      } catch (_) {
        // Old format: a single numeric amount + single date.
        final amount = double.tryParse(rawAmount);

        if (amount == null) {
          continue;
        }

        final date = DateTime.parse(dates[i]);

        dailyAmounts = {DateTime(date.year, date.month, date.day): amount};
      }

      if (dailyAmounts.isEmpty) {
        continue;
      }

      expenses.add(
        Expense(
          tripId: tripId,
          description: descriptions[i],
          category: categories[i],
          dailyAmounts: dailyAmounts,
          icon: getIcon(categories[i]),
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
      expenses
          .map(
            (expense) => jsonEncode(
              expense.dailyAmounts.map(
                (date, amount) => MapEntry(_formatDateKey(date), amount),
              ),
            ),
          )
          .toList(),
    );

    await prefs.setStringList(
      _key(tripId, 'dates'),
      expenses
          .map((expense) => _formatDateKey(expense.dailyAmounts.keys.first))
          .toList(),
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
