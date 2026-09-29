import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_storage_service.dart';
import 'budget_home_page.dart';
import 'add_trip_page.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  final TripStorageService _tripStorageService = TripStorageService();

  List<Trip> trips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final loadedTrips = await _tripStorageService.loadTrips();

    if (!mounted) return;

    setState(() {
      trips = loadedTrips;
      isLoading = false;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : trips.isEmpty
          ? const Center(
              child: Text(
                'No trips yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      trip.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_formatDate(trip.startDate)} → ${_formatDate(trip.endDate)}\n'
                        'Allowance: ¥${trip.allowance.toStringAsFixed(0)}',
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetHomePage(trip: trip),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddTripPage()),
          );

          if (added == true) {
            await _loadTrips();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Trip'),
      ),
    );
  }
}
