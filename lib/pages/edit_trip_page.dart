import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_storage_service.dart';
import '../services/currency_service.dart';
import '../services/expense_storage_service.dart';

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
  final ExpenseStorageService _expenseStorageService = ExpenseStorageService();

  late DateTime _startDate;
  late DateTime _endDate;

  late String _selectedCurrency;
  late final String _originalCurrency;

  bool _isConverting = false;

  // This stores the exchange rate from the ORIGINAL
  // trip currency to the currently selected currency.
  //
  // Expenses are NOT converted immediately.
  // They are converted only when "Save Changes" is pressed.
  double? _pendingExpenseExchangeRate;

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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.trip.name);

    _allowanceController = TextEditingController(
      text: widget.trip.allowance.toStringAsFixed(2),
    );

    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;

    _selectedCurrency = widget.trip.currencyCode;
    _originalCurrency = widget.trip.currencyCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _allowanceController.dispose();

    super.dispose();
  }

  String _currencySymbol(String currencyCode) {
    return CurrencyService.getSymbol(currencyCode);
  }

  Future<void> _changeCurrency(String newCurrency) async {
    if (newCurrency == _selectedCurrency) {
      return;
    }

    final currentAllowance = double.tryParse(
      _allowanceController.text.trim().replaceAll(',', ''),
    );

    if (currentAllowance == null || currentAllowance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid allowance before changing currency.',
          ),
        ),
      );
      return;
    }

    final oldCurrency = _selectedCurrency;

    setState(() {
      _isConverting = true;
    });

    try {
      // Rate used to convert the allowance currently shown
      // in the form from the current selected currency
      // to the new selected currency.
      final allowanceRate = await CurrencyService.getExchangeRate(
        oldCurrency,
        newCurrency,
      );

      // Rate used for stored expenses.
      //
      // Expenses are still stored in the ORIGINAL trip currency
      // until the user presses "Save Changes".
      final expenseRate = await CurrencyService.getExchangeRate(
        _originalCurrency,
        newCurrency,
      );

      final convertedAllowance = currentAllowance * allowanceRate;

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCurrency = newCurrency;

        _allowanceController.text = convertedAllowance.toStringAsFixed(2);

        _allowanceController.selection = TextSelection.fromPosition(
          TextPosition(offset: _allowanceController.text.length),
        );

        // If the user returns to the original currency,
        // no expense conversion is necessary.
        if (newCurrency == _originalCurrency) {
          _pendingExpenseExchangeRate = null;
        } else {
          _pendingExpenseExchangeRate = expenseRate;
        }

        _isConverting = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConverting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get the latest exchange rate.'),
        ),
      );
    }
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
      initialDate: _endDate,
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

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date.')),
      );
      return;
    }

    // Convert existing expenses ONLY when the user
    // actually changed the trip currency.
    //
    // The conversion is intentionally done here rather than
    // inside _changeCurrency(), so cancelling the edit does
    // not modify the stored expenses.
    if (_selectedCurrency != _originalCurrency &&
        _pendingExpenseExchangeRate != null) {
      try {
        await _expenseStorageService.convertExpensesCurrency(
          tripId: widget.trip.id,
          exchangeRate: _pendingExpenseExchangeRate!,
        );
      } catch (e) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to convert existing expenses.')),
        );

        return;
      }
    }

    final updatedTrip = Trip(
      id: widget.trip.id,
      name: name,
      allowance: allowance,
      startDate: _startDate,
      endDate: _endDate,
      currencyCode: _selectedCurrency,
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
    final currencySymbol = _currencySymbol(_selectedCurrency);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Trip Name',
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
            onChanged: _isConverting
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    _changeCurrency(value);
                  },
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

          if (_isConverting) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Converting currency...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],

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
            onPressed: _isConverting ? null : _saveTrip,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
