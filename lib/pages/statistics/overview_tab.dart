import 'package:flutter/material.dart';

import 'statistics_data.dart';

class OverviewTab extends StatelessWidget {
  final StatisticsData data;

  const OverviewTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTripDurationCard(context),
        const SizedBox(height: 16),
        _buildBudgetSummaryCard(context),
        const SizedBox(height: 16),
        _buildSpendingSummaryCard(context),
        const SizedBox(height: 16),
        _buildProjectionCard(context),
      ],
    );
  }

  Widget _buildTripDurationCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Duration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    context,
                    icon: Icons.calendar_month_rounded,
                    label: 'Total Days',
                    value: '${data.totalDays}',
                  ),
                ),
                Expanded(
                  child: _statItem(
                    context,
                    icon: Icons.timelapse_rounded,
                    label: 'Elapsed',
                    value: '${data.elapsedDays}',
                  ),
                ),
                Expanded(
                  child: _statItem(
                    context,
                    icon: Icons.event_available_rounded,
                    label: 'Remaining',
                    value: '${data.remainingDays}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetSummaryCard(BuildContext context) {
    final isOverBudget = data.remainingBudget < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _summaryRow('Allowance', data.formatAmount(data.trip.allowance)),
            _summaryRow('Total Spent', data.formatAmount(data.totalSpent)),
            _summaryRow(
              isOverBudget ? 'Over Budget' : 'Remaining',
              data.formatAmount(data.remainingBudget.abs()),
              valueColor: isOverBudget
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            _summaryRow(
              'Daily Baseline',
              data.formatAmount(data.baselineDailyLimit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingSummaryCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _summaryRow(
              'Average Daily Spending',
              data.formatAmount(data.averageDailySpending),
            ),
            _summaryRow('Today', data.formatAmount(data.todaysSpending)),
            _summaryRow(
              'Budget Used',
              '${(data.budgetUsedPercentage * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: data.budgetUsedPercentage.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard(BuildContext context) {
    final isOverBudget = data.isProjectedOverBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Projection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _summaryRow(
              'Projected Spending',
              data.formatAmount(data.projectedTotalSpending),
            ),
            _summaryRow(
              isOverBudget ? 'Projected Over Budget' : 'Projected Remaining',
              data.formatAmount(data.projectedRemainingBudget.abs()),
              valueColor: isOverBudget
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            _summaryRow(
              'Projected Budget Usage',
              '${(data.projectedBudgetUsage * 100).toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 12),
            Text(
              data.spendingPaceStatus,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isOverBudget
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }
}
