import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_program.dart';
import '../models/auth_user.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';

class StorageService {
  static const String _activeProgramKey = 'gym_active_program_id';
  static const String _userProgramsKey = 'gym_custom_programs';
  static const String _communityProgramsKey = 'gym_community_programs';
  static const String _exercisesHistoryKey = 'gym_exercises_history';
  static const String _profileDataKey = 'gym_user_profile_data';

  // 1. PROGRAMLARIN KALICI KAYDI
  static Future<void> saveCustomPrograms(List<WorkoutProgram> programs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = programs.map((p) => p.toJson()).toList();
    await prefs.setString(_userProgramsKey, jsonEncode(jsonList));
  }

  static Future<List<WorkoutProgram>> loadCustomPrograms() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userProgramsKey);
    if (str != null) {
      try {
        final List list = jsonDecode(str);
        return list.map((e) => WorkoutProgram.fromJson(e)).toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveActiveProgramId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_activeProgramKey, id);
    } else {
      await prefs.remove(_activeProgramKey);
    }
  }

  static Future<String?> loadActiveProgramId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProgramKey);
  }

  // 2. PROFİL VE XP / LEVEL KALICI KAYDI
  static Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileDataKey, jsonEncode(profile.toJson()));
  }

  static Future<UserProfile?> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_profileDataKey);
    if (str != null) {
      try {
        return UserProfile.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  // 3. EGZERSİZ AĞIRLIK GEÇMİŞİ KALICI KAYDI
  static Future<void> saveExercisesHistory(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> historyMap = {};
    for (var ex in exercises) {
      if (ex.history.isNotEmpty) {
        historyMap[ex.id] = ex.history.map((h) => h.toJson()).toList();
      }
    }
    await prefs.setString(_exercisesHistoryKey, jsonEncode(historyMap));
  }

  static Future<void> loadExercisesHistory(List<Exercise> exercises) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_exercisesHistoryKey);
    if (str != null) {
      try {
        final Map<String, dynamic> historyMap = jsonDecode(str);
        for (var ex in exercises) {
          if (historyMap.containsKey(ex.id)) {
            final List list = historyMap[ex.id];
            ex.history.clear();
            ex.history.addAll(list.map((e) => WeightLogEntry.fromJson(e)).toList());
          }
        }
      } catch (_) {}
    }
  }
}
