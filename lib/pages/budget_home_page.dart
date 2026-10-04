import 'package:flutter/material.dart';

import 'expense_history_page.dart';
import 'statistics_page.dart';
import 'trip_list_page.dart';
import '../models/expense.dart';
import '../models/trip.dart';
import '../widgets/expense_item.dart';
import '../widgets/summary_card.dart';
import '../services/expense_storage_service.dart';
import '../services/currency_service.dart';
import '../services/theme_mode_service.dart';
import '../constants/expense_categories.dart';

class BudgetHomePage extends StatefulWidget {
  final Trip trip;

  const BudgetHomePage({super.key, required this.trip});

  @override
  State<BudgetHomePage> createState() => _BudgetHomePageState();
}

class _BudgetHomePageState extends State<BudgetHomePage> {
  late Trip trip;

  List<Expense> expenses = [];

  late String _displayCurrency;

  double _exchangeRate = 1.0;

  bool _isConverting = false;

  @override
  void initState() {
    super.initState();

    trip = widget.trip;
    _displayCurrency = trip.currencyCode;

    _loadExpenses();
  }

  Future<void> _showAppearancePicker() async {
    final selectedMode = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final currentMode = ThemeModeService.mode.value;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose how Budget Monitoring looks.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

                ...ThemeMode.values.map((themeMode) {
                  final isSelected = themeMode == currentMode;

                  return ListTile(
                    leading: Icon(ThemeModeService.getModeIcon(themeMode)),
                    title: Text(ThemeModeService.getModeName(themeMode)),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    selected: isSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.pop(context, themeMode);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );

    if (selectedMode == null || !mounted) {
      return;
    }

    await ThemeModeService.setMode(selectedMode);
  }

  Future<void> _loadExpenses() async {
    final storage = ExpenseStorageService();

    final loadedExpenses = await storage.loadExpenses(trip.id);

    if (!mounted) {
      return;
    }

    setState(() {
      expenses = loadedExpenses;
    });
  }

  Future<void> _saveExpenses() async {
    final storage = ExpenseStorageService();

    await storage.saveExpenses(trip.id, expenses);
  }

  double _convertAmount(double amount) {
    return amount * _exchangeRate;
  }

  String _formatAmount(double amount) {
    return CurrencyService.format(_convertAmount(amount), _displayCurrency);
  }

  Future<void> _changeDisplayCurrency(String currencyCode) async {
    if (currencyCode == _displayCurrency) {
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      final rate = await CurrencyService.getExchangeRate(
        trip.currencyCode,
        currencyCode,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _displayCurrency = currencyCode;
        _exchangeRate = rate;
        _isConverting = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConverting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get the latest exchange rate.'),
        ),
      );
    }
  }

  double get totalSpent {
    return expenses.fold(0, (sum, expense) => sum + expense.totalAmount);
  }

  double get remainingBudget {
    return trip.allowance - totalSpent;
  }

  DateTime get _todayDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _tripStartDate {
    return DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
  }

  DateTime get _tripEndDate {
    return DateTime(trip.endDate.year, trip.endDate.month, trip.endDate.day);
  }

  int get elapsedDays {
    if (_todayDate.isBefore(_tripStartDate)) {
      return 0;
    }

    if (_todayDate.isAfter(_tripEndDate)) {
      return trip.totalDays;
    }

    return _todayDate.difference(_tripStartDate).inDays + 1;
  }

  int get remainingDays {
    if (_todayDate.isBefore(_tripStartDate)) {
      return trip.totalDays;
    }

    if (_todayDate.isAfter(_tripEndDate)) {
      return 0;
    }

    // Today is included because it is still available for spending.
    return _tripEndDate.difference(_todayDate).inDays + 1;
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
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  List<Expense> get todaysExpenses {
    final today = DateTime.now();

    return expenses
        .where((expense) {
          return expense.dailyAmounts.keys.any((date) {
            return date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
          });
        })
        .toList()
        .reversed
        .toList();
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
    if (totalSpent == 0 || elapsedDays <= 0) {
      return 0;
    }

    return totalSpent / elapsedDays;
  }

  double get projectedTotalSpending {
    if (elapsedDays <= 0) {
      return 0;
    }

    // Once the trip has ended, use the actual total instead of
    // extrapolating from an extra day.
    if (elapsedDays >= trip.totalDays) {
      return totalSpent;
    }

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
        builder: (context) {
          return ExpenseHistoryPage(
            tripId: trip.id,
            tripCurrencyCode: trip.currencyCode,
            displayCurrencyCode: _displayCurrency,
            exchangeRate: _exchangeRate,
            expenses: expenses,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    if (updatedExpenses != null) {
      setState(() {
        expenses = updatedExpenses;
      });
    }
  }

  Future<void> _openStatistics() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatisticsPage(
            trip: trip,
            expenses: expenses,
            displayCurrencyCode: _displayCurrency,
            exchangeRate: _exchangeRate,
          );
        },
      ),
    );
  }

