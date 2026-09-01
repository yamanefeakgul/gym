enum IntensityTarget {
  rir0Failure, // Failure / Tükeniş
  rir1,        // RIR 1 (Tükenişe 1 Tekrar Kala)
  rir2,        // RIR 2 (Tükenişe 2 Tekrar Kala)
  rir1to2,     // RIR 1-2
  rir1Failure, // RIR 1 - Failure
}

extension IntensityTargetExtension on IntensityTarget {
  String get displayName {
    switch (this) {
      case IntensityTarget.rir0Failure:
        return 'Failure';
      case IntensityTarget.rir1:
        return 'RIR 1';
      case IntensityTarget.rir2:
        return 'RIR 2';
      case IntensityTarget.rir1to2:
        return 'RIR 1-2';
      case IntensityTarget.rir1Failure:
        return 'RIR 1 - Failure';
    }
  }

  String get shortTag {
    switch (this) {
      case IntensityTarget.rir0Failure:
        return '🔥 Failure';
      case IntensityTarget.rir1:
        return '⚡ RIR 1';
      case IntensityTarget.rir2:
        return '🎯 RIR 2';
      case IntensityTarget.rir1to2:
        return '🎯 RIR 1-2';
      case IntensityTarget.rir1Failure:
        return '🔥 RIR1-Fail';
    }
  }
}

class ProgramExerciseDetail {
  final String exerciseId;
  final String setsReps; // Örn: '2x5-6', '3x8-10'
  final IntensityTarget intensity; // Failure, Rir1, Rir2...

  ProgramExerciseDetail({
    required this.exerciseId,
    this.setsReps = '3x8-10',
    this.intensity = IntensityTarget.rir1,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'setsReps': setsReps,
        'intensity': intensity.name,
      };

  factory ProgramExerciseDetail.fromJson(Map<String, dynamic> json) => ProgramExerciseDetail(
        exerciseId: json['exerciseId'] as String,
        setsReps: json['setsReps'] ?? '3x8-10',
        intensity: IntensityTarget.values.firstWhere(
          (e) => e.name == json['intensity'],
          orElse: () => IntensityTarget.rir1,
        ),
      );
}

class WorkoutDay {
  final int dayOfWeek; // 1: Pazartesi ... 7: Pazar
  final String title;
  final List<ProgramExerciseDetail> exercises;

  WorkoutDay({
    required this.dayOfWeek,
    required this.title,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'title': title,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    var rawList = json['exercises'] as List? ?? [];
    List<ProgramExerciseDetail> parsedExercises = [];
    for (var item in rawList) {
      if (item is Map<String, dynamic>) {
        parsedExercises.add(ProgramExerciseDetail.fromJson(item));
      } else if (item is String) {
        parsedExercises.add(ProgramExerciseDetail(exerciseId: item));
      }
    }
    // Geriye dönük uyumluluk: Eğer exerciseIds varsa
    if (parsedExercises.isEmpty && json['exerciseIds'] != null) {
      for (var id in List<String>.from(json['exerciseIds'])) {
        parsedExercises.add(ProgramExerciseDetail(exerciseId: id));
      }
    }

    return WorkoutDay(
      dayOfWeek: json['dayOfWeek'] as int,
      title: json['title'] as String,
      exercises: parsedExercises,
    );
  }
}

class WorkoutProgram {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String level;
  final int daysPerWeek;
  final List<WorkoutDay> schedule;
  final bool isCommunity;
  int downloadsCount;
  int likesCount;

  WorkoutProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.level = 'Orta Seviye',
    required this.daysPerWeek,
    required this.schedule,
    this.isCommunity = false,
    this.downloadsCount = 0,
    this.likesCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'authorName': authorName,
        'level': level,
        'daysPerWeek': daysPerWeek,
        'schedule': schedule.map((d) => d.toJson()).toList(),
        'isCommunity': isCommunity,
        'downloadsCount': downloadsCount,
        'likesCount': likesCount,
      };

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) => WorkoutProgram(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        authorName: json['authorName'] as String,
        level: json['level'] ?? 'Orta Seviye',
        daysPerWeek: json['daysPerWeek'] as int,
        schedule: (json['schedule'] as List? ?? [])
            .map((d) => WorkoutDay.fromJson(d))
            .toList(),
        isCommunity: json['isCommunity'] ?? false,
        downloadsCount: json['downloadsCount'] ?? 0,
        likesCount: json['likesCount'] ?? 0,
      );
}
