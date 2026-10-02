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

  String _selectedCurrency = 'JPY';

  // Currency code -> currency name
  static const Map<String, String> _currencies = {
    'JPY': 'Japanese Yen',
    'USD': 'US Dollar',
    'PHP': 'Philippine Peso',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'KRW': 'South Korean Won',
    'CNY': 'Chinese Yuan',
    'SGD': 'Singapore Dollar',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'HKD': 'Hong Kong Dollar',
    'TWD': 'New Taiwan Dollar',
    'THB': 'Thai Baht',
    'MYR': 'Malaysian Ringgit',
    'IDR': 'Indonesian Rupiah',
  };

  // Currency code -> display symbol
  static const Map<String, String> _currencySymbols = {
    'JPY': '¥',
    'USD': '\$',
    'PHP': '₱',
    'EUR': '€',
    'GBP': '£',
    'KRW': '₩',
    'CNY': '¥',
    'SGD': 'S\$',
    'AUD': 'A\$',
    'CAD': 'C\$',
    'HKD': 'HK\$',
    'TWD': 'NT\$',
    'THB': '฿',
    'MYR': 'RM',
    'IDR': 'Rp',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _allowanceController.dispose();
    super.dispose();
  }

  String _currencySymbol(String currencyCode) {
    return _currencySymbols[currencyCode] ?? currencyCode;
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _startDate ?? DateTime.now(),
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

      if (_endDate != null && _endDate!.isBefore(_startDate!)) {
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

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a trip name.')),
      );
      return;
    }

    if (allowance == null || allowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid allowance.')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select the start and end dates.')),
      );
      return;
    }

    final trip = Trip(
      id: const Uuid().v4(),
      name: name,
      allowance: allowance,
      startDate: _startDate!,
      endDate: _endDate!,
      currencyCode: _selectedCurrency,
    );

    await _tripStorageService.saveTrip(trip);

    if (!mounted) {
      return;
    }

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
    final currencySymbol = _currencySymbol(_selectedCurrency);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Trip Name',
              hintText: 'e.g. Japan Business Trip',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work_outline),
            ),
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_exchange),
            ),
            items: _currencies.entries.map((entry) {
              final code = entry.key;
              final name = entry.value;
              final symbol = _currencySymbol(code);

              return DropdownMenuItem<String>(
                value: code,
                child: Text('$code - $name ($symbol)'),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _selectedCurrency = value;
              });
            },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _allowanceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Allowance',
              hintText: 'Enter your budget',
              prefixText: '$currencySymbol ',
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(_formatDate(_startDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectStartDate,
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text('End Date'),
              subtitle: Text(_formatDate(_endDate)),
              trailing: const Icon(Icons.chevron_right),
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
