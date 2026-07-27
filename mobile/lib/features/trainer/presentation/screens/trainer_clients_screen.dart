import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';

class TrainerClientsScreen extends StatelessWidget {
  const TrainerClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Clients',
      child: Center(
        child: Text('Assigned clients endpoint: /api/v1/trainer/clients'),
      ),
    );
  }
}
