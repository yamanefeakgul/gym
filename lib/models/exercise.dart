enum MuscleGroup {
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
  cardio,
}

extension MuscleGroupName on MuscleGroup {
  String get displayName {
    switch (this) {
      case MuscleGroup.chest:
        return 'Göğüs';
      case MuscleGroup.back:
        return 'Sırt';
      case MuscleGroup.legs:
        return 'Bacak';
      case MuscleGroup.shoulders:
        return 'Omuz';
      case MuscleGroup.arms:
        return 'Kol (Biceps/Triceps)';
      case MuscleGroup.core:
        return 'Karın & Merkez';
      case MuscleGroup.cardio:
        return 'Kardiyo';
    }
  }

  String get emoji {
    switch (this) {
      case MuscleGroup.chest:
        return '🛡️';
      case MuscleGroup.back:
        return '🦅';
      case MuscleGroup.legs:
        return '🦵';
      case MuscleGroup.shoulders:
        return '🏹';
      case MuscleGroup.arms:
        return '💪';
      case MuscleGroup.core:
        return '🧱';
      case MuscleGroup.cardio:
        return '🏃';
    }
  }
}

class WeightLogEntry {
  final DateTime date;
  final double weightKg;
  final int reps;
  final int sets;

  WeightLogEntry({
    required this.date,
    required this.weightKg,
    required this.reps,
    required this.sets,
  });

  // Brzycki Formülü ile Tahmini 1RM (Tek Tekrar Maksimumu)
  double get estimated1RM => reps == 1 ? weightKg : (weightKg * (36 / (37 - reps)));

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'reps': reps,
        'sets': sets,
      };

  factory WeightLogEntry.fromJson(Map<String, dynamic> json) => WeightLogEntry(
        date: DateTime.parse(json['date']),
        weightKg: (json['weightKg'] as num).toDouble(),
        reps: json['reps'] as int,
        sets: json['sets'] as int,
      );
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final String equipment;
  final String instructions;
  final List<WeightLogEntry> history;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    this.instructions = '',
    List<WeightLogEntry>? history,
  }) : history = history ?? [];

  double get personalRecordWeight {
    if (history.isEmpty) return 0.0;
    return history.map((e) => e.weightKg).reduce((a, b) => a > b ? a : b);
  }

  double get highest1RM {
    if (history.isEmpty) return 0.0;
    return history.map((e) => e.estimated1RM).reduce((a, b) => a > b ? a : b);
  }

  WeightLogEntry? get lastEntry => history.isNotEmpty ? history.last : null;
}
