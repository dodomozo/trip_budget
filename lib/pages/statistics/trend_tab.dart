import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'statistics_data.dart';

class TrendTab extends StatefulWidget {
  final StatisticsData data;

  const TrendTab({super.key, required this.data});

  @override
  State<TrendTab> createState() => _TrendTabState();
}

class _TrendTabState extends State<TrendTab> {
  late DateTime _selectedMonth;

  StatisticsData get data => widget.data;

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month);
    final firstTripMonth = DateTime(
      widget.data.startDate.year,
      widget.data.startDate.month,
    );
    final lastTripMonth = DateTime(
      widget.data.endDate.year,
      widget.data.endDate.month,
    );

    if (currentMonth.isBefore(firstTripMonth)) {
      _selectedMonth = firstTripMonth;
    } else if (currentMonth.isAfter(lastTripMonth)) {
      _selectedMonth = lastTripMonth;
    } else {
      _selectedMonth = currentMonth;
    }
  }

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  DateTime get _firstTripMonth =>
      DateTime(data.startDate.year, data.startDate.month);

  DateTime get _lastTripMonth =>
      DateTime(data.endDate.year, data.endDate.month);

  bool get _canGoPrevious => _selectedMonth.isAfter(_firstTripMonth);

  bool get _canGoNext => _selectedMonth.isBefore(_lastTripMonth);

  void _previousMonth() {
    if (!_canGoPrevious) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  List<MapEntry<DateTime, double>> _getMonthlyEntries() {
    return data.dailyTotals.entries.where((entry) {
      final date = entry.key;

      return date.year == _selectedMonth.year &&
          date.month == _selectedMonth.month;
    }).toList();
  }

  String _formatChartAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }

    return amount.toStringAsFixed(0);
  }

  double _calculateChartMaxY(List<MapEntry<DateTime, double>> entries) {
    if (entries.isEmpty) {
      return 1000;
    }

    final maximumSpending = entries.fold<double>(
      0,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    final maximum = maximumSpending > data.baselineDailyLimit
        ? maximumSpending
        : data.baselineDailyLimit;

    if (maximum <= 0) {
      return 1000;
    }

    // Choose a sensible step based on the maximum amount.
    final magnitude = _pow10((maximum).floor().toString().length - 1);

    final normalized = maximum / magnitude;

    double step;

    if (normalized <= 1) {
      step = magnitude * 0.2;
    } else if (normalized <= 2) {
      step = magnitude * 0.5;
    } else if (normalized <= 5) {
      step = magnitude;
    } else {
      step = magnitude * 2;
    }

    final roundedMax = (maximum / step).ceil() * step;

    // Add one extra step above the highest value so the tallest
    // bar doesn't touch the top of the chart.
    return roundedMax + step;
  }

  double _pow10(int exponent) {
    if (exponent <= 0) {
      return 1;
    }

    double result = 1;

    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }

    return result;
  }

  double _calculateGridInterval(double maxY) {
    return maxY / 5;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _getMonthlyEntries();

    final totalMonthlySpending = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );

    final maximumSpending = entries.fold<double>(
      0,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    final daysWithSpending = entries.where((entry) => entry.value > 0).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMonthSelector(context),
        const SizedBox(height: 12),
        _buildSummaryCard(
          context,
          totalMonthlySpending,
          maximumSpending,
          daysWithSpending,
        ),
        const SizedBox(height: 12),
        _buildChartCard(context, entries),
        const SizedBox(height: 12),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: _canGoPrevious ? _previousMonth : null,
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Center(
                child: Text(
                  _monthName(_selectedMonth),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _canGoNext ? _nextMonth : null,
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalMonthlySpending,
    double maximumSpending,
    int daysWithSpending,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Trend',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Daily spending for ${_monthName(_selectedMonth)}.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Monthly Spending',
                    value: data.formatAmount(totalMonthlySpending),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Highest Day',
                    value: data.formatAmount(maximumSpending),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'Spending Days',
                    value: '$daysWithSpending',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(
    BuildContext context,
    List<MapEntry<DateTime, double>> entries,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return Card(
        child: SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No trip data for this month.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use the arrows above to view another month.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final maxY = _calculateChartMaxY(entries);
    final gridInterval = _calculateGridInterval(maxY);

    final screenWidth = MediaQuery.sizeOf(context).width - 32;

    // Give every day enough horizontal space.
    final chartWidth = entries.length * 46.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Daily Spending',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 320,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth > screenWidth ? chartWidth : screenWidth,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: maxY,
                      alignment: BarChartAlignment.spaceAround,
                      groupsSpace: 8,
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: data.baselineDailyLimit,
                            color: colorScheme.primary,
                            strokeWidth: 2,
                            dashArray: [6, 4],
                          ),
                        ],
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: gridInterval,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 52,
                            interval: gridInterval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatChartAmount(value),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();

                              if (index < 0 || index >= entries.length) {
                                return const SizedBox.shrink();
                              }

                              // Only show the day number.
                              final day = entries[index].key.day;

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '$day',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) =>
                              colorScheme.surfaceContainerHighest,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (groupIndex < 0 ||
                                groupIndex >= entries.length) {
                              return null;
                            }

                            final entry = entries[groupIndex];

                            return BarTooltipItem(
                              '${_monthName(entry.key)} ${entry.key.day}\n'
                              '${data.formatAmount(entry.value)}',
                              TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            );
                          },
                        ),
                      ),
                      barGroups: List.generate(entries.length, (index) {
                        final amount = entries[index].value;

                        final isAboveBaseline =
                            amount > data.baselineDailyLimit;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: amount,
                              width: 22,
                              color: isAboveBaseline
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            _LegendItem(color: colorScheme.primary, label: 'Within baseline'),
            _LegendItem(color: colorScheme.error, label: 'Above baseline'),
            _LegendItem(
              color: colorScheme.primary,
              label: 'Daily baseline',
              isLine: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isLine;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLine)
          Container(width: 24, height: 2, color: color)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}
