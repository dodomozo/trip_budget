import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      home: const BudgetHomePage(),
    );
  }
}

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
    final prefs = await SharedPreferences.getInstance();

    final descriptions = prefs.getStringList('expense_descriptions') ?? [];
    final categories = prefs.getStringList('expense_categories') ?? [];
    final amounts = prefs.getStringList('expense_amounts') ?? [];
    final dates = prefs.getStringList('expense_dates') ?? [];

    final loadedExpenses = <Expense>[];

    for (var i = 0; i < descriptions.length; i++) {
      loadedExpenses.add(
        Expense(
          description: descriptions[i],
          category: categories[i],
          amount: double.parse(amounts[i]),
          icon: _getIcon(categories[i]),
          date: DateTime.parse(dates[i]),
        ),
      );
    }

    setState(() {
      expenses = loadedExpenses;
    });
  }

  Future<void> _saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'expense_descriptions',
      expenses.map((expense) => expense.description).toList(),
    );

    await prefs.setStringList(
      'expense_categories',
      expenses.map((expense) => expense.category).toList(),
    );

    await prefs.setStringList(
      'expense_amounts',
      expenses.map((expense) => expense.amount.toString()).toList(),
    );

    await prefs.setStringList(
      'expense_dates',
      expenses.map((expense) => expense.date.toIso8601String()).toList(),
    );
  }

  IconData _getIcon(String category) {
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
                        icon: _getIcon(selectedCategory),
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
                  child: _SummaryCard(
                    title: 'Allowance',
                    value: '¥${totalAllowance.toStringAsFixed(0)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Spent',
                    value: '¥${totalSpent.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Today's Spending",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            if (expenses.isEmpty)
              const Text(
                'No expenses yet.',
                style: TextStyle(color: Colors.grey),
              ),

            ...expenses.map(
              (expense) => _ExpenseItem(
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseItem extends StatelessWidget {
  final String category;
  final String description;
  final double amount;
  final IconData icon;
  final String date;

  const _ExpenseItem({
    required this.category,
    required this.description,
    required this.amount,
    required this.icon,
    required this.date,
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
          '¥${amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
