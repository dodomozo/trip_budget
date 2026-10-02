class Trip {
  final String id;
  final String name;
  final double allowance;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;

  const Trip({
    required this.id,
    required this.name,
    required this.allowance,
    required this.startDate,
    required this.endDate,
    this.currencyCode = 'JPY',
  });

  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }
}
