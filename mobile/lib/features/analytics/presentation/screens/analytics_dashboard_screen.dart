import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/analytics_dashboard_model.dart';
import '../providers/analytics_providers.dart';
import '../widgets/analytics_charts.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dashboard = ref.watch(analyticsDashboardProvider(_days));

    return AppScreen(
      title: l10n.analyticsTitle,
      actions: <Widget>[
        IconButton(
          tooltip: l10n.refresh,
          onPressed: () => ref.invalidate(analyticsDashboardProvider(_days)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 7, label: Text('7d')),
              ButtonSegment<int>(value: 30, label: Text('30d')),
              ButtonSegment<int>(value: 90, label: Text('90d')),
            ],
            selected: <int>{_days},
            onSelectionChanged: (value) {
              setState(() => _days = value.first);
            },
          ),
          const SizedBox(height: 20),
          dashboard.when(
            data: (data) => _AnalyticsContent(data: data),
            error: (error, stackTrace) => _ErrorState(message: error.toString()),
            loading: () => const LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({required this.data});

  final AnalyticsDashboardModel data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final summary = data.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.trainingOverview,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${_formatDate(data.period.fromDate)} - ${_formatDate(data.period.toDate)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: <Widget>[
            _MetricCard(
              icon: Icons.fitness_center,
              label: l10n.workouts,
              value: summary.workoutCount.toString(),
              detail: '${summary.completedWorkoutCount} ${l10n.completed}',
            ),
            _MetricCard(
              icon: Icons.monitor_weight_outlined,
              label: l10n.averageWeight,
              value: summary.averageWeightLabel,
              detail: '${l10n.change} ${summary.weightChangeLabel}',
            ),
            _MetricCard(
              icon: Icons.trending_up,
              label: l10n.progress,
              value: summary.progressLabel,
              detail: '${summary.totalVolumeKg.toStringAsFixed(0)} kg ${l10n.volume}',
            ),
            _MetricCard(
              icon: Icons.local_fire_department_outlined,
              label: l10n.calories,
              value: summary.caloriesConsumed.toString(),
              detail: '${summary.caloriesBurned} ${l10n.burned}',
            ),
            _MetricCard(
              icon: Icons.calendar_month_outlined,
              label: l10n.activeDays,
              value: summary.activeDays.toString(),
              detail: '${data.period.days} days period',
            ),
            _MetricCard(
              icon: Icons.bolt_outlined,
              label: l10n.activity,
              value: '${summary.activityScore}%',
              detail: '${summary.averageDailyCalories} kcal/day',
            ),
          ],
        ),
        const SizedBox(height: 20),
        AnalyticsLineChart(
          title: l10n.weightProgress,
          points: data.weightChart,
          color: scheme.primary,
          unit: ' kg',
        ),
        const SizedBox(height: 12),
        AnalyticsBarChart(
          title: l10n.workoutActivity,
          points: data.workoutActivityChart,
          color: scheme.secondary,
        ),
        const SizedBox(height: 12),
        AnalyticsLineChart(
          title: l10n.trainingVolume,
          points: data.volumeChart,
          color: scheme.tertiary,
          unit: ' kg',
        ),
        const SizedBox(height: 12),
        AnalyticsCaloriesChart(points: data.calorieChart),
        const SizedBox(height: 20),
        Text(l10n.recentActivity, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _ActivityList(items: data.activity.reversed.take(7).toList()),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.items});

  final List<AnalyticsActivityPointModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(AppLocalizations.of(context).noRecentActivity);
    }

    return Column(
      children: items
          .map(
            (item) => Card(
              child: ListTile(
                leading: Icon(
                  item.isActive
                      ? Icons.check_circle_outline
                      : Icons.radio_button_unchecked,
                ),
                title: Text(_formatDate(item.date)),
                subtitle: Text(
                  '${item.workoutsCount} workouts - ${item.totalVolumeKg.toStringAsFixed(0)} kg volume',
                ),
                trailing: Text('${item.caloriesConsumed} kcal'),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}";
}
