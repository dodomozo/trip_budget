import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/currency_service.dart';
import '../services/expense_storage_service.dart';
import '../widgets/expense_item.dart';
import '../constants/expense_categories.dart';

class _ExpenseDayEntry {
  final Expense expense;
  final DateTime date;
  final double amount;
  final int expenseIndex;

  const _ExpenseDayEntry({
    required this.expense,
    required this.date,
    required this.amount,
    required this.expenseIndex,
  });
}

class ExpenseHistoryPage extends StatefulWidget {
  final String tripId;
  final String tripCurrencyCode;
  final String displayCurrencyCode;
  final double exchangeRate;
  final List<Expense> expenses;

  const ExpenseHistoryPage({
    super.key,
    required this.tripId,
    required this.tripCurrencyCode,
    required this.displayCurrencyCode,
    required this.exchangeRate,
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateHeader(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  double _convertAmount(double amount) {
    return amount * widget.exchangeRate;
  }

  String _formatAmount(double amount) {
    return CurrencyService.format(
      _convertAmount(amount),
      widget.displayCurrencyCode,
    );
  }

  List<_ExpenseDayEntry> _buildDailyEntries() {
    final entries = <_ExpenseDayEntry>[];

    for (var expenseIndex = 0; expenseIndex < expenses.length; expenseIndex++) {
      final expense = expenses[expenseIndex];

      for (final entry in expense.dailyAmounts.entries) {
        final amount = entry.value;

        if (amount <= 0) {
          continue;
        }

        entries.add(
          _ExpenseDayEntry(
            expense: expense,
            date: _dateOnly(entry.key),
            amount: amount,
            expenseIndex: expenseIndex,
          ),
        );
      }
    }

    // Newest date first.
    //
    // For expenses on the same date, higher expenseIndex means
    // the expense was added later, so it appears first.
    entries.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return b.expenseIndex.compareTo(a.expenseIndex);
    });

    return entries;
  }

  Map<DateTime, List<_ExpenseDayEntry>> _groupEntriesByDate(
    List<_ExpenseDayEntry> entries,
  ) {
    final grouped = <DateTime, List<_ExpenseDayEntry>>{};

    for (final entry in entries) {
      grouped.putIfAbsent(entry.date, () => []).add(entry);
    }

    return grouped;
  }

  Future<void> _saveExpenses() async {
    final storage = ExpenseStorageService();

    await storage.saveExpenses(widget.tripId, expenses);
  }

  Future<bool> _confirmDelete(_ExpenseDayEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense Portion?'),
          content: Text(
            'Delete ${_formatAmount(entry.amount)} '
            '${entry.expense.description} '
            'for ${_formatDate(entry.date)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  Future<void> _deleteExpensePortion(_ExpenseDayEntry entry) async {
    final expenseIndex = expenses.indexOf(entry.expense);

    if (expenseIndex == -1) {
      return;
    }

    final updatedDailyAmounts = Map<DateTime, double>.from(
      entry.expense.dailyAmounts,
    );

    updatedDailyAmounts.remove(entry.date);

    setState(() {
      if (updatedDailyAmounts.isEmpty) {
        expenses.removeAt(expenseIndex);
      } else {
        expenses[expenseIndex] = Expense(
          tripId: entry.expense.tripId,
          category: entry.expense.category,
          description: entry.expense.description,
          dailyAmounts: updatedDailyAmounts,
          icon: entry.expense.icon,
        );
      }
    });

    await _saveExpenses();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${entry.expense.description} on '
          '${_formatDate(entry.date)} deleted',
        ),
      ),
    );
  }

  Future<void> _editExpensePortion(_ExpenseDayEntry entry) async {
    final updatedPortion = await showDialog<_EditedExpensePortion>(
      context: context,
      builder: (dialogContext) {
        return EditExpensePortionDialog(
          description: entry.expense.description,
          category: entry.expense.category,
          amount: entry.amount,
          date: entry.date,
          tripId: entry.expense.tripId,
          currencyCode: widget.tripCurrencyCode,
        );
      },
    );

    if (updatedPortion == null) {
      return;
    }

    final expenseIndex = expenses.indexOf(entry.expense);

    if (expenseIndex == -1) {
      return;
    }

    final originalExpense = expenses[expenseIndex];

    final updatedDailyAmounts = Map<DateTime, double>.from(
      originalExpense.dailyAmounts,
    );

    updatedDailyAmounts.remove(entry.date);

    updatedDailyAmounts[updatedPortion.date] = updatedPortion.amount;

    final updatedExpense = Expense(
      tripId: originalExpense.tripId,
      category: updatedPortion.category,
      description: updatedPortion.description,
      dailyAmounts: updatedDailyAmounts,
      icon: ExpenseCategories.getIcon(updatedPortion.category),
    );

    setState(() {
      expenses[expenseIndex] = updatedExpense;
    });

    await _saveExpenses();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updatedPortion.description} updated')),
    );
  }

  Widget _buildDateHeader(DateTime date, List<_ExpenseDayEntry> entries) {
    final dailyTotal = entries.fold<double>(
      0,
      (total, entry) => total + entry.amount,
    );

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              _formatDateHeader(date),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            CurrencyService.format(
              _convertAmount(dailyTotal),
              widget.displayCurrencyCode,
            ),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseEntry(_ExpenseDayEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(
          '${entry.expense.hashCode}_'
          '${entry.date.toIso8601String()}',
        ),
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
          return await _confirmDelete(entry);
        },
        onDismissed: (_) {
          _deleteExpensePortion(entry);
        },
        child: GestureDetector(
          onTap: () {
            _editExpensePortion(entry);
          },
          child: ExpenseItem(
            category: entry.expense.category,
            description: entry.expense.description,
            amount: _convertAmount(entry.amount),
            icon: entry.expense.icon,
            date: _formatDate(entry.date),
            currencyCode: widget.displayCurrencyCode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyEntries = _buildDailyEntries();
    final groupedEntries = _groupEntriesByDate(dailyEntries);

    final dates = groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

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
      body: dailyEntries.isEmpty
          ? const Center(
              child: Text(
                'No expenses yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final entries = groupedEntries[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateHeader(date, entries),

                    ...entries.map(_buildExpenseEntry),

                    if (index < dates.length - 1) const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }
}

class _EditedExpensePortion {
  final String tripId;
  final String description;
  final String category;
  final double amount;
  final DateTime date;

  const _EditedExpensePortion({
    required this.tripId,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
  });
}

class EditExpensePortionDialog extends StatefulWidget {
  final String tripId;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final String currencyCode;

  const EditExpensePortionDialog({
    super.key,
    required this.tripId,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.currencyCode,
  });

  @override
  State<EditExpensePortionDialog> createState() =>
      _EditExpensePortionDialogState();
}

class _EditExpensePortionDialogState extends State<EditExpensePortionDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  late String _selectedCategory;
  late DateTime _selectedDate;

  String? _descriptionError;
  String? _amountError;

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(text: widget.description);

    _amountController = TextEditingController(
      text: widget.amount.toStringAsFixed(0),
    );

    _selectedCategory = widget.category;

    _selectedDate = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    });
  }

  void _save() {
    final description = _descriptionController.text.trim();
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    String? descriptionError;
    String? amountError;

    if (description.isEmpty) {
      descriptionError = 'Please enter a description.';
    }

    if (amountText.isEmpty) {
      amountError = 'Please enter an amount.';
    } else if (amount == null) {
      amountError = 'Please enter a valid number.';
    } else if (amount <= 0) {
      amountError = 'Amount must be greater than 0.';
    }

    if (descriptionError != null || amountError != null) {
      setState(() {
        _descriptionError = descriptionError;
        _amountError = amountError;
      });

      return;
    }

    final result = _EditedExpensePortion(
      tripId: widget.tripId,
      description: description,
      category: _selectedCategory,
      amount: amount!,
      date: _selectedDate,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyService.getSymbol(widget.currencyCode);

    return AlertDialog(
      title: const Text('Edit Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                errorText: _descriptionError,
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ExpenseCategories.all.map((category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Row(
                    children: [
                      Icon(category.icon, size: 22),
                      const SizedBox(width: 12),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return ExpenseCategories.all.map((category) {
                  return Row(
                    children: [
                      Icon(category.icon, size: 22),
                      const SizedBox(width: 12),
                      Text(category.name),
                    ],
                  );
                }).toList();
              },
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$currencySymbol ',
                errorText: _amountError,
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(_formatDate(_selectedDate)),
              onTap: _selectDate,
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
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
