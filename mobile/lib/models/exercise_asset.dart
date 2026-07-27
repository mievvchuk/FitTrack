class ExerciseAsset {
  const ExerciseAsset({
    required this.name,
    required this.path,
  });

  final String name;
  final String path;
}

const exerciseAssets = <ExerciseAsset>[
  ExerciseAsset(name: 'Bench Press', path: 'assets/exercises/bench_press.png'),
  ExerciseAsset(name: 'Squat', path: 'assets/exercises/squat.png'),
  ExerciseAsset(name: 'Deadlift', path: 'assets/exercises/deadlift.png'),
  ExerciseAsset(name: 'Pull Up', path: 'assets/exercises/pull_up.png'),
  ExerciseAsset(
    name: 'Shoulder Press',
    path: 'assets/exercises/shoulder_press.png',
  ),
  ExerciseAsset(name: 'Biceps Curl', path: 'assets/exercises/biceps_curl.png'),
  ExerciseAsset(
    name: 'Triceps Extension',
    path: 'assets/exercises/triceps_extension.png',
  ),
  ExerciseAsset(name: 'Plank', path: 'assets/exercises/plank.png'),
  ExerciseAsset(name: 'Lunges', path: 'assets/exercises/lunges.png'),
  ExerciseAsset(name: 'Push Ups', path: 'assets/exercises/push_ups.png'),
];
