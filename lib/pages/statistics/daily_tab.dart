import 'package:flutter/material.dart';

import '../../models/expense.dart';
import '../../services/expense_storage_service.dart';
import 'statistics_data.dart';

class DailyTab extends StatelessWidget {
  final StatisticsData data;

  const DailyTab({super.key, required this.data});

  static const _months = [
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

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _monthName(DateTime date) => _months[date.month - 1];

  String _shortMonthName(DateTime date) => _monthName(date).substring(0, 3);

  String _weekdayName(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }

  List<Expense> _expensesForDate(DateTime date) {
    final target = _dateOnly(date);

    return data.expenses.where((expense) {
      return expense.dailyAmounts.entries.any((entry) {
        return _dateOnly(entry.key) == target && entry.value > 0;
      });
    }).toList();
  }

  double _amountForDate(Expense expense, DateTime date) {
    final target = _dateOnly(date);

    for (final entry in expense.dailyAmounts.entries) {
      if (_dateOnly(entry.key) == target) {
        return entry.value;
      }
    }
    return 0;
  }

  Future<void> _showDayExpenses(
    BuildContext context,
    DateTime date,
    double total,
  ) async {
    final expenses = _expensesForDate(date);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colors = theme.colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_monthName(date)} ${date.day}, ${date.year}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _weekdayName(date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.formatAmount(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'total spent',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 4),
                  if (expenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 44,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No expenses for this day.',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          final amount = _amountForDate(expense, date);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              foregroundColor: colors.onPrimaryContainer,
                              child: Icon(
                                ExpenseStorageService.getIcon(expense.category),
                              ),
                            ),
                            title: Text(
                              expense.description.isEmpty
                                  ? expense.category
                                  : expense.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(expense.category),
                            trailing: Text(
                              data.formatAmount(amount),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthMarker(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        children: [
          Text(
            _monthName(date),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: colors.outlineVariant)),
        ],
      ),
    );
  }

  Widget _buildDayItem(BuildContext context, DateTime date, double amount) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasSpending = amount > 0;
    final expenseCount = _expensesForDate(date).length;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDayExpenses(context, date, amount),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: hasSpending
                      ? colors.primaryContainer
                      : colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasSpending
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_shortMonthName(date)} ${date.day}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasSpending
                          ? '$expenseCount '
                                '${expenseCount == 1 ? 'expense' : 'expenses'}'
                          : 'No spending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                data.formatAmount(amount),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = data.dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No daily data available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final items = <Widget>[];
    DateTime? lastMonth;

    for (final entry in entries) {
      final date = entry.key;

      if (lastMonth == null ||
          lastMonth.year != date.year ||
          lastMonth.month != date.month) {
        items.add(_buildMonthMarker(context, date));
        lastMonth = date;
      }

      items.add(_buildDayItem(context, date, entry.value));
    }

    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Daily Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a day to view all expenses for that day.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
}
