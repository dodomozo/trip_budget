import '../models/expense.dart';
import '../models/trash_entry.dart';
import '../models/trip.dart';
import 'expense_storage_service.dart';
import 'trash_storage_service.dart';
import 'trip_storage_service.dart';

class TrashService {
  final TrashStorageService _trashStorage = TrashStorageService();
  final TripStorageService _tripStorage = TripStorageService();
  final ExpenseStorageService _expenseStorage = ExpenseStorageService();

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String value) {
    final date = DateTime.parse(value);
    return DateTime(date.year, date.month, date.day);
  }

  Map<String, dynamic> _tripToJson(Trip trip) {
    return {
      'id': trip.id,
      'name': trip.name,
      'allowance': trip.allowance,
      'startDate': trip.startDate.toIso8601String(),
      'endDate': trip.endDate.toIso8601String(),
      'currencyCode': trip.currencyCode,
    };
  }

  Trip _tripFromJson(Map<String, dynamic> data) {
    return Trip(
      id: data['id'] as String,
      name: data['name'] as String,
      allowance: (data['allowance'] as num).toDouble(),
      startDate: DateTime.parse(data['startDate'] as String),
      endDate: DateTime.parse(data['endDate'] as String),
      currencyCode: data['currencyCode'] as String? ?? 'JPY',
    );
  }

  Map<String, dynamic> _expenseToJson(Expense expense) {
    return {
      'tripId': expense.tripId,
      'category': expense.category,
      'description': expense.description,
      'dailyAmounts': expense.dailyAmounts.map(
        (date, amount) => MapEntry(_dateKey(date), amount),
      ),
    };
  }

  Expense _expenseFromJson(Map<String, dynamic> data) {
    final rawAmounts = Map<String, dynamic>.from(data['dailyAmounts'] as Map);

    final dailyAmounts = <DateTime, double>{};

    for (final entry in rawAmounts.entries) {
      dailyAmounts[_parseDate(entry.key)] = (entry.value as num).toDouble();
    }

    return Expense(
      tripId: data['tripId'] as String,
      category: data['category'] as String,
      description: data['description'] as String,
      dailyAmounts: dailyAmounts,
      icon: ExpenseStorageService.getIcon(data['category'] as String),
    );
  }

  /// Moves a trip and all its expenses to Trash.
  ///
  /// The Trash entry is saved before active data is removed.
  Future<void> moveTripToTrash(Trip trip) async {
    final expenses = await _expenseStorage.loadExpenses(trip.id);

    final entry = TrashEntry(
      id: _newId(),
      type: 'trip',
      tripId: trip.id,
      deletedAt: DateTime.now(),
      data: {
        'trip': _tripToJson(trip),
        'expenses': expenses.map(_expenseToJson).toList(),
      },
    );

    await _trashStorage.addToTrash(entry);

    await _expenseStorage.deleteExpenses(trip.id);
    await _tripStorage.deleteTrip(trip.id);
  }

  /// Archives only one date's portion of an expense.
  ///
  /// Call this before saving the updated active expense list.
  Future<void> moveExpensePortionToTrash({
    required Expense expense,
    required DateTime date,
    required double amount,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final entry = TrashEntry(
      id: _newId(),
      type: 'expense',
      tripId: expense.tripId,
      deletedAt: DateTime.now(),
      data: {
        'category': expense.category,
        'description': expense.description,
        'date': _dateKey(normalizedDate),
        'amount': amount,
      },
    );

    await _trashStorage.addToTrash(entry);
  }

  /// Restores an item and removes it from Trash only after saving succeeds.
  Future<void> restore(TrashEntry entry) async {
    if (entry.type == 'trip') {
      final tripData = Map<String, dynamic>.from(entry.data['trip'] as Map);

      final trip = _tripFromJson(tripData);

      final existingTrip = await _tripStorage.loadTrip(trip.id);

      if (existingTrip != null) {
        throw StateError(
          'A trip with this ID already exists. Nothing was restored.',
        );
      }

      final rawExpenses = entry.data['expenses'] as List<dynamic>;

      final expenses = rawExpenses.map((item) {
        return _expenseFromJson(Map<String, dynamic>.from(item as Map));
      }).toList();

      await _tripStorage.saveTrip(trip);
      await _expenseStorage.saveExpenses(trip.id, expenses);
    } else if (entry.type == 'expense') {
      final trip = await _tripStorage.loadTrip(entry.tripId);

      if (trip == null) {
        throw StateError(
          'Restore the associated trip first before restoring this expense.',
        );
      }

      final category = entry.data['category'] as String;
      final description = entry.data['description'] as String;
      final date = _parseDate(entry.data['date'] as String);
      final amount = (entry.data['amount'] as num).toDouble();

      final expenses = await _expenseStorage.loadExpenses(entry.tripId);

      expenses.add(
        Expense(
          tripId: entry.tripId,
          category: category,
          description: description,
          dailyAmounts: {date: amount},
          icon: ExpenseStorageService.getIcon(category),
        ),
      );

      await _expenseStorage.saveExpenses(entry.tripId, expenses);
    } else {
      throw FormatException('Unknown Trash entry type: ${entry.type}');
    }

    await _trashStorage.removeFromTrash(entry.id);
  }

  /// Permanently deletes only the selected Trash entry.
  Future<void> permanentlyDelete(TrashEntry entry) async {
    await _trashStorage.removeFromTrash(entry.id);
  }

  Future<List<TrashEntry>> loadTrash() {
    return _trashStorage.loadTrash();
  }
}
