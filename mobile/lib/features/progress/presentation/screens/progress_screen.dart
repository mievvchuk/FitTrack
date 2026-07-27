import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../l10n/app_localizations.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppScreen(
      title: l10n.progressTitle,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'week', label: Text(l10n.week)),
              ButtonSegment<String>(value: 'month', label: Text(l10n.month)),
              ButtonSegment<String>(value: 'year', label: Text(l10n.year)),
            ],
            selected: const <String>{'month'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 20),
          Card(
            child: SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  l10n.progressChartHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text(l10n.workoutsThisMonth),
              trailing: const Text('12'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(l10n.totalVolume),
              trailing: const Text('58 200 kg'),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.openAnalyticsDashboard,
            icon: Icons.query_stats,
            onPressed: () => context.go(AppRoutes.analytics),
          ),
        ],
      ),
    );
  }
}
