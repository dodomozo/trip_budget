import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_storage_service.dart';
import 'budget_home_page.dart';
import 'add_trip_page.dart';
import 'edit_trip_page.dart';
import '../services/expense_storage_service.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  final TripStorageService _tripStorageService = TripStorageService();

  final ExpenseStorageService _expenseStorageService = ExpenseStorageService();
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

  Future<void> _deleteTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Trip?'),
          content: Text(
            'Are you sure you want to delete "${trip.name}"?\n\n'
            'All expenses belonging to this trip will also be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _expenseStorageService.deleteExpenses(trip.id);
    await _tripStorageService.deleteTrip(trip.id);

    if (!mounted) return;

    await _loadTrips();

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${trip.name} deleted')));
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit Trip',
                          onPressed: () async {
                            final updated = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTripPage(trip: trip),
                              ),
                            );

                            if (updated == true) {
                              await _loadTrips();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete Trip',
                          onPressed: () {
                            _deleteTrip(trip);
                          },
                        ),
                      ],
                    ),
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
