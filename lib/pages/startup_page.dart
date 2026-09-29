import 'package:flutter/material.dart';

import '../services/active_trip_service.dart';
import '../services/trip_storage_service.dart';
import 'budget_home_page.dart';
import 'trip_list_page.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  final ActiveTripService _activeTripService = ActiveTripService();
  final TripStorageService _tripStorageService = TripStorageService();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final activeTripId = await _activeTripService.loadActiveTripId();

    if (activeTripId != null) {
      final trip = await _tripStorageService.loadTrip(activeTripId);

      if (trip != null) {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BudgetHomePage(trip: trip)),
        );

        return;
      }

      await _activeTripService.clearActiveTripId();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TripListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
