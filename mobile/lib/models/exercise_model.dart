class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.difficulty,
    this.mediaUrl,
    this.equipment,
  });

  final String id;
  final String name;
  final String description;
  final String muscleGroup;
  final String difficulty;
  final String? mediaUrl;
  final String? equipment;

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    return ExerciseModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      muscleGroup: json['muscle_group'] as String,
      difficulty: json['difficulty'] as String,
      mediaUrl: json['media_url'] as String?,
      equipment: json['equipment'] as String?,
    );
  }
}
