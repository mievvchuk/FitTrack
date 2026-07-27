import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';

class TrainerDashboardScreen extends StatelessWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Trainer',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Trainer workspace',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text('Create programs, add exercises, and review assigned clients.'),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Programs',
            onPressed: () => context.go(AppRoutes.trainerPrograms),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Clients',
            onPressed: () => context.go(AppRoutes.trainerClients),
          ),
        ],
      ),
    );
  }
}
