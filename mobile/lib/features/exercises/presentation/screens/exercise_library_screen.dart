import 'package:flutter/material.dart';

import '../../../../core/widgets/app_screen.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const groups = <String>['Груди', 'Спина', 'Ноги', 'Плечі', 'Руки', 'Прес'];

    return AppScreen(
      title: 'Вправи',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          TextField(
            decoration: InputDecoration(
              hintText: 'Пошук вправ',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: groups.map((group) {
              return FilterChip(
                label: Text(group),
                selected: group == 'Груди',
                onSelected: (_) {},
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(child: Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bench Press',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Text('Груди • Штанга'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
