import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/trip.dart';
import '../services/trip_storage_service.dart';

class AddTripPage extends StatefulWidget {
  const AddTripPage({super.key});

  @override
  State<AddTripPage> createState() => _AddTripPageState();
}

class _AddTripPageState extends State<AddTripPage> {
  final _nameController = TextEditingController();
  final _allowanceController = TextEditingController();

  final TripStorageService _tripStorageService = TripStorageService();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _startDate ?? DateTime.now(),
    );

    if (selectedDate == null) return;

    setState(() {
      _startDate = selectedDate;

      if (_endDate != null && _endDate!.isBefore(selectedDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
    );

    if (selectedDate == null) return;

    setState(() {
      _endDate = selectedDate;
    });
  }

  Future<void> _saveTrip() async {
    final name = _nameController.text.trim();
    final allowance = double.tryParse(_allowanceController.text.trim());

    if (name.isEmpty ||
        allowance == null ||
        allowance <= 0 ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    final trip = Trip(
      id: const Uuid().v4(),
      name: name,
      allowance: allowance,
      startDate: _startDate!,
      endDate: _endDate!,
    );

    await _tripStorageService.saveTrip(trip);

    if (!mounted) return;

    Navigator.pop(context, true);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Trip Name',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _allowanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Allowance',
              prefixText: '¥ ',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              onTap: _selectStartDate,
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text('End Date'),
              subtitle: Text(_formatDate(_endDate)),
              onTap: _selectEndDate,
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _saveTrip,
            icon: const Icon(Icons.save),
            label: const Text('Save Trip'),
          ),
        ],
      ),
    );
  }
}
