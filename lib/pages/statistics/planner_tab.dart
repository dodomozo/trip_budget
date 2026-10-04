import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'statistics_data.dart';

enum _PlannerDialogAction { cancelled, saved, cleared }

class _PlannerDialogResult {
  final _PlannerDialogAction action;
  final double? value;

  const _PlannerDialogResult.cancelled()
    : action = _PlannerDialogAction.cancelled,
      value = null;

  const _PlannerDialogResult.saved(double amount)
    : action = _PlannerDialogAction.saved,
      value = amount;

  const _PlannerDialogResult.cleared()
    : action = _PlannerDialogAction.cleared,
      value = null;
}

class _PlannerAmountDialog extends StatefulWidget {
  final String title;
  final String description;
  final String label;
  final String currencyPrefix;
  final double? initialValue;
  final bool allowClear;
  final double? maximumValue;
  final String? maximumError;

  const _PlannerAmountDialog({
    required this.title,
    required this.description,
    required this.label,
    required this.currencyPrefix,
    required this.initialValue,
    required this.allowClear,
    this.maximumValue,
    this.maximumError,
  });

  @override
  State<_PlannerAmountDialog> createState() => _PlannerAmountDialogState();
}

class _PlannerAmountDialogState extends State<_PlannerAmountDialog> {
  late final TextEditingController _controller;

  String? _error;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue == null
          ? ''
          : widget.initialValue!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = double.tryParse(_controller.text.trim());

    if (value == null || value < 0) {
      setState(() {
        _error = 'Enter a valid amount.';
      });
      return;
    }

    if (widget.maximumValue != null && value > widget.maximumValue!) {
      setState(() {
        _error =
            widget.maximumError ?? 'Amount cannot exceed the allowed maximum.';
      });
      return;
    }

