import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';

class TrainerProgramsScreen extends StatelessWidget {
  const TrainerProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Training Programs',
      child: Center(
        child: Text('Trainer program builder endpoint: /api/v1/trainer/programs'),
      ),
    );
  }
}
