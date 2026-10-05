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

  static String format(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String formatAmount(double amount, String currencyCode) {
    return format(amount, currencyCode);
  }

  static List<String> get supportedCurrencies {
    return currencyNames.keys.toList();
  }

  static Future<double> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    final from = fromCurrency.trim().toUpperCase();
    final to = toCurrency.trim().toUpperCase();

    if (from.isEmpty || to.isEmpty) {
      throw Exception('Currency code cannot be empty.');
    }

    if (from == to) {
      return 1.0;
    }

    final uri = Uri.https(
      'api.frankfurter.dev',
      '/v2/rate/${from.toLowerCase()}/${to.toLowerCase()}',
    );

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      String message = 'HTTP ${response.statusCode}';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map<String, dynamic> &&
            errorData['message'] is String) {
          message = errorData['message'] as String;
        }
      } catch (_) {
        // Keep the HTTP status as the error message.
      }

      throw Exception('Exchange rate request failed: $message');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid exchange rate response.');
    }

    final base = decoded['base'];
    final quote = decoded['quote'];
    final rate = decoded['rate'];

    if (base is! String || quote is! String || rate is! num) {
      throw Exception('Invalid exchange rate response.');
    }

    if (base.toUpperCase() != from || quote.toUpperCase() != to) {
      throw Exception('Unexpected currency pair returned by the API.');
    }

    final exchangeRate = rate.toDouble();

    if (!exchangeRate.isFinite || exchangeRate <= 0) {
      throw Exception('Invalid exchange rate value.');
    }

    return exchangeRate;
  }

  static Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) async {
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      return amount;
    }

    final rate = await getExchangeRate(fromCurrency, toCurrency);

    return amount * rate;
  }
}
