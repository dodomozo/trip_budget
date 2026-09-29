import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip.dart';

class TripStorageService {
  static const _tripIdsKey = 'trip_ids';

  String _key(String tripId, String field) {
    return 'trip_${tripId}_$field';
  }

  Future<void> saveTrip(Trip trip) async {
    final prefs = await SharedPreferences.getInstance();

    final tripIds = prefs.getStringList(_tripIdsKey) ?? [];

    if (!tripIds.contains(trip.id)) {
      tripIds.add(trip.id);
    }

    await prefs.setStringList(_tripIdsKey, tripIds);

    await prefs.setString(_key(trip.id, 'name'), trip.name);

    await prefs.setDouble(_key(trip.id, 'allowance'), trip.allowance);

    await prefs.setString(
      _key(trip.id, 'start_date'),
      trip.startDate.toIso8601String(),
    );

    await prefs.setString(
      _key(trip.id, 'end_date'),
      trip.endDate.toIso8601String(),
    );
  }

  Future<List<Trip>> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();

    final tripIds = prefs.getStringList(_tripIdsKey) ?? [];

    final trips = <Trip>[];

    for (final tripId in tripIds) {
      final name = prefs.getString(_key(tripId, 'name'));

      final allowance = prefs.getDouble(_key(tripId, 'allowance'));

      final startDateString = prefs.getString(_key(tripId, 'start_date'));

      final endDateString = prefs.getString(_key(tripId, 'end_date'));

      if (name == null ||
          allowance == null ||
          startDateString == null ||
          endDateString == null) {
        continue;
      }

      trips.add(
        Trip(
          id: tripId,
          name: name,
          allowance: allowance,
          startDate: DateTime.parse(startDateString),
          endDate: DateTime.parse(endDateString),
        ),
      );
    }

    return trips;
  }

  Future<Trip?> loadTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(_key(tripId, 'name'));

    final allowance = prefs.getDouble(_key(tripId, 'allowance'));

    final startDateString = prefs.getString(_key(tripId, 'start_date'));

    final endDateString = prefs.getString(_key(tripId, 'end_date'));

    if (name == null ||
        allowance == null ||
        startDateString == null ||
        endDateString == null) {
      return null;
    }

    return Trip(
      id: tripId,
      name: name,
      allowance: allowance,
      startDate: DateTime.parse(startDateString),
      endDate: DateTime.parse(endDateString),
    );
  }

  Future<void> migrateDefaultTrip() async {
    final prefs = await SharedPreferences.getInstance();

    final tripIds = prefs.getStringList(_tripIdsKey) ?? [];

    if (tripIds.contains('default-trip')) {
      return;
    }

    final name = prefs.getString('trip_name');
    final allowance = prefs.getDouble('trip_allowance');
    final startDateString = prefs.getString('trip_start_date');
    final endDateString = prefs.getString('trip_end_date');

    if (name == null ||
        allowance == null ||
        startDateString == null ||
        endDateString == null) {
      return;
    }

    final trip = Trip(
      id: 'default-trip',
      name: name,
      allowance: allowance,
      startDate: DateTime.parse(startDateString),
      endDate: DateTime.parse(endDateString),
    );

    await saveTrip(trip);
  }
}
