import 'package:flutter/material.dart';

class AppNavigationItem {
  const AppNavigationItem({
    required this.label,
    required this.route,
    required this.icon,
    this.requiredPermission,
  });

  final String label;
  final String route;
  final IconData icon;
  final String? requiredPermission;
}
