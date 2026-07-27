import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/auth_user.dart';
import '../constants/app_routes.dart';
import 'app_navigation_item.dart';

class RoleBasedNavigation {
  const RoleBasedNavigation._();

  static List<AppNavigationItem> itemsFor(AuthUser? user) {
    final items = <AppNavigationItem>[
      const AppNavigationItem(
        label: 'Home',
        route: AppRoutes.home,
        icon: Icons.dashboard_outlined,
      ),
      const AppNavigationItem(
        label: 'Exercises',
        route: AppRoutes.exercises,
        icon: Icons.fitness_center,
        requiredPermission: 'exercises:read',
      ),
      const AppNavigationItem(
        label: 'Workouts',
        route: AppRoutes.workouts,
        icon: Icons.timer_outlined,
        requiredPermission: 'workouts:complete',
      ),
      const AppNavigationItem(
        label: 'Progress',
        route: AppRoutes.progress,
        icon: Icons.show_chart,
        requiredPermission: 'progress:manage',
      ),
      const AppNavigationItem(
        label: 'Analytics',
        route: AppRoutes.analytics,
        icon: Icons.query_stats,
        requiredPermission: 'analytics:read',
      ),
      const AppNavigationItem(
        label: 'AI Assistant',
        route: AppRoutes.aiAssistant,
        icon: Icons.auto_awesome_outlined,
        requiredPermission: 'ai:generate',
      ),
      const AppNavigationItem(
        label: 'Premium',
        route: AppRoutes.premium,
        icon: Icons.workspace_premium_outlined,
        requiredPermission: 'premium:pay',
      ),
    ];

    if (user == null) {
      return items;
    }

    if (user.can('programs:create') || user.can('clients:read')) {
      items.add(
        const AppNavigationItem(
          label: 'Trainer',
          route: AppRoutes.trainerDashboard,
          icon: Icons.groups_outlined,
          requiredPermission: 'programs:create',
        ),
      );
    }

    if (user.can('users:manage') || user.can('payments:read')) {
      items.add(
        const AppNavigationItem(
          label: 'Admin',
          route: AppRoutes.adminDashboard,
          icon: Icons.admin_panel_settings_outlined,
          requiredPermission: 'users:manage',
        ),
      );
    }

    return items.where((item) {
      final permission = item.requiredPermission;
      return permission == null || user.can(permission);
    }).toList(growable: false);
  }
}
