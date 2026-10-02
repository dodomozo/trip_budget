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

    // Save the currency belonging to this trip.
    await prefs.setString(_key(trip.id, 'currency_code'), trip.currencyCode);
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

      // Older trips may not have a saved currency.
      // Keep JPY as the backward-compatible default.
      final currencyCode =
          prefs.getString(_key(tripId, 'currency_code')) ?? 'JPY';

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
          currencyCode: currencyCode,
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

    final currencyCode =
        prefs.getString(_key(tripId, 'currency_code')) ?? 'JPY';

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
      currencyCode: currencyCode,
    );
  }

  Future<void> deleteTrip(String tripId) async {
    final prefs = await SharedPreferences.getInstance();

    final tripIds = prefs.getStringList(_tripIdsKey) ?? [];

    tripIds.remove(tripId);

    await prefs.setStringList(_tripIdsKey, tripIds);

    await prefs.remove(_key(tripId, 'name'));

    await prefs.remove(_key(tripId, 'allowance'));

    await prefs.remove(_key(tripId, 'start_date'));

    await prefs.remove(_key(tripId, 'end_date'));

    await prefs.remove(_key(tripId, 'currency_code'));
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
      currencyCode: 'JPY',
    );

    await saveTrip(trip);
  }
}
