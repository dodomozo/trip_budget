import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_storage_service.dart';
import '../services/currency_service.dart';

class EditTripPage extends StatefulWidget {
  final Trip trip;

  const EditTripPage({super.key, required this.trip});

  @override
  State<EditTripPage> createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _allowanceController;

  final TripStorageService _tripStorageService = TripStorageService();

  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.trip.name);

    _allowanceController = TextEditingController(
      text: widget.trip.allowance.toStringAsFixed(0),
    );

    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
  }

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
      initialDate: _startDate,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );

      if (_endDate.isBefore(_startDate)) {
        _endDate = _startDate;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: _startDate,
      lastDate: DateTime(2100),
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });
  }

  Future<void> _saveTrip() async {
    final name = _nameController.text.trim();

    final allowance = double.tryParse(
      _allowanceController.text.trim().replaceAll(',', ''),
    );

    if (name.isEmpty ||
        allowance == null ||
        allowance <= 0 ||
        _endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields correctly.')),
      );

      return;
    }

    final updatedTrip = Trip(
      id: widget.trip.id,
      name: name,
      allowance: allowance,
      startDate: _startDate,
      endDate: _endDate,

      // IMPORTANT:
      // Keep the currency that belongs to this trip.
      currencyCode: widget.trip.currencyCode,
    );

    await _tripStorageService.saveTrip(updatedTrip);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = CurrencyService.getSymbol(widget.trip.currencyCode);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Allowance',
              prefixText: '$currencySymbol ',
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Currency: ${widget.trip.currencyCode}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
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

          const SizedBox(height: 8),

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
            label: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
