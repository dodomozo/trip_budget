import 'package:flutter/material.dart';

import '../services/trip_storage_service.dart';
import '../models/trip.dart';

class TripSettingsPage extends StatefulWidget {
  const TripSettingsPage({super.key});

  @override
  State<TripSettingsPage> createState() => _TripSettingsPageState();
}

class _TripSettingsPageState extends State<TripSettingsPage> {
  final nameController = TextEditingController();
  final allowanceController = TextEditingController();
  final TripStorageService _tripStorageService = TripStorageService();

  DateTime? startDate;
  DateTime? endDate;

  @override
  void dispose() {
    nameController.dispose();
    allowanceController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      startDate = selectedDate;
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      endDate = selectedDate;
    });
  }

  Future<void> _saveSettings() async {
    final name = nameController.text.trim();
    final allowance = double.tryParse(allowanceController.text.trim());

    if (name.isEmpty ||
        allowance == null ||
        allowance <= 0 ||
        startDate == null ||
        endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all trip details.')),
      );

      return;
    }

    if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date.')),
      );

      return;
    }

    final trip = Trip(
      name: name,
      allowance: allowance,
      startDate: startDate!,
      endDate: endDate!,
    );

    await _tripStorageService.saveTrip(trip);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Trip settings saved.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Trip Name',
              hintText: 'e.g. Japan Business Trip',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: allowanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Allowance',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start Date'),
            subtitle: Text(
              startDate == null ? 'Select start date' : _formatDate(startDate!),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectStartDate,
          ),

          const Divider(),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End Date'),
            subtitle: Text(
              endDate == null ? 'Select end date' : _formatDate(endDate!),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectEndDate,
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Trip'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
