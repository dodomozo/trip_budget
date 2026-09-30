import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/expense_storage_service.dart';
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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _expenseDate(Expense expense) {
    return _dateOnly(expense.dailyAmounts.keys.first);
  }

  double _expenseAmount(Expense expense) {
    return expense.totalAmount;
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

  Future<void> _editExpense(Expense expense) async {
    final updatedExpense = await showDialog<Expense>(
      context: context,
      builder: (dialogContext) {
        return EditExpenseDialog(expense: expense);
      },
    );

    if (updatedExpense == null) return;

    final index = expenses.indexOf(expense);

    if (index == -1) return;

    setState(() {
      expenses[index] = updatedExpense;
    });

    await _saveExpenses();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updatedExpense.description} updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedExpenses = [...expenses]
      ..sort((a, b) => _expenseDate(b).compareTo(_expenseDate(a)));

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
                  child: GestureDetector(
                    onTap: () {
                      _editExpense(expense);
                    },
                    child: ExpenseItem(
                      category: expense.category,
                      description: expense.description,
                      amount: _expenseAmount(expense),
                      icon: expense.icon,
                      date: _formatDate(_expenseDate(expense)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class EditExpenseDialog extends StatefulWidget {
  final Expense expense;

  const EditExpenseDialog({super.key, required this.expense});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  late String _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();

    _descriptionController = TextEditingController(
      text: widget.expense.description,
    );

    _amountController = TextEditingController(
      text: widget.expense.totalAmount.toStringAsFixed(0),
    );

    _selectedCategory = widget.expense.category;

    final date = widget.expense.dailyAmounts.keys.first;

    _selectedDate = DateTime(date.year, date.month, date.day);
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

    if (pickedDate == null || !mounted) return;

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

    final amount = double.tryParse(_amountController.text.trim());

    if (description.isEmpty) {
      return;
    }

    if (amount == null || amount <= 0) {
      return;
    }

    final updatedExpense = Expense(
      tripId: widget.expense.tripId,
      description: description,
      category: _selectedCategory,
      dailyAmounts: {_selectedDate: amount},
      icon: ExpenseStorageService.getIcon(_selectedCategory),
    );

    Navigator.of(context).pop(updatedExpense);
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
              decoration: const InputDecoration(labelText: 'Description'),
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
                if (value == null) return;

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
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '¥ ',
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
