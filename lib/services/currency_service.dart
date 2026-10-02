import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyService {
  static const Map<String, String> currencyNames = {
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

  static const Map<String, String> currencySymbols = {
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

  static String getName(String currencyCode) {
    return currencyNames[currencyCode] ?? currencyCode;
  }

  static String getSymbol(String currencyCode) {
    return currencySymbols[currencyCode] ?? currencyCode;
  }

  static String format(
    double amount,
    String currencyCode,
  ) {
    final symbol = getSymbol(currencyCode);

    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String formatAmount(
    double amount,
    String currencyCode,
  ) {
    return format(amount, currencyCode);
  }

  static List<String> get supportedCurrencies {
    return currencyNames.keys.toList();
  }

  /// Gets the latest exchange rate from [fromCurrency] to [toCurrency].
  ///
  /// Example:
  /// JPY -> PHP
  /// returns the number of PHP received for 1 JPY.
  static Future<double> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    if (fromCurrency == toCurrency) {
      return 1.0;
    }

    final uri = Uri.parse(
      'https://api.frankfurter.dev/v2/rate/'
      '${fromCurrency.toLowerCase()}/'
      '${toCurrency.toLowerCase()}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get exchange rate: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final rate = data['rate'];

    if (rate is num) {
      return rate.toDouble();
    }

    throw Exception('Invalid exchange rate response.');
  }

  /// Converts an amount from one currency to another.
  static Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    final rate = await getExchangeRate(
      fromCurrency,
      toCurrency,
    );

    return amount * rate;
  }
}