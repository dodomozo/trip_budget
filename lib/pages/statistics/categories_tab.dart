import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../services/expense_storage_service.dart';
import 'statistics_data.dart';

class CategoriesTab extends StatefulWidget {
  final StatisticsData data;

  const CategoriesTab({super.key, required this.data});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  int? _touchedIndex;

  StatisticsData get data => widget.data;

  // Deliberately varied palette so adjacent categories are easy to
  // distinguish in both the donut chart and category list.
  static const List<Color> _palette = [
    Color(0xFFE53935), // Red
    Color(0xFF1E88E5), // Blue
    Color(0xFF43A047), // Green
    Color(0xFFFB8C00), // Orange
    Color(0xFF8E24AA), // Purple
    Color(0xFF00ACC1), // Cyan
    Color(0xFFD81B60), // Pink
    Color(0xFF6D4C41), // Brown
    Color(0xFF3949AB), // Indigo
    Color(0xFF7CB342), // Light green
    Color(0xFFF4511E), // Deep orange
    Color(0xFF00897B), // Teal
    Color(0xFF5E35B1), // Deep purple
    Color(0xFFC0CA33), // Lime
    Color(0xFF546E7A), // Blue grey
  ];

  Color _categoryColor(int index) {
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = data.categoryTotals;

    if (categoryTotals.isEmpty || data.totalSpent <= 0) {
      return _buildEmptyState(context);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalSpentCard(context),
          const SizedBox(height: 20),
          _buildSectionTitle(
            context,
            'Category Breakdown',
            Icons.category_rounded,
          ),
          const SizedBox(height: 12),
          _buildCategoryList(context, sortedCategories),
          const SizedBox(height: 28),
          _buildSectionTitle(
            context,
            'Spending Distribution',
            Icons.donut_large_rounded,
          ),
          const SizedBox(height: 12),
          _buildDonutChart(context, sortedCategories),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTotalSpentCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Spent',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.formatAmount(data.totalSpent),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<MapEntry<String, double>> categories,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (int i = 0; i < categories.length; i++) ...[
              _buildCategoryItem(
                context,
                categories[i].key,
                categories[i].value,
                i,
              ),
              if (i != categories.length - 1) const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String category,
    double amount,
    int index,
  ) {
    final theme = Theme.of(context);
    final color = _categoryColor(index);
    final percentage = data.totalSpent > 0 ? amount / data.totalSpent : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                ExpenseStorageService.getIcon(category),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              data.formatAmount(amount),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutChart(
    BuildContext context,
    List<MapEntry<String, double>> categories,
  ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        child: Column(
          children: [
            SizedBox(
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 68,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              _touchedIndex = null;
                              return;
                            }

                            _touchedIndex =
                                response.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: [
                        for (int i = 0; i < categories.length; i++)
                          _buildPieSection(categories[i], i),
                      ],
                    ),
                  ),
                  _buildCenterLabel(context, categories),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(context, categories),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildPieSection(
    MapEntry<String, double> entry,
    int index,
  ) {
    final isTouched = _touchedIndex == index;
    final color = _categoryColor(index);

    final percentage = data.totalSpent > 0
        ? entry.value / data.totalSpent
        : 0.0;

    return PieChartSectionData(
      color: color,
      value: entry.value,
      title: isTouched ? '${(percentage * 100).toStringAsFixed(1)}%' : '',
      radius: isTouched ? 78 : 68,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      titlePositionPercentageOffset: 0.55,
    );
  }

  Widget _buildCenterLabel(
    BuildContext context,
    List<MapEntry<String, double>> categories,
  ) {
    final theme = Theme.of(context);

    if (_touchedIndex != null &&
        _touchedIndex! >= 0 &&
        _touchedIndex! < categories.length) {
      final entry = categories[_touchedIndex!];
      final percentage = data.totalSpent > 0
          ? entry.value / data.totalSpent
          : 0.0;

      return IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ExpenseStorageService.getIcon(entry.key),
              color: _categoryColor(_touchedIndex!),
              size: 25,
            ),
            const SizedBox(height: 4),
            Text(
              entry.key,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              data.formatAmount(entry.value),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Total Spent',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.formatAmount(data.totalSpent),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<MapEntry<String, double>> categories,
  ) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 16,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < categories.length; i++)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              setState(() {
                _touchedIndex = _touchedIndex == i ? null : i;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _categoryColor(i),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(categories[i].key, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.donut_large_rounded,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No spending data yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some expenses to see your spending by category.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
