import '../models/workout_program.dart';
import '../models/auth_user.dart';
import 'storage_service.dart';

class ProgramService {
  static String? activeProgramId;
  static List<WorkoutProgram> customPrograms = [];
  static List<WorkoutProgram> communityPrograms = [];
  static WorkoutProgram? cachedActiveProgram; // Aktif seçilen programı doğrudan bellekte tutar

  // Görseldeki 5 Günlük Program (Topluluk Programı)
  static final WorkoutProgram visualProgram = WorkoutProgram(
    id: 'visual_official_split',
    title: 'Hypertrophy Mastery (Görsel Programı)',
    description: 'RIR & Failure hedefleriyle tasarlanmış, göğüs, sırt, omuz ve bacak odaklı 5 günlük split.',
    authorName: 'Gym Team',
    level: 'İleri Seviye',
    daysPerWeek: 5,
    isCommunity: true,
    downloadsCount: 1840,
    likesCount: 680,
    schedule: [
      WorkoutDay(
        dayOfWeek: 1,
        title: 'Pazartesi: Göğüs & Omuz & Triceps',
        exercises: [
          ProgramExerciseDetail(exerciseId: 'plate_loaded_chest_press', setsReps: '2x5-6', intensity: IntensityTarget.rir1),
          ProgramExerciseDetail(exerciseId: 'smith_machine_incline_press', setsReps: '2x5-6', intensity: IntensityTarget.rir1),
          ProgramExerciseDetail(exerciseId: 'chest_fly_machine', setsReps: '1x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'shoulder_press_machine', setsReps: '2x6-8', intensity: IntensityTarget.rir1),
          ProgramExerciseDetail(exerciseId: 'lateral_raise', setsReps: '3x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'triceps_pushdown', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'overhead_rope_extension', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
        ],
      ),
      WorkoutDay(
        dayOfWeek: 2,
        title: 'Salı: Sırt & Biceps Çekiş',
        exercises: [
          ProgramExerciseDetail(exerciseId: 'lat_pulldown', setsReps: '2x6-8', intensity: IntensityTarget.rir1Failure),
          ProgramExerciseDetail(exerciseId: 'plate_loaded_wide_row', setsReps: '3x6-8', intensity: IntensityTarget.rir1Failure),
          ProgramExerciseDetail(exerciseId: 'seated_cable_row', setsReps: '1x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'incline_dumbbell_curl', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'cable_curl', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'hammer_curl', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'reverse_barbell_curl', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
        ],
      ),
      WorkoutDay(
        dayOfWeek: 3,
        title: 'Çarşamba: Ağır Bacak',
        exercises: [
          ProgramExerciseDetail(exerciseId: 'leg_press', setsReps: '2x6-8', intensity: IntensityTarget.rir1to2),
          ProgramExerciseDetail(exerciseId: 'smith_machine_squat', setsReps: '2x6-8', intensity: IntensityTarget.rir1to2),
          ProgramExerciseDetail(exerciseId: 'leg_extension', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'seated_leg_curl', setsReps: '3x8-10', intensity: IntensityTarget.rir1),
        ],
      ),
      WorkoutDay(
        dayOfWeek: 4,
        title: 'Perşembe: Dinlenme & Toparlanma',
        exercises: [],
      ),
      WorkoutDay(
        dayOfWeek: 5,
        title: 'Cuma: Omuz & Göğüs & Arka Omuz',
        exercises: [
          ProgramExerciseDetail(exerciseId: 'shoulder_press_machine', setsReps: '2x6-8', intensity: IntensityTarget.rir1),
          ProgramExerciseDetail(exerciseId: 'lateral_raise', setsReps: '3x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'smith_machine_incline_press', setsReps: '2x5-6', intensity: IntensityTarget.rir1),
          ProgramExerciseDetail(exerciseId: 'chest_fly_machine', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'cable_rear_delt_fly', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'triceps_pushdown', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'overhead_rope_extension', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
        ],
      ),
      WorkoutDay(
        dayOfWeek: 6,
        title: 'Cumartesi: Sırt & Bacak & Biceps',
        exercises: [
          ProgramExerciseDetail(exerciseId: 'plate_loaded_wide_row', setsReps: '3x6-8', intensity: IntensityTarget.rir1Failure),
          ProgramExerciseDetail(exerciseId: 'lat_pulldown', setsReps: '3x6-8', intensity: IntensityTarget.rir1Failure),
          ProgramExerciseDetail(exerciseId: 'romanian_deadlift', setsReps: '2x5-6', intensity: IntensityTarget.rir1to2),
          ProgramExerciseDetail(exerciseId: 'cable_curl', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'hammer_curl', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'reverse_barbell_curl', setsReps: '2x8-10', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'leg_extension', setsReps: '2x6-8', intensity: IntensityTarget.rir0Failure),
          ProgramExerciseDetail(exerciseId: 'seated_leg_curl', setsReps: '1x8-10', intensity: IntensityTarget.rir0Failure),
        ],
      ),
      WorkoutDay(
        dayOfWeek: 7,
        title: 'Pazar: Dinlenme',
        exercises: [],
      ),
    ],
  );

  static Future<void> init() async {
    activeProgramId = await StorageService.loadActiveProgramId();
    customPrograms = await StorageService.loadCustomPrograms();
    communityPrograms = [
      visualProgram,
    ];
  }

  static WorkoutProgram? getActiveProgram() {
    if (activeProgramId == null) return null;
    if (cachedActiveProgram != null && cachedActiveProgram!.id == activeProgramId) {
      return cachedActiveProgram;
    }
    if (activeProgramId == visualProgram.id) return visualProgram;
    final custom = customPrograms.where((p) => p.id == activeProgramId);
    if (custom.isNotEmpty) return custom.first;
    final comm = communityPrograms.where((p) => p.id == activeProgramId);
    if (comm.isNotEmpty) return comm.first;
    return cachedActiveProgram;
  }

  static Future<void> setActiveProgram(WorkoutProgram? program) async {
    cachedActiveProgram = program;
    activeProgramId = program?.id;
    await StorageService.saveActiveProgramId(program?.id);
  }

  static Future<void> saveOrUpdateProgram(WorkoutProgram program) async {
    final index = customPrograms.indexWhere((p) => p.id == program.id);
    if (index != -1) {
      customPrograms[index] = program;
    } else {
      customPrograms.add(program);
    }
    await StorageService.saveCustomPrograms(customPrograms);
  }

  static Future<void> deleteProgram(String programId) async {
    customPrograms.removeWhere((p) => p.id == programId);
    if (activeProgramId == programId) {
      activeProgramId = null;
      cachedActiveProgram = null;
      await StorageService.saveActiveProgramId(null);
    }
    await StorageService.saveCustomPrograms(customPrograms);
  }

  static Future<void> publishToCommunity(WorkoutProgram program) async {
    if (!communityPrograms.any((p) => p.id == program.id)) {
      final commProg = WorkoutProgram(
        id: 'pub_${program.id}',
        title: program.title,
        description: program.description,
        authorName: program.authorName,
        level: program.level,
        daysPerWeek: program.daysPerWeek,
        schedule: program.schedule,
        isCommunity: true,
        downloadsCount: 1,
        likesCount: 1,
      );
      communityPrograms.insert(0, commProg);
    }
  }

  static List<LeaderboardEntry> getDynamicLeaderboard(int userLevel, double userTonnage, int userStreak, String username, String rankTitle) {
    List<LeaderboardEntry> list = [
      LeaderboardEntry(
        rank: 1,
        username: username,
        level: userLevel,
        rankTitle: rankTitle,
        totalTonnage: userTonnage / 1000,
        streakDays: userStreak,
        isCurrentUser: true,
      ),
    ];
    return list;
  }
}
