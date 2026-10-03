import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../models/trip.dart';
import 'statistics/categories_tab.dart';
import 'statistics/daily_tab.dart';
import 'statistics/overview_tab.dart';
import 'statistics/performance_tab.dart';
import 'statistics/planner_tab.dart';
import 'statistics/statistics_data.dart';
import 'statistics/trend_tab.dart';

class StatisticsPage extends StatefulWidget {
  final Trip trip;
  final List<Expense> expenses;
  final String displayCurrencyCode;
  final double exchangeRate;

  const StatisticsPage({
    super.key,
    required this.trip,
    required this.expenses,
    required this.displayCurrencyCode,
    required this.exchangeRate,
  });

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  late StatisticsData _data;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 6, vsync: this);

    _data = StatisticsData(
      trip: widget.trip,
      expenses: widget.expenses,
      displayCurrencyCode: widget.displayCurrencyCode,
      exchangeRate: widget.exchangeRate,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up_rounded), text: 'Trend'),
            Tab(icon: Icon(Icons.donut_large_rounded), text: 'Categories'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Daily'),
            Tab(icon: Icon(Icons.speed_rounded), text: 'Performance'),
            Tab(icon: Icon(Icons.savings_rounded), text: 'Planner'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OverviewTab(data: _data),
          TrendTab(data: _data),
          CategoriesTab(data: _data),
          DailyTab(data: _data),
          PerformanceTab(data: _data),
          PlannerTab(data: _data),
        ],
      ),
    );
  }
}
