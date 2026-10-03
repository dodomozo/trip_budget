import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;

  const ExpenseCategory({required this.name, required this.icon});
}

class ExpenseCategories {
  static const List<ExpenseCategory> all = [
    ExpenseCategory(name: 'Food', icon: Icons.restaurant),
    ExpenseCategory(name: 'Transportation', icon: Icons.train),
    ExpenseCategory(name: 'Shopping', icon: Icons.shopping_bag),
    ExpenseCategory(name: 'Entertainment', icon: Icons.movie),
    ExpenseCategory(name: 'Drinks', icon: Icons.local_drink),
    ExpenseCategory(name: 'Sightseeing', icon: Icons.photo_camera),
    ExpenseCategory(name: 'Sports', icon: Icons.sports_basketball),
    ExpenseCategory(name: 'Groceries', icon: Icons.shopping_cart),
    ExpenseCategory(name: 'Gadgets', icon: Icons.devices),
    ExpenseCategory(name: 'Other', icon: Icons.receipt),
  ];

  static ExpenseCategory getByName(String name) {
    return all.firstWhere(
      (category) => category.name == name,
      orElse: () => all.last,
    );
  }

  static IconData getIcon(String name) {
    return getByName(name).icon;
  }
}
