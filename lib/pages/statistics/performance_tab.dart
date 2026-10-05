import 'package:flutter/material.dart';

import 'statistics_data.dart';

class PerformanceTab extends StatelessWidget {
  final StatisticsData data;

  const PerformanceTab({super.key, required this.data});

  String _formatPercentage(double value) {
    return '${(value * 100).round()}%';
  }

  String _formatSignedPercentage(double value) {
    final percent = (value * 100).round();

    if (percent > 0) {
      return '+$percent%';
    }

    return '$percent%';
  }

  String _statusTitle() {
    if (data.totalSpent <= 0 || data.elapsedDays <= 0) {
      return 'NO SPENDING YET';
    }

    final paceRatio = data.averageDailyBudgetUsage;
    final gap = data.budgetUsedPercentage - (data.elapsedDays / data.totalDays);

    if (data.projectedTotalSpending <= data.trip.allowance &&
        gap <= 0.05 &&
        paceRatio <= 1.05) {
      return 'ON TRACK';
    }

    if (data.projectedTotalSpending <= data.trip.allowance &&
        gap <= 0.15 &&
        paceRatio <= 1.15) {
      return 'WATCH SPENDING';
    }

    return 'AT RISK';
  }

  String _statusMessage() {
    switch (_statusTitle()) {
      case 'NO SPENDING YET':
        return 'There is not enough spending data to evaluate your budget performance yet.';

      case 'ON TRACK':
        return 'Your current spending pace is within a healthy range for this trip.';

      case 'WATCH SPENDING':
        return 'Your spending pace is slightly ahead of your trip progress. Keep an eye on daily spending.';

      default:
        return 'Your current spending pace may cause you to exceed the trip allowance if it continues.';
    }
  }

