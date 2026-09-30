import 'package:flutter/material.dart';

import 'expense_history_page.dart';
import 'trip_list_page.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../widgets/expense_item.dart';
import '../widgets/summary_card.dart';
import '../services/expense_storage_service.dart';

class BudgetHomePage extends StatefulWidget {
  final Trip trip;

  const BudgetHomePage({super.key, required this.trip});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  late Trip trip;
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();

    trip = widget.trip;

    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final storage = ExpenseStorageService();
    final loadedExpenses = await storage.loadExpenses(trip.id);

    if (!mounted) return;

    setState(() {
      expenses = loadedExpenses;
    });
  }

  Future<void> _saveExpenses() async {
    final storage = ExpenseStorageService();
    await storage.saveExpenses(trip.id, expenses);
  }

  double get totalSpent {
    return expenses.fold(0, (sum, expense) => sum + expense.totalAmount);
  }

  double get remainingBudget {
    return trip.allowance - totalSpent;
  }

  int get remainingDays {
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);

    final endDate = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );

    final days = endDate.difference(todayDate).inDays;

    return days < 0 ? 0 : days + 1;
  }

  double get recommendedDailyBudget {
    if (remainingDays <= 0) {
      return 0;
    }

    return remainingBudget / remainingDays;
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
                        tripId: trip.id,
                        category: selectedCategory,
                        description: description,
                        dailyAmounts: {
                          DateTime(
                            DateTime.now().year,
                            DateTime.now().month,
                            DateTime.now().day,
                          ): amount,
                        },
                        icon: ExpenseStorageService.getIcon(selectedCategory),
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
    final today = DateTime(now.year, now.month, now.day);

    return expenses.where((expense) {
      return expense.dailyAmounts.keys.any((date) {
        final expenseDate = DateTime(date.year, date.month, date.day);

        return expenseDate == today;
      });
    }).toList();
  }

  double get todaysSpending {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return expenses.fold(0, (sum, expense) {
      for (final entry in expense.dailyAmounts.entries) {
        final date = DateTime(entry.key.year, entry.key.month, entry.key.day);

        if (date == today) {
          sum += entry.value;
        }
      }

      return sum;
    });
  }

  double get dailyBudgetDifference {
    return recommendedDailyBudget - todaysSpending;
  }

  double get averageDailySpending {
    if (totalSpent == 0) {
      return 0;
    }

    final daysElapsed = trip.totalDays - remainingDays + 1;

    if (daysElapsed <= 0) {
      return 0;
    }

    return totalSpent / daysElapsed;
  }

  double get projectedTotalSpending {
    return averageDailySpending * trip.totalDays;
  }

  double get projectedRemainingBudget {
    return trip.allowance - projectedTotalSpending;
  }

  String get dailyBudgetStatus {
    if (todaysSpending == 0) {
      return 'No spending today';
    }

    if (dailyBudgetDifference >= 0) {
      return 'Within daily budget';
    }

    return 'Over daily budget';
  }

  Future<void> _openExpenseHistory() async {
    final updatedExpenses = await Navigator.push<List<Expense>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ExpenseHistoryPage(tripId: trip.id, expenses: expenses),
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
      appBar: AppBar(
        title: Text(trip.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_copy_outlined),
            tooltip: 'My Trips',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TripListPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            Text(
              '${_formatDate(trip.startDate)} → ${_formatDate(trip.endDate)}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),

            Text(
              '$remainingDays days remaining',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
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

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Daily Budget',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${recommendedDailyBudget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Based on your remaining budget and trip days',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Spending Forecast',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¥${projectedTotalSpending.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Projected total spending',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      projectedRemainingBudget >= 0
                          ? 'Projected remaining: ¥${projectedRemainingBudget.toStringAsFixed(0)}'
                          : 'Projected over budget: ¥${projectedRemainingBudget.abs().toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
                    value: '¥${trip.allowance.toStringAsFixed(0)}',
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
            const SizedBox(height: 4),

            Text(
              '¥${todaysSpending.toStringAsFixed(0)} spent today',
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 4),

            Text(
              dailyBudgetStatus,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              dailyBudgetDifference >= 0
                  ? '¥${dailyBudgetDifference.toStringAsFixed(0)} remaining for today'
                  : '¥${dailyBudgetDifference.abs().toStringAsFixed(0)} over today\'s budget',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),

            const SizedBox(height: 12),

            if (todaysExpenses.isEmpty)
              const Text(
                'No expenses today.',
                style: TextStyle(color: Colors.grey),
              ),

            ...todaysExpenses.map((expense) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              final todayAmount = expense.dailyAmounts.entries
                  .where(
                    (entry) =>
                        DateTime(
                          entry.key.year,
                          entry.key.month,
                          entry.key.day,
                        ) ==
                        today,
                  )
                  .fold<double>(0, (sum, entry) => sum + entry.value);

              return ExpenseItem(
                category: expense.category,
                description: expense.description,
                amount: todayAmount,
                icon: expense.icon,
                date: _formatDate(today),
              );
            }),
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
