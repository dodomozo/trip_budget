import '../../models/expense.dart';
import '../../models/trip.dart';
import '../../services/currency_service.dart';

class StatisticsData {
  final Trip trip;
  final List<Expense> expenses;
  final String displayCurrencyCode;
  final double exchangeRate;

  StatisticsData({
    required this.trip,
    required this.expenses,
    required this.displayCurrencyCode,
    required this.exchangeRate,
  });

  // ------------------------------------------------------------
  // Date helpers
  // ------------------------------------------------------------

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime get startDate => _dateOnly(trip.startDate);

  DateTime get endDate => _dateOnly(trip.endDate);

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ------------------------------------------------------------
  // Trip duration
  // ------------------------------------------------------------

  int get totalDays => trip.totalDays;

  /// Includes today when the trip is currently ongoing.
  int get elapsedDays {
    if (today.isBefore(startDate)) {
      return 0;
    }

    if (today.isAfter(endDate)) {
      return totalDays;
    }

    return today.difference(startDate).inDays + 1;
  }

  /// Only future trip days.
  /// Today is intentionally NOT included.
  int get remainingDays {
    if (today.isBefore(startDate)) {
      return totalDays;
    }

    if (today.isAfter(endDate)) {
      return 0;
    }

    return endDate.difference(today).inDays;
  }

  // ------------------------------------------------------------
  // Currency
  // ------------------------------------------------------------

  double convertAmount(double amount) {
    return amount * exchangeRate;
  }

  String formatAmount(double amount) {
    return CurrencyService.format(convertAmount(amount), displayCurrencyCode);
  }

  // ------------------------------------------------------------
  // Spending
  // ------------------------------------------------------------

  double get totalSpent {
    return expenses.fold(0, (sum, expense) => sum + expense.totalAmount);
  }

  double get remainingBudget {
    return trip.allowance - totalSpent;
  }

  double get budgetUsedPercentage {
    if (trip.allowance <= 0) {
      return 0;
    }

    return totalSpent / trip.allowance;
  }

  // ------------------------------------------------------------
  // Daily budget
  // ------------------------------------------------------------

  /// Fixed daily baseline for the entire trip.
  ///
  /// This is intentionally NOT the adaptive remaining budget.
  double get baselineDailyLimit {
    if (totalDays <= 0) {
      return 0;
    }

    return trip.allowance / totalDays;
  }

  double get averageDailySpending {
    if (elapsedDays <= 0) {
      return 0;
    }

    return totalSpent / elapsedDays;
  }

  double get averageDailyBudgetUsage {
    if (baselineDailyLimit <= 0) {
      return 0;
    }

    return averageDailySpending / baselineDailyLimit;
  }

  // ------------------------------------------------------------
  // Projection
  // ------------------------------------------------------------

  double get projectedTotalSpending {
    if (totalDays <= 0) {
      return 0;
    }

    // Before the trip starts, there is no spending pace yet.
    if (elapsedDays <= 0) {
      return 0;
    }

    // Completed trip.
    if (remainingDays == 0) {
      return totalSpent;
    }

    return averageDailySpending * totalDays;
  }

  double get projectedRemainingBudget {
    return trip.allowance - projectedTotalSpending;
  }

  double get projectedBudgetUsage {
    if (trip.allowance <= 0) {
      return 0;
    }

    return projectedTotalSpending / trip.allowance;
  }

  bool get isProjectedOverBudget {
    return projectedTotalSpending > trip.allowance;
  }

  String get spendingPaceStatus {
    if (averageDailySpending == 0) {
      return 'No spending recorded yet';
    }

    if (averageDailySpending <= baselineDailyLimit) {
      return 'Within daily baseline';
    }

    return 'Above daily baseline';
  }

  // ------------------------------------------------------------
  // Category totals
  // ------------------------------------------------------------

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};

    for (final expense in expenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.totalAmount;
    }

    return totals;
  }

  // ------------------------------------------------------------
  // Daily spending
  // ------------------------------------------------------------

  /// Returns every day of the trip, including zero-spending days.
  Map<DateTime, double> get dailyTotals {
    final totals = <DateTime, double>{};

    for (int i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      totals[date] = 0;
    }

    for (final expense in expenses) {
      for (final entry in expense.dailyAmounts.entries) {
        final date = _dateOnly(entry.key);

        if (date.isBefore(startDate) || date.isAfter(endDate)) {
          continue;
        }

        totals[date] = (totals[date] ?? 0) + entry.value;
      }
    }

    return totals;
  }

  double spendingForDate(DateTime date) {
    final normalizedDate = _dateOnly(date);

    return dailyTotals[normalizedDate] ?? 0;
  }

  // ------------------------------------------------------------
  // Today's spending
  // ------------------------------------------------------------

  double get todaysSpending {
    return spendingForDate(today);
  }

  // ------------------------------------------------------------
  // Convenience values
  // ------------------------------------------------------------

  bool get tripHasStarted {
    return !today.isBefore(startDate);
  }

  bool get tripHasEnded {
    return today.isAfter(endDate);
  }

  bool get tripIsOngoing {
    return tripHasStarted && !tripHasEnded;
  }
}