  Color _statusColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    switch (_statusTitle()) {
      case 'NO SPENDING YET':
        return colors.onSurfaceVariant;

      case 'ON TRACK':
        return Colors.green;

      case 'WATCH SPENDING':
        return Colors.orange;

      default:
        return colors.error;
    }
  }

  IconData _statusIcon() {
    switch (_statusTitle()) {
      case 'NO SPENDING YET':
        return Icons.hourglass_empty_rounded;

      case 'ON TRACK':
        return Icons.check_circle_rounded;

      case 'WATCH SPENDING':
        return Icons.visibility_rounded;

      default:
        return Icons.warning_rounded;
    }
  }

  // int get _daysAtOrBelowBaseline {
  //   if (data.elapsedDays <= 0) {
  //     return 0;
  //   }

  //   var count = 0;
  //   final dailyTotals = data.dailyTotals;

  //   for (int i = 0; i < data.elapsedDays; i++) {
  //     final date = data.startDate.add(Duration(days: i));
  //     final amount = dailyTotals[date] ?? 0;

  //     if (amount <= data.baselineDailyLimit) {
  //       count++;
  //     }
  //   }

  //   return count;
  // }

  int get _daysAboveBaseline {
    if (data.elapsedDays <= 0) {
      return 0;
    }

    var count = 0;
    final dailyTotals = data.dailyTotals;

    for (int i = 0; i < data.elapsedDays; i++) {
      final date = data.startDate.add(Duration(days: i));
      final amount = dailyTotals[date] ?? 0;

      if (amount > data.baselineDailyLimit) {
        count++;
      }
    }

    return count;
  }

  int get _spendingDays {
    if (data.elapsedDays <= 0) {
      return 0;
    }

    var count = 0;
    final dailyTotals = data.dailyTotals;

    for (int i = 0; i < data.elapsedDays; i++) {
      final date = data.startDate.add(Duration(days: i));
      final amount = dailyTotals[date] ?? 0;

      if (amount > 0) {
        count++;
      }
    }

    return count;
  }

  double get _tripProgress {
    if (data.totalDays <= 0) {
      return 0;
    }

    return data.elapsedDays / data.totalDays;
  }

  double get _performanceGap {
    return data.budgetUsedPercentage - _tripProgress;
  }

  double get _budgetEfficiency {
    if (data.averageDailySpending <= 0 || data.baselineDailyLimit <= 0) {
      return 0;
    }

    return (data.baselineDailyLimit / data.averageDailySpending).clamp(
      0.0,
      1.0,
    );
  }

  String _gapDescription() {
    final gap = _performanceGap;

    if (data.totalSpent <= 0 || data.elapsedDays <= 0) {
      return 'Not enough data yet';
    }

    if (gap.abs() < 0.01) {
      return 'Budget usage matches trip progress';
    }

    if (gap > 0) {
      return '${_formatPercentage(gap)} ahead of trip progress';
    }

    return '${_formatPercentage(gap.abs())} behind trip progress';
  }

  String _paceDescription() {
    if (data.averageDailySpending <= 0) {
      return 'No spending recorded yet';
    }

    final difference = data.averageDailySpending - data.baselineDailyLimit;

    if (difference.abs() < 0.01) {
      return 'Exactly at daily baseline';
    }

    if (difference > 0) {
      return '${data.formatAmount(difference)} above baseline';
    }

    return '${data.formatAmount(difference.abs())} below baseline';
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    String? subtitle,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _statusColor(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon(), color: statusColor, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              _statusTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetUtilization(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final used = data.budgetUsedPercentage.clamp(0.0, 1.0);
    final progress = _tripProgress.clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Budget used', style: theme.textTheme.titleSmall),
                ),
                Text(
                  _formatPercentage(data.budgetUsedPercentage),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: used, minHeight: 10),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonValue(
                    context,
                    label: 'Budget used',
                    value: _formatPercentage(data.budgetUsedPercentage),
                  ),
                ),
                Expanded(
                  child: _buildComparisonValue(
                    context,
                    label: 'Trip elapsed',
                    value: _formatPercentage(progress),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _performanceGap > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 18,
                  color: _performanceGap > 0 ? colors.error : colors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _gapDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonValue(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingPace(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPaceRow(
              context,
              icon: Icons.speed_rounded,
              label: 'Actual average',
              value: data.formatAmount(data.averageDailySpending),
            ),
            const Divider(height: 24),
            _buildPaceRow(
              context,
              icon: Icons.flag_outlined,
              label: 'Daily baseline',
              value: data.formatAmount(data.baselineDailyLimit),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  data.averageDailySpending > data.baselineDailyLimit
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 18,
                  color: data.averageDailySpending > data.baselineDailyLimit
                      ? colors.error
                      : colors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _paceDescription(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaceRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 21, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProjection(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final projected = data.projectedTotalSpending;
    final allowance = data.trip.allowance;
    final difference = projected - allowance;
    final isOver = difference > 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProjectionRow(
              context,
              'Projected spending',
              data.formatAmount(projected),
            ),
            const Divider(height: 24),
            _buildProjectionRow(
              context,
              'Trip allowance',
              data.formatAmount(allowance),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  isOver
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 19,
                  color: isOver ? colors.error : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOver
                        ? '${data.formatAmount(difference.abs())} projected over allowance'
                        : '${data.formatAmount(difference.abs())} projected remaining',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMetrics(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildMetricLine(
              context,
              icon: Icons.auto_graph_rounded,
              label: 'Budget efficiency',
              value: _budgetEfficiency > 0
                  ? _formatPercentage(_budgetEfficiency)
                  : '—',
              detail: _budgetEfficiency > 0
                  ? 'Higher means your daily pace is closer to the baseline'
                  : 'Not enough spending data yet',
            ),
            const Divider(height: 24),
            _buildMetricLine(
              context,
              icon: Icons.speed_rounded,
              label: 'Spending pace',
              value: data.averageDailySpending > 0
                  ? _formatSignedPercentage(data.averageDailyBudgetUsage - 1)
                  : '—',
              detail: 'Compared with the trip daily baseline',
            ),
            const Divider(height: 24),
            _buildMetricLine(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Days above baseline',
              value: '$_daysAboveBaseline / ${data.elapsedDays}',
              detail: 'Days where spending exceeded the daily baseline',
            ),
            const Divider(height: 24),
            _buildMetricLine(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Spending days',
              value: '$_spendingDays / ${data.elapsedDays}',
              detail: 'Days with at least one recorded expense',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricLine(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String detail,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildSectionTitle(
          context,
          'Budget Performance',
          'See how effectively your spending is tracking against the trip plan.',
        ),
        _buildStatusCard(context),
        const SizedBox(height: 20),

        _buildSectionTitle(
          context,
          'Budget Utilization',
          'Compare the portion of your budget used with the portion of the trip elapsed.',
        ),
        _buildBudgetUtilization(context),
        const SizedBox(height: 20),

        _buildSectionTitle(
          context,
          'Spending Pace',
          'Compare your actual daily spending with the original trip baseline.',
        ),
        _buildSpendingPace(context),
        const SizedBox(height: 20),

        _buildSectionTitle(
          context,
          'Projection',
          'Estimate where your total spending may end up if the current pace continues.',
        ),
        _buildProjection(context),
        const SizedBox(height: 20),

        _buildSectionTitle(
          context,
          'Performance Metrics',
          'Additional indicators of budget discipline during the trip.',
        ),
        _buildPerformanceMetrics(context),
      ],
    );
  }
}
