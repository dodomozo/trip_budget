import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../widgets/expense_item.dart';
import '../widgets/summary_card.dart';
import 'expense_history_page.dart';
import '../services/expense_storage_service.dart';

class BudgetHomePage extends StatefulWidget {
  const BudgetHomePage({super.key});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  static const totalAllowance = 200000.0;

  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final storage = ExpenseStorageService();
    final loadedExpenses = await storage.loadExpenses();

    if (!mounted) return;

    setState(() {
      expenses = loadedExpenses;
    });
  }

  Future<void> _saveExpenses() async {
    final storage = ExpenseStorageService();
    await storage.saveExpenses(expenses);
  }

  double get totalSpent {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double get remainingBudget {
    return totalAllowance - totalSpent;
  }

  Future<void> _addExpense() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    String selectedCategory = 'Food';

    final result = await showDialog<Expense>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Expense'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(
                        value: 'Transportation',
                        child: Text('Transportation'),
                      ),
                      DropdownMenuItem(
                        value: 'Shopping',
                        child: Text('Shopping'),
                      ),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '¥ ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final description = descriptionController.text.trim();

                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (description.isEmpty || amount == null) {
                      return;
                    }

                    Navigator.pop(
                      context,
                      Expense(
                        category: selectedCategory,
                        description: description,
                        amount: amount,
                        icon: ExpenseStorageService.getIcon(selectedCategory),
                        date: DateTime.now(),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    // descriptionController.dispose();
    // amountController.dispose();

    if (result == null) {
      return;
    }

    setState(() {
      expenses.add(result);
    });

    await _saveExpenses();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<Expense> get todaysExpenses {
    final now = DateTime.now();

    return expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day;
    }).toList();
  }

  Future<void> _openExpenseHistory() async {
    final updatedExpenses = await Navigator.push<List<Expense>>(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseHistoryPage(expenses: expenses),
      ),
    );

    if (updatedExpenses != null) {
      setState(() {
        expenses = updatedExpenses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Monitoring')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Japan Business Trip',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Remaining Budget',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${remainingBudget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: 'Allowance',
                    value: '¥${totalAllowance.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SummaryCard(
                    title: 'Spent',
                    value: '¥${totalSpent.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Spending",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _openExpenseHistory,
                  child: const Text('View All'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (todaysExpenses.isEmpty)
              const Text(
                'No expenses today.',
                style: TextStyle(color: Colors.grey),
              ),

            ...todaysExpenses.map(
              (expense) => ExpenseItem(
                category: expense.category,
                description: expense.description,
                amount: expense.amount,
                icon: expense.icon,
                date: _formatDate(expense.date),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}
