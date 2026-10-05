class Currency {
  final String code;
  final String name;
  final String symbol;
  final String flag;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
  });
}

class Currencies {
  static const List<Currency> all = [
    Currency(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵'),
    Currency(code: 'PHP', name: 'Philippine Peso', symbol: '₱', flag: '🇵🇭'),
    Currency(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸'),
    Currency(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺'),
    Currency(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧'),
    Currency(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷'),
    Currency(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳'),
    Currency(
      code: 'SGD',
      name: 'Singapore Dollar',
      symbol: 'S\$',
      flag: '🇸🇬',
    ),
    Currency(
      code: 'AUD',
      name: 'Australian Dollar',
      symbol: 'A\$',
      flag: '🇦🇺',
    ),
    Currency(code: 'CAD', name: 'Canadian Dollar', symbol: 'C\$', flag: '🇨🇦'),
  ];

  static Currency getByCode(String code) {
    return all.firstWhere(
      (currency) => currency.code == code,
      orElse: () => all.first,
    );
  }
}
