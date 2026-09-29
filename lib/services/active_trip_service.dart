import 'package:shared_preferences/shared_preferences.dart';

class ActiveTripService {
  static const _activeTripIdKey = 'active_trip_id';

  Future<void> saveActiveTripId(String tripId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_activeTripIdKey, tripId);
  }

  Future<String?> loadActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(_activeTripIdKey);
  }

  Future<void> clearActiveTripId() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_activeTripIdKey);
  }
}
