import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip.dart';

class TripStorageService {
  static const _nameKey = 'trip_name';
  static const _allowanceKey = 'trip_allowance';
  static const _startDateKey = 'trip_start_date';
  static const _endDateKey = 'trip_end_date';

  Future<void> saveTrip(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_nameKey, trip.name);
    await prefs.setDouble(_allowanceKey, trip.allowance);
    await prefs.setString(_startDateKey, trip.startDate.toIso8601String());
    await prefs.setString(_endDateKey, trip.endDate.toIso8601String());
  }

  Future<Trip?> loadTrip() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(_nameKey);
    final allowance = prefs.getDouble(_allowanceKey);
    final startDateString = prefs.getString(_startDateKey);
    final endDateString = prefs.getString(_endDateKey);

    if (name == null ||
        allowance == null ||
        startDateString == null ||
        endDateString == null) {
      return null;
    }

    return Trip(
      name: name,
      allowance: allowance,
      startDate: DateTime.parse(startDateString),
      endDate: DateTime.parse(endDateString),
    );
  }
}
