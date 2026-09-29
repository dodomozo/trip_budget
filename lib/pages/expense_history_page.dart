import 'package:flutter/material.dart';

import '../services/expense_storage_service.dart';
import '../models/expense.dart';
import '../widgets/expense_item.dart';

class ExpenseHistoryPage extends StatefulWidget {
  final String tripId;
  final List<Expense> expenses;

  const ExpenseHistoryPage({
    super.key,
    required this.tripId,
    required this.expenses,
  });

  @override
  State<ExpenseHistoryPage> createState() => _ExpenseHistoryPageState();
}

class _ExpenseHistoryPageState extends State<ExpenseHistoryPage> {
  late List<Expense> expenses;

  @override
  void initState() {
    super.initState();
    expenses = [...widget.expenses];
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _saveExpenses() async {
    final storage = ExpenseStorageService();
    await storage.saveExpenses(widget.tripId, expenses);
  }

  Future<bool> _confirmDelete(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense?'),
          content: Text(
            'Are you sure you want to delete "${expense.description}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteExpenseAfterConfirmation(Expense expense) async {
    setState(() {
      expenses.remove(expense);
    });

    await _saveExpenses();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${expense.description} deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final sortedExpenses = [...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, expenses);
          },
        ),
      ),
      body: sortedExpenses.isEmpty
          ? const Center(
              child: Text(
                'No expenses yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedExpenses.length,
              itemBuilder: (context, index) {
                final expense = sortedExpenses[index];

                return Dismissible(
                  key: ObjectKey(expense),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    return await _confirmDelete(expense);
                  },
                  onDismissed: (_) {
                    _deleteExpenseAfterConfirmation(expense);
                  },
                  child: ExpenseItem(
                    category: expense.category,
                    description: expense.description,
                    amount: expense.amount,
                    icon: expense.icon,
                    date: _formatDate(expense.date),
                  ),
                );
              },
            ),
    );
  }
}
