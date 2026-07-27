import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      title: 'Тренування',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          PrimaryButton(
            label: 'Створити тренування',
            icon: Icons.add,
            onPressed: () {},
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              title: const Text('Push Day'),
              subtitle: const Text('6 вправ • 55 хв'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Leg Day'),
              subtitle: const Text('5 вправ • 60 хв'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
