import 'package:flutter/material.dart';

import '../services/currency_service.dart';

class ExpenseItem extends StatelessWidget {
  final String category;
  final String description;
  final double amount;
  final IconData icon;
  final String date;
  final String currencyCode;

  const ExpenseItem({
    super.key,
    required this.category,
    required this.description,
    required this.amount,
    required this.icon,
    required this.date,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(description),
        subtitle: Text('$category • $date'),
        trailing: Text(
          CurrencyService.format(amount, currencyCode),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
