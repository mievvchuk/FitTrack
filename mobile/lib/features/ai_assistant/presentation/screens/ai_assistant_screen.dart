import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_screen.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/models/ai_fitness_plan_model.dart';
import '../providers/ai_assistant_providers.dart';

const _goalOptions = <String, String>{
  'weight_loss': 'Fat loss',
  'muscle_gain': 'Muscle gain',
  'strength': 'Strength',
  'endurance': 'Endurance',
  'general_fitness': 'General fitness',
};

const _levelOptions = <String, String>{
  'beginner': 'Beginner',
  'intermediate': 'Intermediate',
  'advanced': 'Advanced',
};

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController(text: '78');
  final _heightController = TextEditingController(text: '178');

  String _goal = 'muscle_gain';
  String _fitnessLevel = 'beginner';
  bool _isLoading = false;
  String? _errorMessage;
  AIFitnessPlanModel? _generatedPlan;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(aiFitnessPlanHistoryProvider);

    return AppScreen(
      title: 'AI Assistant',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Personal plan generator',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Workout and nutrition recommendations based on goal, body metrics, and training level.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          _InputCard(
            formKey: _formKey,
            goal: _goal,
            fitnessLevel: _fitnessLevel,
            weightController: _weightController,
            heightController: _heightController,
            onGoalChanged: (value) => setState(() => _goal = value),
            onLevelChanged: (value) => setState(() => _fitnessLevel = value),
          ),
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: _isLoading ? 'Generating...' : 'Generate AI plan',
            icon: Icons.auto_awesome,
            onPressed: _isLoading ? null : _generatePlan,
          ),
          if (_isLoading) ...<Widget>[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
          if (_generatedPlan != null) ...<Widget>[
            const SizedBox(height: 24),
            _PlanResultCard(plan: _generatedPlan!),
          ],
          const SizedBox(height: 28),
          Text(
            'Previous plans',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          history.when(
            data: (plans) {
              if (plans.isEmpty) {
                return const Text('No saved AI plans yet.');
              }
              return Column(
                children: plans
                    .take(3)
                    .map(
                      (plan) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _HistoryPlanCard(plan: plan),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            error: (error, stackTrace) => Text(error.toString()),
            loading: () => const LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plan = await ref.read(aiAssistantApiServiceProvider).generatePlan(
            goal: _goal,
            weightKg: double.parse(_weightController.text),
            heightCm: double.parse(_heightController.text),
            fitnessLevel: _fitnessLevel,
          );
      if (!mounted) {
        return;
      }
      setState(() => _generatedPlan = plan);
      ref.invalidate(aiFitnessPlanHistoryProvider);
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.formKey,
    required this.goal,
    required this.fitnessLevel,
    required this.weightController,
    required this.heightController,
    required this.onGoalChanged,
    required this.onLevelChanged,
  });

  final GlobalKey<FormState> formKey;
  final String goal;
  final String fitnessLevel;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final ValueChanged<String> onGoalChanged;
  final ValueChanged<String> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: goal,
                decoration: const InputDecoration(labelText: 'Goal'),
                items: _goalOptions.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onGoalChanged(value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        suffixText: 'kg',
                      ),
                      validator: (value) => _numberValidator(
                        value,
                        min: 25,
                        max: 300,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        suffixText: 'cm',
                      ),
                      validator: (value) => _numberValidator(
                        value,
                        min: 80,
                        max: 250,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: fitnessLevel,
                decoration: const InputDecoration(labelText: 'Training level'),
                items: _levelOptions.entries
                    .map(
                      (entry) => DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    onLevelChanged(value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanResultCard extends StatelessWidget {
  const _PlanResultCard({required this.plan});

  final AIFitnessPlanModel plan;

  @override
  Widget build(BuildContext context) {
    final nutrition = plan.nutritionRecommendations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Generated plan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(plan.summary),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _MetricChip(label: '${nutrition.caloriesPerDay} kcal'),
                    _MetricChip(label: '${nutrition.proteinG}g protein'),
                    _MetricChip(label: '${nutrition.fatsG}g fats'),
                    _MetricChip(label: '${nutrition.carbsG}g carbs'),
                  ],
                ),
                const SizedBox(height: 16),
                for (final day in plan.workoutPlan.weeklySchedule.take(3))
                  _WorkoutDayTile(day: day),
                const SizedBox(height: 12),
                for (final note in plan.safetyNotes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(Icons.health_and_safety_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryPlanCard extends StatelessWidget {
  const _HistoryPlanCard({required this.plan});

  final AIFitnessPlanModel plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text(_goalOptions[plan.goal] ?? plan.goal),
        subtitle: Text(
          '${_levelOptions[plan.fitnessLevel] ?? plan.fitnessLevel} - ${plan.model}',
        ),
      ),
    );
  }
}

class _WorkoutDayTile extends StatelessWidget {
  const _WorkoutDayTile({required this.day});

  final AIWorkoutDayModel day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Day ${day.day}: ${day.focus}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final exercise in day.exercises.take(4))
            Text(
              '${exercise.name}: ${exercise.sets} x ${exercise.reps}, rest ${exercise.restSeconds}s',
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.bolt_outlined, size: 16),
    );
  }
}

String? _numberValidator(String? value, {required double min, required double max}) {
  final parsed = double.tryParse(value ?? '');
  if (parsed == null) {
    return 'Required';
  }
  if (parsed < min || parsed > max) {
    return '$min-$max';
  }
  return null;
}
