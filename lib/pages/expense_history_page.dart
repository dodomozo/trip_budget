import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_storage_service.dart';
import '../widgets/expense_item.dart';

class _ExpenseDayEntry {
  final Expense expense;
  final DateTime date;
  final double amount;

  const _ExpenseDayEntry({
    required this.expense,
    required this.date,
    required this.amount,
  });
}

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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<_ExpenseDayEntry> _buildDailyEntries() {
    final entries = <_ExpenseDayEntry>[];

    for (final expense in expenses) {
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
          ),
        );
      }
    }

    entries.sort((a, b) {
      final dateComparison = b.date.compareTo(a.date);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return a.expense.description.compareTo(b.expense.description);
    });

    return entries;
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
            'Delete ${entry.descriptionForDialog} '
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
          '${entry.expense.description} on ${_formatDate(entry.date)} deleted',
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

    // Remove the original day's portion.
    updatedDailyAmounts.remove(entry.date);

    // Add the edited portion to its new date.
    updatedDailyAmounts[updatedPortion.date] = updatedPortion.amount;

    final updatedExpense = Expense(
      tripId: originalExpense.tripId,
      category: updatedPortion.category,
      description: updatedPortion.description,
      dailyAmounts: updatedDailyAmounts,
      icon: ExpenseStorageService.getIcon(updatedPortion.category),
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

  @override
  Widget build(BuildContext context) {
    final dailyEntries = _buildDailyEntries();

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
              padding: const EdgeInsets.all(16),
              itemCount: dailyEntries.length,
              itemBuilder: (context, index) {
                final entry = dailyEntries[index];

                return Dismissible(
                  key: ValueKey(
                    '${entry.expense.tripId}_'
                    '${entry.expense.description}_'
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
                      amount: entry.amount,
                      icon: entry.expense.icon,
                      date: _formatDate(entry.date),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

extension on _ExpenseDayEntry {
  String get descriptionForDialog {
    return '¥${amount.toStringAsFixed(0)} ${expense.description}';
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

  const EditExpensePortionDialog({
    super.key,
    required this.tripId,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
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
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
            const SizedBox(height: 16),
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