  Future<void> _openPlanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return StatisticsPage(
            trip: trip,
            expenses: expenses,
            displayCurrencyCode: _displayCurrency,
            exchangeRate: _exchangeRate,
            initialTabIndex: 5,
          );
        },
      ),
    );
  }

  Future<void> _showCurrencyPicker() async {
    if (_isConverting) {
      return;
    }

    final selectedCurrency = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  'Display Currency',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Choose how amounts are displayed. '
                  'Your trip and expense data will not be changed.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ...CurrencyService.supportedCurrencies.map((currency) {
                final isSelected = currency == _displayCurrency;

                return ListTile(
                  leading: CircleAvatar(child: Text(currency.substring(0, 1))),
                  title: Text(currency),
                  subtitle: Text(CurrencyService.getSymbol(currency)),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context, currency);
                  },
                );
              }),
            ],
          ),
        );
      },
    );

    if (selectedCurrency == null || !mounted) {
      return;
    }

    await _changeDisplayCurrency(selectedCurrency);
  }

  Widget _buildCurrencySelector() {
    final symbol = CurrencyService.getSymbol(_displayCurrency);

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: _showCurrencyPicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isConverting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.currency_exchange,
                    size: 17,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                const SizedBox(width: 7),
                Text(
                  '$_displayCurrency ($symbol)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.keyboard_arrow_down, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.name,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${_formatDate(trip.startDate)} → '
                      '${_formatDate(trip.endDate)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.timelapse, size: 15, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    '$remainingDays days remaining',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildCurrencySelector(),
      ],
    );
  }

  Widget _buildRemainingBudgetCard() {
    final isOverBudget = remainingBudget < 0;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_outlined,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOverBudget ? 'Over Budget' : 'Remaining Budget',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatAmount(
                isOverBudget ? remainingBudget.abs() : remainingBudget,
              ),
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isOverBudget
                  ? 'You have exceeded your trip allowance.'
                  : 'Available for the remaining $remainingDays '
                        '${remainingDays == 1 ? 'day' : 'days'}.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBudgetCard() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.today_outlined,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended Daily Budget',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatAmount(recommendedDailyBudget),
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard() {
    final projectedRemaining = projectedRemainingBudget;
    final isOverBudget = projectedRemaining < 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Spending Forecast',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildForecastMetric(
                    label: 'Projected spending',
                    value: _formatAmount(projectedTotalSpending),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildForecastMetric(
                    label: isOverBudget
                        ? 'Projected over'
                        : 'Projected remaining',
                    value: _formatAmount(projectedRemaining.abs()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastMetric({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTodaySection() {
    final isWithinBudget = dailyBudgetDifference >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Expanded(
              child: Text(
                "Today's Spending",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: _openExpenseHistory,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatAmount(todaysSpending)} spent today',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: isWithinBudget
                  ? Theme.of(context).colorScheme.primaryContainer
                        .withValues(alpha: 0.45)
                  : Theme.of(context).colorScheme.errorContainer
                        .withValues(alpha: 0.55),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isWithinBudget
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWithinBudget
                        ? Icons.check_rounded
                        : Icons.warning_amber_rounded,
                    size: 27,
                    color: isWithinBudget
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dailyBudgetStatus,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        dailyBudgetDifference >= 0
                            ? '${_formatAmount(dailyBudgetDifference)} '
                                  'remaining for today'
                            : '${_formatAmount(dailyBudgetDifference.abs())} '
                                  'over today\'s budget',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (todaysExpenses.isEmpty)
          _buildEmptyTodayState()
        else
          ...todaysExpenses.map((expense) {
            final today = DateTime.now();

            final todayDate = DateTime(today.year, today.month, today.day);

            final amount = expense.dailyAmounts[todayDate] ?? 0;

            return ExpenseItem(
              category: expense.category,
              description: expense.description,
              amount: _convertAmount(amount),
              icon: expense.icon,
              date: _formatDate(todayDate),
              currencyCode: _displayCurrency,
            );
          }),
      ],
    );
  }

  Widget _buildEmptyTodayState() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 34,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                'No expenses today',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your spending will appear here.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: 'Allowance',
            value: _formatAmount(trip.allowance),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SummaryCard(title: 'Spent', value: _formatAmount(totalSpent)),
        ),
      ],
    );
  }

  Widget _buildPlannerShortcutCard() {
    return Card(
      elevation: 0,
      child: InkWell(
        onTap: _openPlanner,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.savings_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan My Budget',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set a savings goal and daily spending limit.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Monitoring'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Statistics',
            onPressed: _openStatistics,
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Appearance',
            onPressed: _showAppearancePicker,
          ),
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
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTripHeader(),

              const SizedBox(height: 18),

              _buildRemainingBudgetCard(),

              const SizedBox(height: 12),

              _buildPlannerShortcutCard(),

              const SizedBox(height: 12),

              _buildDailyBudgetCard(),

              const SizedBox(height: 12),

              _buildSummaryCards(),

              const SizedBox(height: 12),

              _buildForecastCard(),

              const SizedBox(height: 28),

              _buildTodaySection(),
            ],
          ),
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
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _dateText() {
    if (!_spreadAcrossDays) {
      return _formatDate(_selectedDate);
    }

    if (_rangeStart == null || _rangeEnd == null) {
      return 'Select date range';
    }

    return '${_formatDate(_rangeStart!)} → '
        '${_formatDate(_rangeEnd!)}';
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
    final currencySymbol = CurrencyService.getSymbol(widget.trip.currencyCode);

    return AlertDialog(
      title: const Text('Add Expense'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

            const SizedBox(height: 14),

            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'What did you spend on?',
                prefixIcon: const Icon(Icons.receipt_long_outlined),
                errorText: _descriptionError,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                prefixIcon: const Icon(Icons.payments_outlined),
                prefixText: '$currencySymbol ',
                errorText: _amountError,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            Card(
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date'),
                subtitle: Text(_dateText()),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectDate,
              ),
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
                'Divide the expense equally '
                'across the selected dates',
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
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.add),
          label: const Text('Add Expense'),
        ),
      ],
    );
  }
}
