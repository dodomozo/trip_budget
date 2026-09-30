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
    final result = await showDialog<Expense>(
      context: context,
      builder: (dialogContext) {
        return AddExpenseDialog(trip: trip);
      },
    );

    if (result == null || !mounted) {
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
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);

    return expenses.where((expense) {
      final amount = expense.dailyAmounts[todayDate] ?? 0;

      return amount > 0;
    }).toList();
  }

  double get todaysSpending {
    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);

    return expenses.fold(
      0,
      (sum, expense) => sum + (expense.dailyAmounts[todayDate] ?? 0),
    );
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

    if (!mounted) return;

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
              final today = DateTime.now();

              final todayDate = DateTime(today.year, today.month, today.day);

              final amount = expense.dailyAmounts[todayDate] ?? 0;

              return ExpenseItem(
                category: expense.category,
                description: expense.description,
                amount: amount,
                icon: expense.icon,
                date: _formatDate(todayDate),
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

class AddExpenseDialog extends StatefulWidget {
  final Trip trip;

  const AddExpenseDialog({super.key, required this.trip});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  String _selectedCategory = 'Food';

  DateTime _selectedDate = DateTime.now();

  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  bool _spreadAcrossDays = false;

  String? _amountError;
  String? _descriptionError;
  String? _dateError;

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController();
    _amountController = TextEditingController();

    final today = DateTime.now();

    final tripStart = DateTime(
      widget.trip.startDate.year,
      widget.trip.startDate.month,
      widget.trip.startDate.day,
    );

    final tripEnd = DateTime(
      widget.trip.endDate.year,
      widget.trip.endDate.month,
      widget.trip.endDate.day,
    );

    final todayDate = DateTime(today.year, today.month, today.day);

    if (todayDate.isBefore(tripStart)) {
      _selectedDate = tripStart;
    } else if (todayDate.isAfter(tripEnd)) {
      _selectedDate = tripEnd;
    } else {
      _selectedDate = todayDate;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _dateText() {
    if (!_spreadAcrossDays) {
      return _formatDate(_selectedDate);
    }

    if (_rangeStart == null || _rangeEnd == null) {
      return 'Select date range';
    }

    return '${_formatDate(_rangeStart!)} → ${_formatDate(_rangeEnd!)}';
  }

  Future<void> _selectDate() async {
    if (_spreadAcrossDays) {
      final initialRange = _rangeStart != null && _rangeEnd != null
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null;

      final pickedRange = await showDateRangePicker(
        context: context,
        firstDate: widget.trip.startDate,
        lastDate: widget.trip.endDate,
        initialDateRange: initialRange,
      );

      if (pickedRange == null || !mounted) {
        return;
      }

      setState(() {
        _rangeStart = DateTime(
          pickedRange.start.year,
          pickedRange.start.month,
          pickedRange.start.day,
        );

        _rangeEnd = DateTime(
          pickedRange.end.year,
          pickedRange.end.month,
          pickedRange.end.day,
        );

        _dateError = null;
      });

      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );

      _dateError = null;
    });
  }

  Map<DateTime, double> _buildDailyAmounts(double totalAmount) {
    if (!_spreadAcrossDays) {
      return {_selectedDate: totalAmount};
    }

    final start = _rangeStart!;
    final end = _rangeEnd!;

    final numberOfDays = end.difference(start).inDays + 1;

    final dailyAmount = totalAmount / numberOfDays;

    final dailyAmounts = <DateTime, double>{};

    for (var i = 0; i < numberOfDays; i++) {
      final date = start.add(Duration(days: i));

      dailyAmounts[DateTime(date.year, date.month, date.day)] = dailyAmount;
    }

    return dailyAmounts;
  }

  void _save() {
    final description = _descriptionController.text.trim();

    final amountText = _amountController.text.trim();

    String? descriptionError;
    String? amountError;
    String? dateError;

    if (description.isEmpty) {
      descriptionError = 'Please enter a description.';
    }

    final amount = double.tryParse(amountText);

    if (amountText.isEmpty) {
      amountError = 'Please enter an amount.';
    } else if (amount == null) {
      amountError = 'Please enter a valid number.';
    } else if (amount <= 0) {
      amountError = 'Amount must be greater than 0.';
    }

    if (_spreadAcrossDays && (_rangeStart == null || _rangeEnd == null)) {
      dateError = 'Please select a date range.';
    }

    if (descriptionError != null || amountError != null || dateError != null) {
      setState(() {
        _descriptionError = descriptionError;

        _amountError = amountError;

        _dateError = dateError;
      });

      return;
    }

    final dailyAmounts = _buildDailyAmounts(amount!);

    final expense = Expense(
      tripId: widget.trip.id,
      category: _selectedCategory,
      description: description,
      dailyAmounts: dailyAmounts,
      icon: ExpenseStorageService.getIcon(_selectedCategory),
    );

    Navigator.of(context).pop(expense);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Expense'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,

              decoration: const InputDecoration(labelText: 'Category'),

              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(
                  value: 'Transportation',
                  child: Text('Transportation'),
                ),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],

              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,

              decoration: InputDecoration(
                labelText: 'Description',
                errorText: _descriptionError,
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _amountController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '¥ ',
                errorText: _amountError,
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,

              leading: const Icon(Icons.calendar_today),

              title: const Text('Date'),

              subtitle: Text(_dateText()),

              onTap: _selectDate,
            ),

            if (_dateError != null)
              Align(
                alignment: Alignment.centerLeft,

                child: Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),

                  child: Text(
                    _dateError!,

                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            CheckboxListTile(
              contentPadding: EdgeInsets.zero,

              title: const Text('Spread across days'),

              subtitle: const Text(
                'Divide the expense equally across the selected dates',
              ),

              value: _spreadAcrossDays,

              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _spreadAcrossDays = value;

                  _dateError = null;

                  if (value) {
                    _rangeStart = _selectedDate;

                    _rangeEnd = _selectedDate;
                  } else {
                    _rangeStart = null;
                    _rangeEnd = null;
                  }
                });
              },
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}
