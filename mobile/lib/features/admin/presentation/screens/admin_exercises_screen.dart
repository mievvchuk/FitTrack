import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';

class AdminExercisesScreen extends StatelessWidget {
  const AdminExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScreen(
      title: 'Exercise Admin',
      child: Center(
        child: Text('Exercise create/update requires exercises:create or exercises:update.'),
      ),
    );
  }
}
