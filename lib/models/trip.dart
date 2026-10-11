class Trip {
  final String id;
  final String name;
  final double allowance;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final String countryCode;
  final String countryName;

  const Trip({
    required this.id,
    required this.name,
    required this.allowance,
    required this.startDate,
    required this.endDate,
    this.currencyCode = 'JPY',
    this.countryCode = 'JP',
    this.countryName = 'Japan',
  });

  int get totalDays => endDate.difference(startDate).inDays + 1;
}
