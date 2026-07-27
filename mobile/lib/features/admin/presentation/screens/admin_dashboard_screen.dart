import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Admin',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Admin console',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text('Manage users, exercises, roles, and payment history.'),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Users',
            onPressed: () => context.go(AppRoutes.adminUsers),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Exercises',
            onPressed: () => context.go(AppRoutes.adminExercises),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Payments',
            onPressed: () => context.go(AppRoutes.adminPayments),
          ),
        ],
      ),
    );
  }
}