    Navigator.of(context).pop(_PlannerDialogResult.saved(value));
  }

  void _clear() {
    Navigator.of(context).pop(const _PlannerDialogResult.cleared());
  }

  void _cancel() {
    Navigator.of(context).pop(const _PlannerDialogResult.cancelled());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.label,
              prefixText: '${widget.currencyPrefix} ',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        if (widget.allowClear)
          TextButton(onPressed: _clear, child: const Text('Clear')),
        TextButton(onPressed: _cancel, child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class PlannerTab extends StatefulWidget {
  final StatisticsData data;

  const PlannerTab({super.key, required this.data});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> {
  StatisticsData get data => widget.data;

  double? _savingsGoal;
  double? _dailySpendingLimit;

  bool _isLoading = true;

  String get _savingsGoalKey => 'planner_savings_goal_${data.trip.id}';

  String get _dailySpendingLimitKey => 'planner_daily_limit_${data.trip.id}';

  @override
  void initState() {
    super.initState();
    _loadPlannerSettings();
  }

  Future<void> _loadPlannerSettings() async {
    final preferences = await SharedPreferences.getInstance();

    if (!mounted) {
      return;
    }

    setState(() {
      _savingsGoal = preferences.getDouble(_savingsGoalKey);
      _dailySpendingLimit = preferences.getDouble(_dailySpendingLimitKey);
      _isLoading = false;
    });
  }

  Future<void> _saveSavingsGoal(double? value) async {
    final preferences = await SharedPreferences.getInstance();

    if (value == null) {
      await preferences.remove(_savingsGoalKey);
    } else {
      await preferences.setDouble(_savingsGoalKey, value);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _savingsGoal = value;
    });
  }

  Future<void> _saveDailySpendingLimit(double? value) async {
    final preferences = await SharedPreferences.getInstance();

    if (value == null) {
      await preferences.remove(_dailySpendingLimitKey);
    } else {
      await preferences.setDouble(_dailySpendingLimitKey, value);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _dailySpendingLimit = value;
    });
  }

  double get _remainingBudget => data.remainingBudget;

  double get _recommendedDailyBudget {
    if (data.remainingDays <= 0) {
      return 0;
    }

    return _remainingBudget / data.remainingDays;
  }

  double get _goalBasedRemainingBudget {
    if (_savingsGoal == null) {
      return _remainingBudget;
    }

    return data.trip.allowance - _savingsGoal! - data.totalSpent;
  }

  double get _goalBasedDailyLimit {
    if (data.remainingDays <= 0) {
      return 0;
    }

    return _goalBasedRemainingBudget / data.remainingDays;
  }

  double get _effectiveDailyLimit {
    if (_dailySpendingLimit != null) {
      return _dailySpendingLimit!;
    }

    if (_savingsGoal != null) {
      return _goalBasedDailyLimit < 0 ? 0 : _goalBasedDailyLimit;
    }

    return _recommendedDailyBudget;
  }

  double get _plannedProjectedSpending {
    if (data.remainingDays <= 0) {
      return data.totalSpent;
    }

    return data.totalSpent + (_effectiveDailyLimit * data.remainingDays);
  }

  double get _plannedProjectedSavings {
    return data.trip.allowance - _plannedProjectedSpending;
  }

  double get _currentProjectedSavings {
    return data.projectedRemainingBudget;
  }

  double get _savingsGoalProgress {
    if (_savingsGoal == null || _savingsGoal! <= 0) {
      return 0;
    }

    final projectedSavings = _currentProjectedSavings;

    if (projectedSavings <= 0) {
      return 0;
    }

    return (projectedSavings / _savingsGoal!).clamp(0.0, 1.0).toDouble();
  }

  bool get _isSavingsGoalAchievable {
    if (_savingsGoal == null) {
      return true;
    }

    return _currentProjectedSavings >= _savingsGoal!;
  }

  bool get _isCurrentlyOverBudget => data.remainingBudget < 0;

  String _formatAmount(double amount) {
    return data.formatAmount(amount);
  }

  Future<void> _showSavingsGoalDialog() async {
    final result = await showDialog<_PlannerDialogResult>(
      context: context,
      builder: (_) {
        return _PlannerAmountDialog(
          title: 'Set Savings Goal',
          description:
              'How much of your allowance do you want to keep '
              'as savings at the end of the trip?',
          label: 'Savings goal',
          currencyPrefix: data.trip.currencyCode,
          initialValue: _savingsGoal,
          allowClear: _savingsGoal != null,
          maximumValue: data.trip.allowance,
          maximumError: 'Goal cannot exceed your trip allowance.',
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result.action) {
      case _PlannerDialogAction.saved:
        await _saveSavingsGoal(result.value);

      case _PlannerDialogAction.cleared:
        await _saveSavingsGoal(null);

      case _PlannerDialogAction.cancelled:
        break;
    }
  }

  Future<void> _showDailySpendingLimitDialog() async {
    final result = await showDialog<_PlannerDialogResult>(
      context: context,
      builder: (_) {
        return _PlannerAmountDialog(
          title: 'Set Daily Spending Limit',
          description:
              'Set the maximum amount you want to spend per day '
              'for the rest of the trip.',
          label: 'Daily spending limit',
          currencyPrefix: data.trip.currencyCode,
          initialValue: _dailySpendingLimit,
          allowClear: _dailySpendingLimit != null,
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    switch (result.action) {
      case _PlannerDialogAction.saved:
        await _saveDailySpendingLimit(result.value);

      case _PlannerDialogAction.cleared:
        await _saveDailySpendingLimit(null);

      case _PlannerDialogAction.cancelled:
        break;
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 21, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required String title,
    required String description,
    required String value,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRemainingBudgetCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isOverBudget = _remainingBudget < 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_outlined,
                  color: isOverBudget ? colors.error : colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Remaining Budget Plan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _formatAmount(_remainingBudget.abs()),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isOverBudget ? colors.error : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isOverBudget
                  ? 'You are already over your trip allowance.'
                  : 'Available budget for the remaining trip.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetric(
                    context,
                    label: 'Remaining days',
                    value: '${data.remainingDays}',
                  ),
                ),
                Expanded(
                  child: _buildMiniMetric(
                    context,
                    label: 'Recommended / day',
                    value: _formatAmount(_recommendedDailyBudget),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectedOutcomeCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final projectedSpending = _plannedProjectedSpending;
    final projectedSavings = _plannedProjectedSavings;
    final isOverBudget = projectedSpending > data.trip.allowance;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Projected Outcome',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your current planner settings.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetric(
                    context,
                    label: 'Projected spending',
                    value: _formatAmount(projectedSpending),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMiniMetric(
                    context,
                    label: isOverBudget
                        ? 'Projected over'
                        : 'Projected savings',
                    value: _formatAmount(projectedSavings.abs()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isOverBudget
                    ? colors.errorContainer
                    : colors.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverBudget
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isOverBudget
                        ? colors.onErrorContainer
                        : colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isOverBudget ? 'This plan would exceed your allowance.' : 'This plan keeps your spending within your allowance.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isOverBudget
                            ? colors.onErrorContainer
                            : colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildSavingsGoalCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_savingsGoal == null) {
      return _buildSettingCard(
        context: context,
        title: 'Savings Goal',
        description: 'Set an amount you want to keep from your allowance.',
        value: 'Not set',
        icon: Icons.savings_outlined,
        onPressed: _showSavingsGoalDialog,
      );
    }

    final progress = _savingsGoalProgress;

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: _showSavingsGoalDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.savings_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Savings Goal',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Target: ${_formatAmount(_savingsGoal!)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: colors.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of goal',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    _isSavingsGoalAchievable ? 'On track' : 'At risk',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isSavingsGoalAchievable
                          ? colors.primary
                          : colors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionRecommendation(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    String title;
    String message;
    IconData icon;

    if (data.tripHasEnded) {
      title = 'Trip Complete';
      message =
          'Your trip has ended. Review your final spending and '
          'savings result in the other Statistics tabs.';
      icon = Icons.flag_outlined;
    } else if (data.tripIsOngoing && _isCurrentlyOverBudget) {
      title = 'Budget Exceeded';
      message =
          'You have already exceeded your trip allowance. '
          'Avoid additional spending where possible.';
      icon = Icons.warning_amber_rounded;
    } else if (_savingsGoal != null && !_isSavingsGoalAchievable) {
      final requiredLimit = _goalBasedDailyLimit > 0
          ? _goalBasedDailyLimit
          : 0.0;

      if (requiredLimit <= 0) {
        title = 'Savings Goal Is At Risk';
        message =
            'Your current spending pace has already made the '
            'savings goal difficult to reach. Additional spending '
            'should be minimized.';
      } else {
        title = 'Reduce Daily Spending';
        message =
            'To reach your savings goal, try to keep remaining '
            'daily spending at ${_formatAmount(requiredLimit)} '
            'or less.';
      }

      icon = Icons.trending_down_rounded;
    } else if (_dailySpendingLimit != null &&
        _dailySpendingLimit! > data.baselineDailyLimit) {
      title = 'Daily Limit Is Above Baseline';
      message =
          'Your custom daily limit is higher than your original '
          'trip baseline of '
          '${_formatAmount(data.baselineDailyLimit)} per day. '
          'You may finish with less savings than originally planned.';
      icon = Icons.info_outline_rounded;
    } else if (_dailySpendingLimit != null) {
      title = 'Plan Looks Good';
      message =
          'Your custom daily limit is set. Staying within this '
          'limit should keep your remaining spending under control.';
      icon = Icons.check_circle_outline_rounded;
    } else {
      title = 'Recommended Plan';
      message =
          'You can spend around '
          '${_formatAmount(_recommendedDailyBudget)} per remaining '
          'day based on your current remaining budget.';
      icon = Icons.lightbulb_outline_rounded;
    }

    return Card(
      elevation: 0,
      color: colors.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                      height: 1.4,
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

  Widget _buildGoalSummary(BuildContext context) {
    if (_savingsGoal == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final projectedSavings = _currentProjectedSavings;
    final difference = projectedSavings - _savingsGoal!;

    final isAchievable = difference >= 0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes_rounded, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Goal Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildMiniMetric(
                    context,
                    label: 'Savings target',
                    value: _formatAmount(_savingsGoal!),
                  ),
                ),
                Expanded(
                  child: _buildMiniMetric(
                    context,
                    label: 'Projected savings',
                    value: _formatAmount(projectedSavings),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              isAchievable
                  ? 'Projected savings are '
                        '${_formatAmount(difference)} above your goal.'
                  : 'Projected savings are '
                        '${_formatAmount(difference.abs())} below your goal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isAchievable ? colors.primary : colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripStatusCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    String title;
    String message;
    IconData icon;

    if (!data.tripHasStarted) {
      title = 'Trip Has Not Started';
      message =
          'Use the planner to prepare your savings goal and '
          'daily spending limit before your trip begins.';
      icon = Icons.event_available_outlined;
    } else if (data.tripHasEnded) {
      title = 'Trip Completed';
      message =
          'Your planning period is complete. Your actual spending '
          'is now your final result.';
      icon = Icons.flag_outlined;
    } else {
      title =
          '${data.remainingDays} '
          '${data.remainingDays == 1 ? 'day' : 'days'} remaining';
      message =
          'Plan your remaining spending based on your budget '
          'and personal goals.';
      icon = Icons.calendar_today_outlined;
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: colors.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Budget Planner',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Plan your remaining spending and protect your budget.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),

        const SizedBox(height: 16),

        _buildTripStatusCard(context),

        const SizedBox(height: 20),

        _buildSectionTitle(context, 'Your Plan', Icons.tune_rounded),

        const SizedBox(height: 12),

        _buildSavingsGoalCard(context),

        const SizedBox(height: 10),

        _buildSettingCard(
          context: context,
          title: 'Daily Spending Limit',
          description: 'Set the maximum amount you want to spend each day.',
          value: _dailySpendingLimit == null
              ? 'Not set'
              : _formatAmount(_dailySpendingLimit!),
          icon: Icons.speed_outlined,
          onPressed: _showDailySpendingLimitDialog,
        ),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'Budget Plan',
          Icons.account_balance_wallet_outlined,
        ),

        const SizedBox(height: 12),

        _buildRemainingBudgetCard(context),

        const SizedBox(height: 12),

        _buildProjectedOutcomeCard(context),

        const SizedBox(height: 24),

        _buildSectionTitle(
          context,
          'Recommendation',
          Icons.lightbulb_outline_rounded,
        ),

        const SizedBox(height: 12),

        _buildActionRecommendation(context),

        const SizedBox(height: 24),

        _buildGoalSummary(context),

        if (_savingsGoal != null) const SizedBox(height: 12),

        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your planner settings are saved for this trip. '
                    'Changing the savings goal or daily spending limit '
                    'does not change your actual expenses.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
