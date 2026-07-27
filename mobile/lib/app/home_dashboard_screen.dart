import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/widgets/app_screen.dart';
import '../core/widgets/primary_button.dart';
import '../l10n/app_localizations.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScreen(
      title: l10n.appTitle,
      actions: <Widget>[
        IconButton(
          tooltip: l10n.analyticsTitle,
          onPressed: () => context.go(AppRoutes.analytics),
          icon: const Icon(Icons.query_stats),
        ),
        IconButton(
          tooltip: l10n.aiFitnessAssistant,
          onPressed: () => context.go(AppRoutes.aiAssistant),
          icon: const Icon(Icons.auto_awesome_outlined),
        ),
        IconButton(
          tooltip: l10n.profileTitle,
          onPressed: () => context.go(AppRoutes.profile),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            l10n.homeTodayWorkout,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Push Day',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.homeWorkoutSubtitle),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: l10n.startWorkout,
                    onPressed: () => context.go(AppRoutes.workouts),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: <Widget>[
              _MetricCard(label: l10n.weight, value: '78.5 kg'),
              _MetricCard(label: l10n.workouts, value: '4/week'),
              _MetricCard(label: l10n.volume, value: '18 240 kg'),
              _MetricCard(label: l10n.calories, value: '2 180'),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.aiFitnessAssistant),
              subtitle: Text(l10n.aiFitnessAssistantSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.aiAssistant),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.query_stats),
              title: Text(l10n.analyticsDashboard),
              subtitle: Text(l10n.analyticsDashboardSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.analytics),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l10n.openProgress,
            onPressed: () => context.go(AppRoutes.progress),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
