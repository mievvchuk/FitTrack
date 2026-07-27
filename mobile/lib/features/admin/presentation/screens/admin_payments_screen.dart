import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';

class AdminPaymentsScreen extends StatelessWidget {
  const AdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Payments',
      child: Center(
        child: Text('Admin payments endpoint: /api/v1/admin/payments'),
      ),
    );
  }
}
