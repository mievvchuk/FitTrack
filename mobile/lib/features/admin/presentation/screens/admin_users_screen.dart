import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Users',
      child: Center(
        child: Text('Role management endpoints: /api/v1/users/{id}/roles'),
      ),
    );
  }
}
